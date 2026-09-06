# Chabad House Website / אתר בית חב״ד

A community website for a Chabad house, built with **Flutter (web)**, featuring a
public **client side** and an **admin side**, in **three languages** (Hebrew /
English / Russian) with full RTL support. The site is live at 
[shneurgreenberg.github.io/chabad-site](https://shneurgreenberg.github.io/chabad-site/)
and [www.jewishsib.com](https://www.jewishsib.com), with full Firebase backend 
integration for content management.

אתר קהילתי לבית חב״ד, בנוי ב־**Flutter (web)**, עם **צד לקוח** ציבורי ו־**צד מנהל**,
ב־**שלוש שפות** (עברית / אנגלית / רוסית) ותמיכה מלאה ב־RTL. האתר חי באתר 
[shneurgreenberg.github.io/chabad-site](https://shneurgreenberg.github.io/chabad-site/)
ו־[www.jewishsib.com](https://www.jewishsib.com), וכולל אינטגרציה אמיתית עם Firebase 
לניהול תוכן.

---

## Run it on your computer / הרצה על המחשב שלך

### 1. Install Flutter / התקנת Flutter

Install the Flutter SDK (stable channel) by following the official guide:
<https://docs.flutter.dev/get-started/install>

Then verify:

```bash
flutter --version   # should be 3.44.x or newer
flutter doctor
```

To run the app in a web browser you also need **Google Chrome** installed.
כדי להריץ בדפדפן צריך גם שיהיה מותקן **Google Chrome**.

### 2. Get the code / הורדת הקוד

```bash
git clone https://github.com/shneurgreenberg/chabad-site.git
cd chabad-site
```

### 3. Install dependencies / התקנת תלויות

```bash
flutter pub get
```

### 4. Run / הרצה

The easiest way is to run in Chrome / הדרך הקלה ביותר היא להריץ ב־Chrome:

```bash
flutter run -d chrome
```

Or serve it on a local URL you can open in any browser
(או להריץ שרת מקומי ולפתוח כתובת בדפדפן כלשהו):

```bash
flutter run -d web-server --web-port 8080
# then open http://localhost:8080
```

Press `r` for hot reload, `R` for hot restart, `q` to quit.
בזמן ריצה: `r` לרענון חם, `R` להפעלה מחדש, `q` ליציאה.

### Admin side / צד המנהל

Open the admin area at `/#/admin` (e.g. `http://localhost:8080/#/admin`).
Login with Firebase authentication or use the demo PIN if configured.

נכנסים לאזור הניהול בכתובת `/#/admin`. התחברות עם Firebase או PIN הדגמה אם מוגדר.

---

## Useful commands / פקודות שימושיות

```bash
flutter analyze                 # static analysis / ניתוח סטטי
flutter test                    # run tests / הרצת בדיקות
flutter build web --release     # production web build / בילד לפרודקשן (output: build/web)
```

### Web tip / טיפ ל־web

If `flutter doctor` complains about something related to web, usually it is enough
to ensure Chrome is installed and run once:

אם `flutter doctor` מתלונן על משהו שקשור ל־web, בדרך כלל מספיק לוודא ש־Chrome מותקן ולהריץ פעם אחת:

```bash
flutter config --enable-web
```

---

## Deployment / פריסה

### GitHub Pages

The site is automatically deployed to GitHub Pages on every push to `main` via 
the workflow in `.github/workflows/deploy-github-pages.yml`. The GitHub Pages 
deployment uses `--base-href /chabad-site/` for the repository path.

האתר מפרוס אוטומטית ל־GitHub Pages בכל push ל־`main` דרך workflow שב־
`.github/workflows/deploy-github-pages.yml`. פריסת GitHub Pages משתמשת ב־
`--base-href /chabad-site/` עבור נתיב הריפו.

### Amvera (Production - www.jewishsib.com)

The production site at [www.jewishsib.com](https://www.jewishsib.com) is deployed 
on **Amvera** using Docker. Files included:

- `Dockerfile` - Multi-stage build (Flutter + nginx)
- `amvera.yaml` - Amvera configuration
- `nginx.conf` - SPA routing with hash-based navigation

האתר הפרודקשן באתר [www.jewishsib.com](https://www.jewishsib.com) מפרוס על **Amvera** 
באמצעות Docker. קבצים שנכללים:

- `Dockerfile` - בניה רב-שלבית (Flutter + nginx)
- `amvera.yaml` - הגדרות Amvera
- `nginx.conf` - ניתוב SPA עם ניווט מבוסס hash

**To deploy to Amvera:**

1. Create a new project on Amvera (suggested name: `chabad-site` or `jewishsib`)
2. Add the Amvera git remote to your local repository
3. Push to the Amvera git remote to trigger deployment
4. Configure custom domain `www.jewishsib.com` in Amvera dashboard

**כדי לפרוס ל־Amvera:**

1. צור פרויקט חדש ב־Amvera (שם מוצע: `chabad-site` או `jewishsib`)
2. הוסף את ה־remote של Amvera למאגר המקומי שלך
3. בצע push ל־remote של Amvera כדי להפעיל את הפריסה
4. הגדר דומיין מותאם אישית `www.jewishsib.com` בלוח הבקרה של Amvera

---

## Other platforms / פלטפורמות אחרות

The project is also scaffolded for Android, iOS, Linux, macOS and Windows
(`flutter run -d <device>`), but it was designed and tested primarily for **web**.

הפרויקט מוכן גם ל־Android, iOS, Linux, macOS ו־Windows, אך תוכנן ונבדק בעיקר ל־**web**.
