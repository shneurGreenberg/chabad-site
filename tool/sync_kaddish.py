import json
import re
from pathlib import Path

html_path = Path.home() / "AppData/Local/Temp/kaddish-page.html"
html = html_path.read_text(encoding="utf-8")
match = re.search(r"window\.data\s*=\s*(\{.*?\})\s*;\s*</script>", html, re.S)
if not match:
    raise SystemExit("window.data not found")
live = json.loads(match.group(1))
people = live["people"]

root = Path(__file__).resolve().parents[1]
local_path = root / "assets/data/kaddish_novosibirsk.json"
local = json.loads(local_path.read_text(encoding="utf-8"))
by_id = {int(x["id"]): x for x in local}

base = "https://synagogue-kadish-shneur.amvera.io/photos/"
# Files that exist on the photo host even when the board record has no photo field.
extra_photos = {193: "193.jpg"}


def photo_url(filename, crop):
    if not filename:
        return ""
    query = ["w=280"]
    if isinstance(crop, dict):
        x, y, z = crop.get("x"), crop.get("y"), crop.get("zoom")
        if isinstance(x, (int, float)) and x != 50:
            query.append(f"cx={x}")
        if isinstance(y, (int, float)) and y != 50:
            query.append(f"cy={y}")
        if isinstance(z, (int, float)) and z != 1:
            query.append(f"cz={z}")
    return f"{base}{filename}?{'&'.join(query)}"


out = []
for person in people:
    pid = int(person["id"])
    old = by_id.get(pid, {})
    death = person.get("gregorianDateOfDeath") or {}
    photo = str(person.get("photo") or "").strip()
    if not photo and pid in extra_photos:
        photo = extra_photos[pid]
    crop = person.get("photoCrop") if isinstance(person.get("photoCrop"), dict) else None
    rec = {
        "id": pid,
        "name": person.get("name") or old.get("name") or "",
        "title": person.get("title") or old.get("title") or "",
        "deathYear": death.get("year") or old.get("deathYear"),
        "deathMonth": death.get("month") or old.get("deathMonth"),
        "deathDay": death.get("date") or old.get("deathDay"),
        "hebrew": old.get("hebrew") or {},
        "photo": photo,
        "photoUrl": photo_url(photo, crop) if photo else "",
    }
    if crop:
        rec["photoCrop"] = crop
    for key in ("birthYear", "section", "row"):
        if old.get(key):
            rec[key] = old[key]
    out.append(rec)

with_photo = sum(1 for item in out if item.get("photo"))
local_path.write_text(json.dumps(out, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(f"wrote {len(out)} records, {with_photo} with photos")
