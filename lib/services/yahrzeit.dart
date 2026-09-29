import '../models.dart';

class UpcomingYahrzeit {
  UpcomingYahrzeit({required this.grave, required this.next, required this.days});
  final Grave grave;
  final DateTime next;
  final int days;
}

/// Gregorian death-date anniversary. Hebrew conversion needs a calendar API;
/// this still surfaces the next memorial window for the cemetery list.
DateTime? nextYahrzeit(Grave g, [DateTime? from]) {
  final month = g.deathMonth;
  final day = g.deathDay;
  if (month == null || day == null || month < 1 || month > 12 || day < 1) {
    return null;
  }
  final now = from ?? DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  var next = DateTime(now.year, month, day.clamp(1, 28));
  try {
    next = DateTime(now.year, month, day);
  } catch (_) {}
  if (next.isBefore(today)) {
    try {
      next = DateTime(now.year + 1, month, day);
    } catch (_) {
      next = DateTime(now.year + 1, month, day.clamp(1, 28));
    }
  }
  return next;
}

int? daysUntilYahrzeit(Grave g, [DateTime? from]) {
  final next = nextYahrzeit(g, from);
  if (next == null) return null;
  final now = from ?? DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return next.difference(today).inDays;
}

List<UpcomingYahrzeit> upcomingYahrzeits(
  Iterable<Grave> graves, {
  int withinDays = 30,
  DateTime? from,
}) {
  final out = <UpcomingYahrzeit>[];
  for (final g in graves) {
    final next = nextYahrzeit(g, from);
    final days = daysUntilYahrzeit(g, from);
    if (next == null || days == null) continue;
    if (days >= 0 && days <= withinDays) {
      out.add(UpcomingYahrzeit(grave: g, next: next, days: days));
    }
  }
  out.sort((a, b) => a.days.compareTo(b.days));
  return out;
}

/// Hebrew anniversary of a civil death date: the same Hebrew month and day.
///
/// Sunset is not applied. The board stores a Gregorian calendar date and
/// Hebcal displays that civil date as a Hebrew month and day.
class HebrewYahrzeit {
  const HebrewYahrzeit({
    required this.year,
    required this.month,
    required this.day,
    required this.monthName,
    required this.label,
  });

  final int year;

  /// 1 = Tishrei. In a leap year 6 = Adar I and 7 = Adar II; otherwise 6 = Adar
  /// and 7 = Nisan.
  final int month;
  final int day;
  final String monthName;

  /// Hebrew day and month, for example `ג׳ בשבט`.
  final String label;
}

HebrewYahrzeit? hebrewYahrzeitFromGregorian({
  required int year,
  required int month,
  required int day,
}) {
  if (!_isGregorianDate(year, month, day)) return null;
  final hebrew = _julianDayToHebrew(_gregorianToJulianDay(year, month, day));
  final leap = _isHebrewLeapYear(hebrew.year);
  final monthName = _hebrewMonthName(hebrew.month, leap: leap);
  final dayLabel = _hebrewDay(hebrew.day);
  return HebrewYahrzeit(
    year: hebrew.year,
    month: hebrew.month,
    day: hebrew.day,
    monthName: monthName,
    label: '$dayLabel ב$monthName',
  );
}

bool _isGregorianDate(int year, int month, int day) {
  if (year < 1 || month < 1 || month > 12 || day < 1 || day > 31) return false;
  final date = DateTime.utc(year, month, day);
  return date.year == year && date.month == month && date.day == day;
}

bool _isHebrewLeapYear(int year) => (year * 7 + 1) % 19 < 7;

int _elapsedMonths(int hebrewYear) => (235 * (hebrewYear - 1) + 1) ~/ 19;

/// Days from the Hebrew epoch to 1 Tishrei of [hebrewYear], with dehiyyot.
int _elapsedDays(int hebrewYear) {
  final months = _elapsedMonths(hebrewYear);
  final parts = 204 + 793 * (months % 1080);
  final hours = 5 + 12 * months + 793 * (months ~/ 1080) + parts ~/ 1080;
  final day = 1 + 29 * months + hours ~/ 24;
  final remainder = hours % 24;
  final partsMod = parts % 1080;
  final dow = day % 7;
  final postpone =
      remainder >= 18 ||
      (dow == 2 &&
          remainder >= 9 &&
          partsMod >= 204 &&
          !_isHebrewLeapYear(hebrewYear)) ||
      (dow == 1 &&
          remainder >= 15 &&
          partsMod >= 589 &&
          _isHebrewLeapYear(hebrewYear - 1));
  if (postpone) {
    final next = (dow + 1) % 7;
    if (next == 0 || next == 3 || next == 5) return day + 2;
    return day + 1;
  }
  if (dow == 0 || dow == 3 || dow == 5) return day + 1;
  return day;
}

