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
          name: (name == null || name.isEmpty) 
              ? (lang == 'he' ? 'מיקום נוכחי' : lang == 'ru' ? 'Текущее местоположение' : 'Current location')
              : name,
          latitude: lat,
          longitude: lon,
          timezone: tz,
          region: region,
        );
      }
    } catch (_) {}
    final tz = await lookupTimezone(lat, lon);
    return GeoPlace(
      name: lang == 'he' ? 'מיקום נוכחי' : lang == 'ru' ? 'Текущее местоположение' : 'Current location',
      latitude: lat,
      longitude: lon,
      timezone: tz,
    );
  }

  static Future<String> lookupTimezone(double lat, double lon) async {
    // NSK coords must never fall through to UTC / inverted Etc/GMT.
    if ((lat - 55.0).abs() < 1.5 && (lon - 83.0).abs() < 2.5) {
      return 'Asia/Novosibirsk';
    }
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
    var tzid = loc.timezone.trim();
    if ((lat - 55.0).abs() < 1.5 && (lon - 83.0).abs() < 2.5) {
      tzid = 'Asia/Novosibirsk';
    }
    final tz = Uri.encodeQueryComponent(tzid);

    final zmanimJson = await _json(
      'https://www.hebcal.com/zmanim?cfg=json&latitude=$lat&longitude=$lon&tzid=$tz',
    );
    final times = (zmanimJson['times'] as Map?) ?? {};

    /// Parse Hebcal ISO clock; if offset is present, use wall-clock as given
    /// (primary fix is correct tzid — this just avoids truncating oddly).
    String clockFromIso(String? raw) {
      if (raw == null || !raw.contains('T')) return '--:--';
      final afterT = raw.split('T').last;
      if (afterT.length < 5) return '--:--';
      final hhmm = afterT.substring(0, 5);
      // If UTC (+00:00 / Z) wall clock is noon-ish and loc is NSK, convert +7h.
      final utcish = afterT.contains('+00:00') ||
          afterT.contains('-00:00') ||
          afterT.endsWith('Z') ||
          afterT.contains('+00');
      final hour = int.tryParse(hhmm.substring(0, 2)) ?? -1;
      final nearNsk = (lat - 55.0).abs() < 1.5 && (lon - 83.0).abs() < 2.5;
      if (nearNsk && utcish && hour >= 10 && hour <= 15) {
        final min = int.tryParse(hhmm.substring(3, 5)) ?? 0;
        final localHour = (hour + 7) % 24;
        return '${localHour.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
      }
      return hhmm;
    }

    String t(String key) {
      final raw = times[key];
      if (raw is String) return clockFromIso(raw);
      return '--:--';
    }

    final zmanim = <Zman>[
      Zman(name: {'he': 'עלות השחר', 'en': 'Dawn', 'ru': 'Рассвет'}, time: t('alotHaShachar'), kind: ZmanKind.dawn),
      Zman(name: {'he': 'הנץ החמה', 'en': 'Sunrise', 'ru': 'Восход'}, time: t('sunrise'), kind: ZmanKind.sunrise),
      Zman(name: {'he': 'סוף זמן ק"ש', 'en': 'Latest Shema', 'ru': 'Крайний Шма'}, time: t('sofZmanShma'), kind: ZmanKind.shema),
      Zman(name: {'he': 'סוף זמן תפילה', 'en': 'Latest Shacharit', 'ru': 'Крайняя Шахарит'}, time: t('sofZmanTfilla'), kind: ZmanKind.shacharit),
      Zman(name: {'he': 'חצות היום', 'en': 'Midday', 'ru': 'Полдень'}, time: t('chatzot'), kind: ZmanKind.midday),
      Zman(name: {'he': 'מנחה גדולה', 'en': 'Mincha Gedola', 'ru': 'Минха гдола'}, time: t('minchaGedola'), kind: ZmanKind.mincha),
      Zman(name: {'he': 'שקיעה', 'en': 'Sunset', 'ru': 'Закат'}, time: t('sunset'), kind: ZmanKind.sunset),
      Zman(name: {'he': 'צאת הכוכבים', 'en': 'Nightfall', 'ru': 'Появление звёзд'}, time: t('tzeit'), kind: ZmanKind.stars),
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
        return clockFromIso(date);
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

    /// Major holiday title near candle lighting (e.g. Rosh Hashana).
    String holidayName(Map<String, dynamic> json, {bool hebrew = false}) {
      String fromCandlesMemo() {
        for (final item in json['items'] as List? ?? const []) {
          if (item is! Map) continue;
          if (item['category'] != 'candles') continue;
          final memo = (item['memo'] as String?)?.trim() ?? '';
          if (memo.isNotEmpty) return memo;
        }
        return '';
      }

      for (final item in json['items'] as List? ?? const []) {
        if (item is! Map) continue;
        if (item['category'] != 'holiday') continue;
        final sub = '${item['subcat'] ?? ''}';
        final yomtov = item['yomtov'] == true;
        if (!(yomtov || sub == 'major' || sub == 'modern')) continue;
        if (hebrew) {
          final h = (item['hebrew'] as String?)?.trim();
          if (h != null && h.isNotEmpty) return h;
        }
        final title = (item['title'] as String?)?.trim() ?? '';
        if (title.toLowerCase().startsWith('erev ')) continue;
        if (title.isNotEmpty) return title;
      }
      final memo = fromCandlesMemo();
      if (memo.isNotEmpty) return memo;
      for (final item in json['items'] as List? ?? const []) {
        if (item is! Map) continue;
        if (item['category'] != 'holiday') continue;
        if (hebrew) {
          final h = (item['hebrew'] as String?)?.trim();
          if (h != null && h.isNotEmpty) return h;
        }
        final title = (item['title'] as String?)?.trim();
        if (title != null && title.isNotEmpty) return title;
      }
      return '';
    }

    final heName = parasha(shabbatHe, hebrewFallback: '');
    final enName = parasha(shabbatEn);
    final ruName = parasha(shabbatRu);
    final hebrewFromEn = parasha(shabbatEn, hebrewFallback: 'x');

    final holidayHe = holidayName(shabbatHe, hebrew: true);
    final holidayEn = holidayName(shabbatEn);
    final holidayRu = holidayName(shabbatRu);
    final hasHoliday = holidayEn.isNotEmpty || holidayHe.isNotEmpty;

    // On major holidays Hebcal omits parashat — never leave occasion blank.
    final parashaHeOut = heName.isNotEmpty
        ? heName
        : (hebrewFromEn.isNotEmpty ? hebrewFromEn : (holidayHe.isNotEmpty ? holidayHe : holidayEn));
    final parashaEnOut = enName.isNotEmpty ? enName : holidayEn;
    final parashaRuOut = ruName.isNotEmpty
        ? ruName
        : (enName.isNotEmpty ? enName : (holidayRu.isNotEmpty ? holidayRu : holidayEn));

    final candle = itemTime(shabbatEn, 'candles');
    final havdala = itemTime(shabbatEn, 'havdalah');

    return (
      zmanim: zmanim,
      shabbat: {
        'candle': candle,
        'havdala': havdala,
        'parasha_he': parashaHeOut,
        'parasha_en': parashaEnOut,
        'parasha_ru': parashaRuOut,
        'holiday_he': holidayHe.isNotEmpty ? holidayHe : holidayEn,
        'holiday_en': holidayEn,
        'holiday_ru': holidayRu.isNotEmpty ? holidayRu : holidayEn,
        'is_holiday': hasHoliday ? '1' : '0',
        'fetched_at': DateTime.now().toUtc().toIso8601String(),
      },
    );
  }

  static Future<Map<String, dynamic>> _json(String url) async {
    // Add timestamp to prevent browser caching of stale zmanim data
    final sep = url.contains('?') ? '&' : '?';
    final cacheBust = '${sep}_t=${DateTime.now().millisecondsSinceEpoch}';
    final res = await CorsProxy.getDirectOrProxy('$url$cacheBust');
    final body = res.body.trim();
    if (body.startsWith('<')) {
      throw Exception('blocked');
    }
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    throw Exception('bad json');
  }
}
