# Chabad House Website / אתר בית חב״ד

A community website for a Chabad house, built with **Flutter (web)**, featuring a
public **client side** and an **admin side**, in **three languages** (Hebrew /
English / Russian) with full RTL support. All content is currently **mock data**
and is meant to be wired to a real backend / external CRM later.

אתר קהילתי לבית חב״ד, בנוי ב־**Flutter (web)**, עם **צד לקוח** ציבורי ו־**צד מנהל**,
ב־**שלוש שפות** (עברית / אנגלית / רוסית) ותמיכה מלאה ב־RTL. כל התוכן כרגע
**נתוני דמה** ומיועד לחיבור מאוחר יותר לשרת / מערכת CRM חיצונית.

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
git clone https://github.com/shneurGreenberg/flutter.git
cd flutter
# The app currently lives on this branch (until the PR is merged into main):
git checkout cursor/setup-flutter-dev-environment-cee0
```

> After the PR is merged into `main`, you can skip the `git checkout` step.
> אחרי שתמזג את ה־PR ל־`main`, אפשר לדלג על שורת ה־`git checkout`.

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
Login is a demo — **any email and password work**.

נכנסים לאזור הניהול בכתובת `/#/admin`. ההתחברות היא הדגמה — **כל אימייל וסיסמה יתקבלו**.

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

## Other platforms / פלטפורמות אחרות

The project is also scaffolded for Android, iOS, Linux, macOS and Windows
(`flutter run -d <device>`), but it was designed and tested primarily for **web**.

הפרויקט מוכן גם ל־Android, iOS, Linux, macOS ו־Windows, אך תוכנן ונבדק בעיקר ל־**web**.
