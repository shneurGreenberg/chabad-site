import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/data/holidays.dart';
import 'package:flutter_app/services/links.dart';

void main() {
  group('contact links', () {
    test('isolateLtr wraps LTR isolate characters', () {
      final s = isolateLtr('+7 (383) 222-20-23');
      expect(s.startsWith('\u2066'), isTrue);
      expect(s.endsWith('\u2069'), isTrue);
    });

    test('finds email and phone in Hebrew sentence', () {
      const text =
          'להזמנות: +7 (383) 222-20-23 או chabad.nsk@gmail.com בבית מנחם';
      final matches = findContactMatches(text);
      expect(matches.length, 2);
      expect(matches.any((m) => m.isEmail && m.text.contains('chabad')), isTrue);
      expect(matches.any((m) => !m.isEmail && m.url.startsWith('tel:')), isTrue);
    });

    test('telUrl keeps country code', () {
      expect(telUrl('+7 (383) 222-20-23'), 'tel:+73832222023');
    });
  });

  group('holidays', () {
    test('skips Rosh Hashana after it has ended', () {
      final now = DateTime(2026, 9, 15);
      final upcoming = upcomingHolidays(now: now, withinDays: 45);
      expect(
        upcoming.any((h) => (h.name['en'] ?? '').contains('Rosh Hashanah 5787')),
        isFalse,
      );
      expect(
        upcoming.any((h) => (h.name['en'] ?? '').contains('Yom Kippur')),
        isTrue,
      );
    });
  });
}
