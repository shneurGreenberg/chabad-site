import 'dart:convert';

import '../models.dart';
import 'cors_proxy.dart';

class GeoPlace {
  GeoPlace({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.timezone,
    this.region = '',
  });
  final String name;
  final double latitude;
  final double longitude;
  final String timezone;
  final String region;

  String get label {
    if (region.trim().isEmpty) return name;
    return '$name, $region';
  }
}

class LocationZmanimApi {
  static Future<List<GeoPlace>> searchCity(String query, {String lang = 'he'}) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final url =
        'https://geocoding-api.open-meteo.com/v1/search?name=${Uri.encodeQueryComponent(q)}&count=6&language=$lang';
    final json = await _json(url);
    final results = json['results'] as List? ?? const [];
    final places = <GeoPlace>[];
    for (final raw in results) {
      if (raw is! Map) continue;
      final name = (raw['name'] as String?)?.trim() ?? '';
      final lat = (raw['latitude'] as num?)?.toDouble();
      final lon = (raw['longitude'] as num?)?.toDouble();
      if (name.isEmpty || lat == null || lon == null) continue;
      var tz = (raw['timezone'] as String?)?.trim() ?? '';
      if (tz.isEmpty) tz = await lookupTimezone(lat, lon);
      final region = [
        raw['admin1'],
        raw['country'],
      ].whereType<String>().where((s) => s.trim().isNotEmpty).join(', ');
      places.add(GeoPlace(
        name: name,
        latitude: lat,
        longitude: lon,
        timezone: tz,
        region: region,
      ));
    }
    return places;
  }

  static Future<GeoPlace> fromCoordinates(double lat, double lon, {String lang = 'he'}) async {
    final url =
        'https://geocoding-api.open-meteo.com/v1/reverse?latitude=$lat&longitude=$lon&language=$lang';
    try {
      final json = await _json(url);
      final results = json['results'] as List? ?? const [];
      if (results.isNotEmpty && results.first is Map) {
        final raw = results.first as Map;
        final name = (raw['name'] as String?)?.trim();
        var tz = (raw['timezone'] as String?)?.trim() ?? '';
        if (tz.isEmpty) tz = await lookupTimezone(lat, lon);
        final region = [
          raw['admin1'],
          raw['country'],
        ].whereType<String>().where((s) => s.trim().isNotEmpty).join(', ');
        return GeoPlace(
          name: (name == null || name.isEmpty) ? 'מיקום נוכחי' : name,
          latitude: lat,
          longitude: lon,
          timezone: tz,
          region: region,
        );
      }
    } catch (_) {}
    final tz = await lookupTimezone(lat, lon);
    return GeoPlace(
      name: 'מיקום נוכחי',
      latitude: lat,
      longitude: lon,
      timezone: tz,
    );
  }

  static Future<String> lookupTimezone(double lat, double lon) async {
    try {
      final url =
          'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m';
      final json = await _json(url);
      final tz = (json['timezone'] as String?)?.trim();
      if (tz != null && tz.isNotEmpty) return tz;
    } catch (_) {}
    final offsetH = (lon / 15).round().clamp(-12, 14);
    final sign = offsetH >= 0 ? '+' : '-';
    return 'Etc/GMT$sign${offsetH.abs()}';
  }

  static Future<({List<Zman> zmanim, Map<String, String> shabbat})> fetchTimes(
    SiteLocation loc,
  ) async {
    final lat = loc.latitude;
    final lon = loc.longitude;
    final tz = Uri.encodeQueryComponent(loc.timezone);

    final zmanimJson = await _json(
      'https://www.hebcal.com/zmanim?cfg=json&latitude=$lat&longitude=$lon&tzid=$tz',
    );
    final times = (zmanimJson['times'] as Map?) ?? {};

    String t(String key) {
      final raw = times[key];
      if (raw is String && raw.contains('T')) {
        final clock = raw.split('T').last;
        if (clock.length >= 5) return clock.substring(0, 5);
      }
      return '--:--';
    }

    final zmanim = <Zman>[
      Zman(name: {'he': 'עלות השחר', 'en': 'Dawn', 'ru': 'Рассвет'}, time: t('alotHaShachar')),
      Zman(name: {'he': 'הנץ החמה', 'en': 'Sunrise', 'ru': 'Восход'}, time: t('sunrise')),
      Zman(name: {'he': 'סוף זמן ק"ש', 'en': 'Latest Shema', 'ru': 'Крайний Шма'}, time: t('sofZmanShma')),
      Zman(name: {'he': 'סוף זמן תפילה', 'en': 'Latest Shacharit', 'ru': 'Крайняя Шахарит'}, time: t('sofZmanTfilla')),
      Zman(name: {'he': 'חצות היום', 'en': 'Midday', 'ru': 'Полдень'}, time: t('chatzot')),
      Zman(name: {'he': 'מנחה גדולה', 'en': 'Mincha Gedola', 'ru': 'Минха гдола'}, time: t('minchaGedola')),
      Zman(name: {'he': 'שקיעה', 'en': 'Sunset', 'ru': 'Закат'}, time: t('sunset')),
      Zman(name: {'he': 'צאת הכוכבים', 'en': 'Nightfall', 'ru': 'Появление звёзд'}, time: t('tzeit')),
    ];

    final shabbatEn = await _json(
      'https://www.hebcal.com/shabbat?cfg=json&leyning=1&M=on&c=on&latitude=$lat&longitude=$lon&tzid=$tz',
    );
    final shabbatHe = await _json(
      'https://www.hebcal.com/shabbat?cfg=json&leyning=1&M=on&c=on&lg=h&latitude=$lat&longitude=$lon&tzid=$tz',
    );
    Map<String, dynamic> shabbatRu = const {};
    try {
      shabbatRu = await _json(
        'https://www.hebcal.com/shabbat?cfg=json&leyning=1&M=on&c=on&lg=ru&latitude=$lat&longitude=$lon&tzid=$tz',
      );
    } catch (_) {}

    String itemTime(Map<String, dynamic> json, String category) {
      for (final item in json['items'] as List? ?? const []) {
        if (item is! Map) continue;
        if (item['category'] != category) continue;
        final date = item['date'] as String?;
        if (date != null && date.contains('T')) {
          final clock = date.split('T').last;
          if (clock.length >= 5) return clock.substring(0, 5);
        }
      }
      return '--:--';
    }

    String parasha(Map<String, dynamic> json, {String? hebrewFallback}) {
      for (final item in json['items'] as List? ?? const []) {
        if (item is! Map) continue;
        if (item['category'] != 'parashat') continue;
        if (hebrewFallback != null) {
          final h = item['hebrew'] as String?;
          if (h != null && h.trim().isNotEmpty) return h.trim();
        }
        final title = (item['title'] as String?)?.trim();
        if (title != null && title.isNotEmpty) return title;
      }
      return hebrewFallback ?? '';
    }

    final heName = parasha(shabbatHe, hebrewFallback: '');
    final enName = parasha(shabbatEn);
    final ruName = parasha(shabbatRu);
    final hebrewFromEn = parasha(shabbatEn, hebrewFallback: 'x');

    return (
      zmanim: zmanim,
      shabbat: {
        'candle': itemTime(shabbatEn, 'candles'),
        'havdala': itemTime(shabbatEn, 'havdalah'),
        'parasha_he': heName.isNotEmpty ? heName : hebrewFromEn,
        'parasha_en': enName,
        'parasha_ru': ruName.isNotEmpty ? ruName : enName,
      },
    );
  }

  static Future<Map<String, dynamic>> _json(String url) async {
    final res = await CorsProxy.getDirectOrProxy(url);
    final body = res.body.trim();
    if (body.startsWith('<')) {
      throw Exception('blocked');
    }
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    throw Exception('bad json');
  }
}
