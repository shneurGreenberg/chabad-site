import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/models.dart';
import 'package:flutter_app/services/location_zmanim.dart';
import 'package:flutter_app/util/youtube.dart';

void main() {
  group('CachedZmanim', () {
    CachedZmanim sample({
      required DateTime fetchedAt,
      SiteLocation? loc,
      String candle = '18:42',
    }) {
      final place = loc ?? SiteLocation.novosibirsk();
      return CachedZmanim(
        fetchedAt: fetchedAt,
        latitude: place.latitude,
        longitude: place.longitude,
        timezone: place.timezone,
        zmanim: [
          Zman(
            name: const {'he': 'שקיעה', 'en': 'Sunset'},
            time: '19:24',
            kind: ZmanKind.sunset,
          ),
        ],
        shabbat: {
          'candle': candle,
          'havdala': '19:52',
          'parasha_he': 'נצבים',
        },
      );
    }

    test('round-trips json', () {
      final original = sample(fetchedAt: DateTime.utc(2026, 9, 10, 12));
      final parsed = CachedZmanim.fromJson(original.toJson());
      expect(parsed, isNotNull);
      expect(parsed!.latitude, original.latitude);
      expect(parsed.shabbat['candle'], '18:42');
      expect(parsed.zmanim.single.kind, ZmanKind.sunset);
    });

    test('is fresh within 7 days at the same city', () {
      final loc = SiteLocation.novosibirsk();
      final cache = sample(
        fetchedAt: DateTime.utc(2026, 9, 12),
      );
      expect(
        cache.isFreshFor(loc, now: DateTime.utc(2026, 9, 16)),
        isTrue,
      );
    });

    test('is stale after 7 days', () {
      final loc = SiteLocation.novosibirsk();
      final cache = sample(
        fetchedAt: DateTime.utc(2026, 9, 1),
      );
      expect(
        cache.isFreshFor(loc, now: DateTime.utc(2026, 9, 16)),
        isFalse,
      );
    });

    test('is stale when coordinates change', () {
      final cache = sample(fetchedAt: DateTime.utc(2026, 9, 15));
      final jerusalem = SiteLocation(
        cityName: 'ירושלים',
        latitude: 31.7683,
        longitude: 35.2137,
        timezone: 'Asia/Jerusalem',
      );
      expect(
        cache.isFreshFor(jerusalem, now: DateTime.utc(2026, 9, 16)),
        isFalse,
      );
    });

    test('rejects placeholder candle times', () {
      final loc = SiteLocation.novosibirsk();
      final cache = sample(
        fetchedAt: DateTime.utc(2026, 9, 15),
        candle: '--:--',
      );
      expect(
        cache.isFreshFor(loc, now: DateTime.utc(2026, 9, 16)),
        isFalse,
      );
    });
  });

  group('youtube embed', () {
    test('parses watch urls', () {
      expect(
        youtubeIdFrom('https://www.youtube.com/watch?v=OVKQe9fiNu8'),
        'OVKQe9fiNu8',
      );
    });

    test('embed url is landscape-safe and inline', () {
      final url = youtubeEmbedUrl('OVKQe9fiNu8');
      expect(url, contains('/embed/OVKQe9fiNu8'));
      expect(url, contains('playsinline=1'));
      expect(url, contains('fs=1'));
      expect(url, isNot(contains('accelerometer')));
    });
  });
}
