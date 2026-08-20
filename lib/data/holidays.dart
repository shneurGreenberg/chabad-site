import '../models.dart';

class JewishHoliday {
  const JewishHoliday({required this.start, required this.name});

  /// Civil calendar date of the first evening / first day.
  final DateTime start;
  final Loc name;
}

/// Upcoming dates for 5787–5788. Evening-before is used for “starts on”.
final jewishHolidays = <JewishHoliday>[
  JewishHoliday(
    start: DateTime(2026, 9, 11),
    name: {
      'he': 'ראש השנה תשפ״ז',
      'en': 'Rosh Hashanah 5787',
      'ru': 'Рош ха-Шана 5787',
    },
  ),
  JewishHoliday(
    start: DateTime(2026, 9, 20),
    name: {
      'he': 'יום כיפור',
      'en': 'Yom Kippur',
      'ru': 'Йом Кипур',
    },
  ),
  JewishHoliday(
    start: DateTime(2026, 9, 25),
    name: {
      'he': 'סוכות',
      'en': 'Sukkot',
      'ru': 'Суккот',
    },
  ),
  JewishHoliday(
    start: DateTime(2026, 10, 3),
    name: {
      'he': 'שמחת תורה',
      'en': 'Simchat Torah',
      'ru': 'Симхат Тора',
    },
  ),
  JewishHoliday(
    start: DateTime(2026, 12, 4),
    name: {
      'he': 'חנוכה',
      'en': 'Chanukah',
      'ru': 'Ханука',
    },
  ),
  JewishHoliday(
    start: DateTime(2027, 3, 22),
    name: {
      'he': 'פורים',
      'en': 'Purim',
      'ru': 'Пурим',
    },
  ),
  JewishHoliday(
    start: DateTime(2027, 4, 21),
    name: {
      'he': 'פסח',
      'en': 'Passover',
      'ru': 'Песах',
    },
  ),
  JewishHoliday(
    start: DateTime(2027, 10, 2),
    name: {
      'he': 'ראש השנה תשפ״ח',
      'en': 'Rosh Hashanah 5788',
      'ru': 'Рош ха-Шана 5788',
    },
  ),
];

List<JewishHoliday> upcomingHolidays({DateTime? now, int withinDays = 45}) {
  final n = now ?? DateTime.now();
  final today = DateTime(n.year, n.month, n.day);
  return [
    for (final h in jewishHolidays)
      if (_daysUntil(today, h.start) >= 0 &&
          _daysUntil(today, h.start) <= withinDays)
        h,
  ];
}

int daysUntilHoliday(JewishHoliday h, {DateTime? now}) {
  final n = now ?? DateTime.now();
  return _daysUntil(DateTime(n.year, n.month, n.day), h.start);
}

int _daysUntil(DateTime today, DateTime start) {
  final d = DateTime(start.year, start.month, start.day);
  return d.difference(today).inDays;
}
