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
