import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/data/holidays.dart';
import 'package:flutter_app/services/links.dart';
import 'package:flutter_app/widgets/map_embed.dart';

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

  group('static maps', () {
    test('Novosibirsk tile URL is OSM z/x/y', () {
      final url = osmTileUrl(55.0284, 82.9283);
      expect(url, startsWith('https://tile.openstreetmap.org/16/'));
      expect(url.endsWith('.png'), isTrue);
    });

    test('candidate list prefers Yandex then OSM', () {
      final urls = staticMapCandidateUrls(55.0284, 82.9283);
      expect(urls.first, contains('static-maps.yandex.ru'));
      expect(urls[1], contains('openstreetmap.de'));
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