int _daysInHebrewYear(int hebrewYear) =>
    _elapsedDays(hebrewYear + 1) - _elapsedDays(hebrewYear);

int _daysInHebrewMonth(int hebrewYear, int month) {
  final leap = _isHebrewLeapYear(hebrewYear);
  final canonical = leap ? month : (month >= 7 ? month + 1 : month);
  switch (canonical) {
    case 1:
      return 30;
    case 2:
      return _daysInHebrewYear(hebrewYear) % 10 == 5 ? 30 : 29;
    case 3:
      return _daysInHebrewYear(hebrewYear) % 10 == 3 ? 29 : 30;
    case 4:
      return 29;
    case 5:
      return 30;
    case 6:
      return leap ? 30 : 29;
    case 7:
      return 29;
    case 8:
      return 30;
    case 9:
      return 29;
    case 10:
      return 30;
    case 11:
      return 29;
    case 12:
      return 30;
    case 13:
      return 29;
    default:
      return 0;
  }
}

/// Julian day of the civil date. The time of day is ignored.
int _gregorianToJulianDay(int year, int month, int day) {
  final a = (14 - month) ~/ 12;
  final y = year + 4800 - a;
  final m = month + 12 * a - 3;
  return day +
      (153 * m + 2) ~/ 5 +
      365 * y +
      y ~/ 4 -
      y ~/ 100 +
      y ~/ 400 -
      32045;
}

/// Day before 1 Tishrei, year 1. `_elapsedDays` is 1-based for that year.
const _hebrewEpochJd = 347997;

({int year, int month, int day}) _julianDayToHebrew(int jd) {
  var year = (jd - _hebrewEpochJd) ~/ 365 + 3761;
  while (jd >= _hebrewEpochJd + _elapsedDays(year + 1)) {
    year++;
  }
  while (jd < _hebrewEpochJd + _elapsedDays(year)) {
    year--;
  }
  final dayInYear = jd - (_hebrewEpochJd + _elapsedDays(year));
  var month = 1;
  var accumulated = 0;
  final months = _isHebrewLeapYear(year) ? 13 : 12;
  while (month <= months) {
    final length = _daysInHebrewMonth(year, month);
    if (accumulated + length > dayInYear) break;
    accumulated += length;
    month++;
  }
  return (year: year, month: month, day: dayInYear - accumulated + 1);
}

const _monthNames = [
  'תשרי',
  'חשון',
  'כסלו',
  'טבת',
  'שבט',
  'אדר',
  'אדר ב׳',
  'ניסן',
  'אייר',
  'סיון',
  'תמוז',
  'אב',
  'אלול',
];

String _hebrewMonthName(int month, {required bool leap}) {
  if (leap && month == 6) return 'אדר א׳';
  if (leap && month == 7) return 'אדר ב׳';
  if (leap) return _monthNames[month - 1];
  if (month <= 6) return _monthNames[month - 1];
  return _monthNames[month];
}

const _hebrewDays = [
  '',
  'א׳',
  'ב׳',
  'ג׳',
  'ד׳',
  'ה׳',
  'ו׳',
  'ז׳',
  'ח׳',
  'ט׳',
  'י׳',
  'י״א',
  'י״ב',
  'י״ג',
  'י״ד',
  'ט״ו',
  'ט״ז',
  'י״ז',
  'י״ח',
  'י״ט',
  'כ׳',
  'כ״א',
  'כ״ב',
  'כ״ג',
  'כ״ד',
  'כ״ה',
  'כ״ו',
  'כ״ז',
  'כ״ח',
  'כ״ט',
  'ל׳',
];

String _hebrewDay(int day) {
  if (day < 1 || day >= _hebrewDays.length) return '$day';
  return _hebrewDays[day];
}
