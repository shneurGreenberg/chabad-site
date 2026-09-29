import json
import urllib.request
from pathlib import Path

BOARD_API = "https://synagogue-kadish-shneur.amvera.io/s/novosibirsk/api/board"
BOARD_FULL_API = f"{BOARD_API}?slim=0"
PHOTO_BASE = "https://synagogue-kadish-shneur.amvera.io/photos/"
EXTRA_PHOTOS = {193: "193.jpg"}


def fetch_json(url):
    req = urllib.request.Request(url, headers={"Accept": "application/json"})
    with urllib.request.urlopen(req, timeout=30) as res:
        return json.loads(res.read().decode("utf-8"))


def people_from_payload(payload):
    if isinstance(payload, list):
        return payload
    if isinstance(payload, dict) and isinstance(payload.get("people"), list):
        return payload["people"]
    return []


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
    return f"{PHOTO_BASE}{filename}?{'&'.join(query)}"


def absolute_url(value):
    url = str(value or "").strip()
    if not url:
        return ""
    if url.startswith("http://") or url.startswith("https://"):
        return url
    if url.startswith("//"):
        return f"https:{url}"
    if url.startswith("/"):
        return f"https://synagogue-kadish-shneur.amvera.io{url}"
    return f"{PHOTO_BASE}{url}"


try:
    people = people_from_payload(fetch_json(BOARD_API))
except Exception as err:
    raise SystemExit(f"{BOARD_API} failed: {err}") from err

if people and all(isinstance(person, dict) and "text" not in person for person in people):
    try:
        full = people_from_payload(fetch_json(BOARD_FULL_API))
    except Exception as err:
        print(f"{BOARD_FULL_API} failed: {err}")
        full = []
    if full:
        people = full
        print(f"loaded {len(people)} people from {BOARD_FULL_API}")
    else:
        print(f"loaded {len(people)} people from {BOARD_API}")
elif people:
    print(f"loaded {len(people)} people from {BOARD_API}")

if not people:
    raise SystemExit("no people from kaddish board")

root = Path(__file__).resolve().parents[1]
local_path = root / "assets/data/kaddish_novosibirsk.json"
local = json.loads(local_path.read_text(encoding="utf-8"))
by_id = {int(x["id"]): x for x in local}

out = []
for person in people:
    pid = int(person["id"])
    old = by_id.get(pid, {})
    death = person.get("gregorianDateOfDeath") or {}
    photo = str(person.get("photo") or "").strip()
    if not photo and pid in EXTRA_PHOTOS:
        photo = EXTRA_PHOTOS[pid]
    crop = person.get("photoCrop") if isinstance(person.get("photoCrop"), dict) else None
    thumb = str(person.get("photoThumbUrl") or person.get("photoUrl") or "").strip()
    rec = {
        "id": pid,
        "name": person.get("name") or old.get("name") or "",
        "title": person.get("title") or old.get("title") or "",
        "deathYear": death.get("year") or old.get("deathYear"),
        "deathMonth": death.get("month") or old.get("deathMonth"),
        "deathDay": death.get("date") or old.get("deathDay"),
        "hebrew": old.get("hebrew") or {},
        "photo": photo,
        "photoUrl": absolute_url(thumb) or (photo_url(photo, crop) if photo else ""),
    }
    hebrew_death = person.get("hebrewDateOfDeath")
    if isinstance(hebrew_death, dict) and hebrew_death.get("label"):
        rec["hebrewDeathLabel"] = hebrew_death["label"]
    elif isinstance(hebrew_death, str) and hebrew_death.strip():
        rec["hebrewDeathLabel"] = hebrew_death.strip()
    if crop:
        rec["photoCrop"] = crop
    for key in ("birthYear", "section", "row"):
        if old.get(key):
            rec[key] = old[key]
    out.append(rec)

with_photo = sum(1 for item in out if item.get("photoUrl"))
local_path.write_text(json.dumps(out, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(f"wrote {len(out)} records, {with_photo} with photos")
