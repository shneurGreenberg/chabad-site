import '../models.dart';

class JewishHoliday {
  const JewishHoliday({
    required this.start,
    required this.name,
    this.end,
  });

  /// Civil calendar date of the first evening / first day.
  final DateTime start;
  /// Inclusive last civil day of the holiday (optional).
  final DateTime? end;
  final Loc name;

  DateTime get lastDay => end ?? start;
}

/// Fallback calendar when Hebcal is unreachable. Prefer live data from
/// [LocationZmanimApi].
final jewishHolidays = <JewishHoliday>[
  JewishHoliday(
    start: DateTime(2026, 9, 11),
    end: DateTime(2026, 9, 13),
    name: {
      'he': 'ראש השנה תשפ״ז',
      'en': 'Rosh Hashanah 5787',
      'ru': 'Рош ха-Шана 5787',
    },
  ),
  JewishHoliday(
    start: DateTime(2026, 9, 20),
    end: DateTime(2026, 9, 21),
    name: {
      'he': 'יום כיפור',
      'en': 'Yom Kippur',
      'ru': 'Йом Кипур',
    },
  ),
  JewishHoliday(
    start: DateTime(2026, 9, 25),
    end: DateTime(2026, 10, 2),
    name: {
      'he': 'סוכות',
      'en': 'Sukkot',
      'ru': 'Суккот',
    },
  ),
  JewishHoliday(
    start: DateTime(2026, 10, 3),
    end: DateTime(2026, 10, 4),
    name: {
      'he': 'שמחת תורה',
      'en': 'Simchat Torah',
      'ru': 'Симхат Тора',
    },
  ),
  JewishHoliday(
    start: DateTime(2026, 12, 4),
    end: DateTime(2026, 12, 12),
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
    end: DateTime(2027, 4, 29),
    name: {
      'he': 'פסח',
      'en': 'Passover',
      'ru': 'Песах',
    },
  ),
  JewishHoliday(
    start: DateTime(2027, 10, 2),
    end: DateTime(2027, 10, 4),
    name: {
      'he': 'ראש השנה תשפ״ח',
      'en': 'Rosh Hashanah 5788',
      'ru': 'Рош ха-Шана 5788',
    },
  ),
  JewishHoliday(
    start: DateTime(2027, 10, 11),
    end: DateTime(2027, 10, 12),
    name: {
      'he': 'יום כיפור',
      'en': 'Yom Kippur',
      'ru': 'Йом Кипур',
    },
  ),
];

List<JewishHoliday> upcomingHolidays({
  DateTime? now,
  int withinDays = 45,
  List<JewishHoliday>? source,
}) {
  final n = now ?? DateTime.now();
  final today = DateTime(n.year, n.month, n.day);
  final list = source ?? jewishHolidays;
  return [
    for (final h in list)
      if (_daysUntil(today, h.lastDay) >= 0 &&
          _daysUntil(today, h.start) <= withinDays)
        h,
  ];
}

int daysUntilHoliday(JewishHoliday h, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final today = DateTime(n.year, n.month, n.day);
  final untilStart = _daysUntil(today, h.start);
  if (untilStart > 0) return untilStart;
  if (_daysUntil(today, h.lastDay) >= 0) return 0;
  return untilStart;
}

int _daysUntil(DateTime today, DateTime start) {
  final d = DateTime(start.year, start.month, start.day);
  return d.difference(today).inDays;
}

JewishHoliday? holidayFromHebcalItem(Map item) {
  final date = DateTime.tryParse('${item['date'] ?? ''}');
  if (date == null) return null;
  final title = '${item['title'] ?? ''}'.trim();
  if (title.isEmpty) return null;
  if (title.toLowerCase().startsWith('erev ')) return null;
  final he = '${item['hebrew'] ?? ''}'.trim();
  return JewishHoliday(
    start: DateTime(date.year, date.month, date.day),
    name: {
      'he': he.isNotEmpty ? he : title,
      'en': title,
      'ru': title,
    },
  );
}
