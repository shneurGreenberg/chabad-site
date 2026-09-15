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
    final nearNsk = (lat - 55.0).abs() < 1.5 && (lon - 83.0).abs() < 2.5;
    var tzid = loc.timezone.trim();
    if (nearNsk) {
      tzid = 'Asia/Novosibirsk';
    }
    final tz = Uri.encodeQueryComponent(tzid);
    // Novosibirsk geonameid has built-in tz on Hebcal — prefer it near NSK.
    final locQuery = nearNsk
        ? 'geonameid=1496747&tzid=$tz'
        : 'latitude=$lat&longitude=$lon&tzid=$tz';

    final zmanimJson = await _json(
      'https://www.hebcal.com/zmanim?cfg=json&$locQuery',
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

    final today = DateTime.now();
    final startDay = DateTime(today.year, today.month, today.day);
    final endDay = startDay.add(const Duration(days: 16));
    String ymd(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final range = 'start=${ymd(startDay)}&end=${ymd(endDay)}';

    Future<Map<String, dynamic>> cal(String lg) => _json(
          'https://www.hebcal.com/hebcal?v=1&cfg=json&maj=on&min=off&mod=off'
          '&nx=off&ss=off&mf=off&c=on&s=on&M=on&$locQuery&$range'
          '${lg.isEmpty ? '' : '&lg=$lg'}',
        );

    Map<String, dynamic> calEn = const {};
    Map<String, dynamic> calHe = const {};
    Map<String, dynamic> calRu = const {};
    try {
      calEn = await cal('');
    } catch (_) {}
    try {
      calHe = await cal('h');
    } catch (_) {}
    try {
      calRu = await cal('ru');
    } catch (_) {}

    DateTime? itemWhen(Map item) => DateTime.tryParse('${item['date'] ?? ''}');

    List<Map<String, dynamic>> itemsOf(Map<String, dynamic> json) {
      final raw = json['items'];
      if (raw is! List) return const [];
      return [
        for (final item in raw)
          if (item is Map) Map<String, dynamic>.from(item),
      ];
    }

    String clockOf(Map item) => clockFromIso(item['date'] as String?);

    Map<String, dynamic>? firstMatching(
      List<Map<String, dynamic>> items,
      bool Function(Map<String, dynamic>, DateTime) pred,
    ) {
      Map<String, dynamic>? best;
      DateTime? bestAt;
      for (final item in items) {
        final at = itemWhen(item);
        if (at == null || !pred(item, at)) continue;
        if (bestAt == null || at.isBefore(bestAt)) {
          best = item;
          bestAt = at;
        }
      }
      return best;
    }

    final enItems = itemsOf(calEn);
    final heItems = itemsOf(calHe);
    final ruItems = itemsOf(calRu);

    final shabbatCandles = firstMatching(enItems, (item, at) {
      if (item['category'] != 'candles') return false;
      return at.weekday == DateTime.friday &&
          !DateTime(at.year, at.month, at.day).isBefore(startDay);
    });
    final shabbatHavdala = firstMatching(enItems, (item, at) {
      if (item['category'] != 'havdalah') return false;
      return at.weekday == DateTime.saturday &&
          !DateTime(at.year, at.month, at.day).isBefore(startDay);
    });
    final holidayCandles = firstMatching(enItems, (item, at) {
      if (item['category'] != 'candles') return false;
      if (at.weekday == DateTime.friday) return false;
      return !DateTime(at.year, at.month, at.day).isBefore(startDay);
    });
    final holidayHavdalaItem = firstMatching(enItems, (item, at) {
      if (item['category'] != 'havdalah') return false;
      if (at.weekday == DateTime.saturday) return false;
      return !DateTime(at.year, at.month, at.day).isBefore(startDay);
    });

    String parashaOf(List<Map<String, dynamic>> items, {bool hebrew = false}) {
      for (final item in items) {
        if (item['category'] != 'parashat') continue;
        if (hebrew) {
          final h = '${item['hebrew'] ?? ''}'.trim();
          if (h.isNotEmpty) return h;
        }
        final title = '${item['title'] ?? ''}'.trim();
        if (title.isNotEmpty) return title;
      }
      return '';
    }

    String holidayOf(List<Map<String, dynamic>> items, {bool hebrew = false}) {
      for (final item in items) {
        if (item['category'] != 'holiday') continue;
        final sub = '${item['subcat'] ?? ''}';
        final yomtov = item['yomtov'] == true;
        if (!(yomtov || sub == 'major')) continue;
        final title = '${item['title'] ?? ''}'.trim();
        if (title.toLowerCase().startsWith('erev ')) continue;
        final at = itemWhen(item);
        if (at != null && DateTime(at.year, at.month, at.day).isBefore(startDay)) {
          continue;
        }
        if (hebrew) {
          final h = '${item['hebrew'] ?? ''}'.trim();
          if (h.isNotEmpty) return h;
        }
        if (title.isNotEmpty) return title;
      }
      return '';
    }

    var candle = shabbatCandles == null ? '--:--' : clockOf(shabbatCandles);
    var havdala = shabbatHavdala == null ? '--:--' : clockOf(shabbatHavdala);
    final holidayCandle =
        holidayCandles == null ? '' : clockOf(holidayCandles);
    final holidayHavdala =
        holidayHavdalaItem == null ? '' : clockOf(holidayHavdalaItem);

    // If the 16-day calendar missed Friday (network hole), fall back to /shabbat.
    if (candle == '--:--' || havdala == '--:--') {
      try {
        final shabbatEn = await _json(
          'https://www.hebcal.com/shabbat?cfg=json&leyning=1&M=on&c=on&$locQuery',
        );
        String itemTime(Map<String, dynamic> json, String category) {
          for (final item in json['items'] as List? ?? const []) {
            if (item is! Map) continue;
            if (item['category'] != category) continue;
            return clockFromIso(item['date'] as String?);
          }
          return '--:--';
        }
        if (candle == '--:--') candle = itemTime(shabbatEn, 'candles');
        if (havdala == '--:--') havdala = itemTime(shabbatEn, 'havdalah');
      } catch (_) {}
    }

    final heName = parashaOf(heItems, hebrew: true);
    final enName = parashaOf(enItems);
    final ruName = parashaOf(ruItems);
    final hebrewFromEn = parashaOf(enItems, hebrew: true);

    final holidayHe = holidayOf(heItems, hebrew: true);
    final holidayEn = holidayOf(enItems);
    final holidayRu = holidayOf(ruItems);
    final hasHoliday = holidayEn.isNotEmpty ||
        holidayHe.isNotEmpty ||
        holidayCandle.isNotEmpty;

    return (
      zmanim: zmanim,
      shabbat: <String, String>{
        'candle': candle,
        'havdala': havdala,
        'parasha_he': heName.isNotEmpty ? heName : hebrewFromEn,
        'parasha_en': enName,
        'parasha_ru': ruName.isNotEmpty ? ruName : enName,
        'holiday_he': holidayHe.isNotEmpty ? holidayHe : holidayEn,
        'holiday_en': holidayEn,
        'holiday_ru': holidayRu.isNotEmpty ? holidayRu : holidayEn,
        'holiday_candle': holidayCandle,
        'holiday_havdala': holidayHavdala,
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
