import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models.dart';
import '../services/yahrzeit.dart';

/// Live Novosibirsk kaddish registry used by the cemetery page.
const kaddishHost = 'https://synagogue-kadish-shneur.amvera.io';
const kaddishBoardApi = '$kaddishHost/s/novosibirsk/api/board';
const kaddishBoardFullApi = '$kaddishBoardApi?slim=0';
const kaddishBoardPersonApi = '$kaddishHost/s/novosibirsk/api/board/person';
const kaddishPhotoBase = '$kaddishHost/photos/';

/// Direct board call. Long enough for a slow phone, short of the old 22s proxy.
const kaddishDirectTimeout = Duration(seconds: 8);

/// One CORS fallback after the real URL fails to connect. Not a retry chain.
const kaddishProxyTimeout = Duration(seconds: 5);

/// HTTP result for the board loader. A null return means the call did not
/// connect (CORS or network), which is the only case that may use a proxy.
class KaddishResponse {
  const KaddishResponse(this.statusCode, this.body);
  final int statusCode;
  final String body;
}

typedef KaddishGet = Future<KaddishResponse?> Function(
  String url,
  Duration timeout,
);

String kaddishProxyUrl(String target) =>
    'https://corsproxy.io/?${Uri.encodeComponent(target)}';

/// True when the short board omitted biography text.
bool boardDropsText(List<Map<String, dynamic>> people) {
  if (people.isEmpty) return false;
  return people.every((person) => !person.containsKey('text'));
}

Future<KaddishResponse?> kaddishHttpGet(String url, Duration timeout) async {
  try {
    final res = await http
        .get(Uri.parse(url), headers: const {'Accept': 'application/json'})
        .timeout(timeout);
    return KaddishResponse(res.statusCode, res.body);
  } catch (_) {
    return null;
  }
}

/// Loads graves from the public board. The people collection URL is never
/// requested. `?slim=0` is used only when the short board drops `text`.
/// A connecting failure uses one short proxy attempt after the real URL.
Future<List<Grave>> fetchKaddishBoardGraves({KaddishGet? get}) async {
  final fetch = get ?? kaddishHttpGet;
  var usedProxy = false;

  Future<List<Map<String, dynamic>>?> load(String url) async {
    final direct = await fetch(url, kaddishDirectTimeout);
    final directPeople = _peopleIfOk(direct);
    if (directPeople != null) return directPeople;
    if (direct != null) return null;
    if (usedProxy) return null;
    usedProxy = true;
    return _peopleIfOk(await fetch(kaddishProxyUrl(url), kaddishProxyTimeout));
  }

  final short = await load(kaddishBoardApi);
  if (short == null || short.isEmpty) return const [];
  if (!boardDropsText(short)) {
    return [for (final person in short) graveFromKaddish(person)];
  }
  final full = await load(kaddishBoardFullApi);
  final people = (full != null && full.isNotEmpty) ? full : short;
  return [for (final person in people) graveFromKaddish(person)];
}

List<Map<String, dynamic>>? _peopleIfOk(KaddishResponse? res) {
  if (res == null) return null;
  if (res.statusCode < 200 || res.statusCode >= 300 || res.body.isEmpty) {
    return null;
  }
  try {
    final people = peopleFromKaddishJson(jsonDecode(res.body));
    if (people.isEmpty) return null;
    return people;
  } catch (_) {
    return null;
  }
}

/// Files that exist on the photo host even when the board record has no photo.
const kaddishExtraPhotos = {193: '193.jpg'};

List<Map<String, dynamic>> peopleFromKaddishJson(dynamic raw) {
  if (raw is List) {
    return [
      for (final item in raw)
        if (item is Map) Map<String, dynamic>.from(item),
    ];
  }
  if (raw is Map) {
    final people = raw['people'];
    if (people is List) {
      return [
        for (final item in people)
          if (item is Map) Map<String, dynamic>.from(item),
      ];
    }
  }
  return const [];
}

String absoluteKaddishUrl(String value) {
  final v = value.trim();
  if (v.isEmpty) return '';
  if (v.startsWith('http://') || v.startsWith('https://')) return v;
  if (v.startsWith('//')) return 'https:$v';
  if (v.startsWith('/')) return '$kaddishHost$v';
  return '$kaddishPhotoBase$v';
}

/// Kaddish app photo route: `GET /photos/<filename>` on [kaddishHost].
/// An empty filename is not a photo.
String kaddishPhotoFileUrl(String filename) {
  final name = filename.trim();
  if (name.isEmpty || name.contains('/') || name.contains('..')) return '';
  return '$kaddishPhotoBase$name';
}

String photoUrlFromKaddish(String filename, dynamic crop) {
  final fileUrl = kaddishPhotoFileUrl(filename);
  if (fileUrl.isEmpty) return '';
  final query = <String>[];
  if (crop is Map) {
    final x = crop['x'];
    final y = crop['y'];
    final z = crop['zoom'] ?? crop['z'];
    if (x is num && x != 50) query.add('cx=$x');
    if (y is num && y != 50) query.add('cy=$y');
    if (z is num && z != 1) query.add('cz=$z');
  }
  if (query.isEmpty) return fileUrl;
  return '$fileUrl?${query.join('&')}';
}

/// Device pixels along the longer side of a photo frame.
/// One source pixel per screen pixel. A fixed `w=280` jpeg is smaller than a
/// retina detail frame, and painting it into that frame smears the photo.
int sharpPhotoPixels(
  double logicalWidth,
  double logicalHeight,
  double devicePixelRatio,
) {
  final dpr = devicePixelRatio.isFinite && devicePixelRatio > 0
      ? devicePixelRatio
      : 1.0;
  final edge = logicalWidth > logicalHeight ? logicalWidth : logicalHeight;
  final px = (edge * dpr).ceil();
  if (px < 1) return 1;
  if (px > 1600) return 1600;
  return px;
}

/// Same photo URL with `w` set to the on-screen pixel size.
/// Replaces a baked-in tiny width (such as `w=280`) so the jpeg is not
/// stretched up to the frame.
String kaddishPhotoAtPixels(String? url, int pixelWidth) {
  final src = url?.trim() ?? '';
  if (src.isEmpty || pixelWidth <= 0) return src;
  final uri = Uri.tryParse(src);
  if (uri == null) return src;
  final params = Map<String, String>.from(uri.queryParameters);
  params['w'] = '$pixelWidth';
  return uri.replace(queryParameters: params).toString();
}

/// Same-origin cemetery thumb so CanvasKit can paint it.
/// GitHub Pages ships files under `kaddish-photos/`; Amvera nginx proxies that
/// path to the kaddish `/photos/` route (which does not send CORS).
String sameOriginKaddishPhoto(String? url) {
  final src = url?.trim() ?? '';
  if (src.isEmpty) return '';
  final parsed = Uri.tryParse(src);
  final path = parsed?.path.isNotEmpty == true ? parsed!.path : src.split('?').first;
  final name = path.split('/').last;
  if (name.isEmpty || !name.contains('.')) return resolveKaddishPhotoUrl(src);
  final basePath = Uri.base.path;
  final prefix = basePath.endsWith('/') ? basePath : '$basePath/';
  return Uri(
    scheme: Uri.base.scheme,
    host: Uri.base.host,
    port: Uri.base.hasPort ? Uri.base.port : null,
    path: '${prefix}kaddish-photos/$name',
    query: parsed != null && parsed.hasQuery ? parsed.query : null,
  ).toString();
}

/// Resolves a kaddish photo URL for web.
/// Prefer [sameOriginKaddishPhoto] for CanvasKit; this keeps the absolute host
/// URL for fallbacks and non-image uses.
String resolveKaddishPhotoUrl(String? url) {
  final src = url?.trim() ?? '';
  if (src.isEmpty) return '';
  if (src.startsWith('http://') || src.startsWith('https://')) return src;
  if (src.startsWith('/')) return '$kaddishHost$src';
  return '$kaddishPhotoBase$src';
}

String hebrewDeathLabelFromKaddish(dynamic raw) {
  if (raw is String) return raw.trim();
  if (raw is Map) {
    return '${raw['label'] ?? raw['he'] ?? raw['text'] ?? ''}'.trim();
  }
  return '';
}

/// Parse person from API response, handling both wrapped {person: {...}} and bare object.
Map<String, dynamic>? personFromApiResponse(dynamic raw) {
  if (raw is Map<String, dynamic>) {
    // Try wrapped format first: {person: {...}}
    final person = raw['person'];
    if (person is Map<String, dynamic>) {
      return person;
    }
    // Otherwise treat the response itself as the person object
    return raw;
  }
  return null;
}

Grave graveFromKaddish(Map<String, dynamic> m) {
  final idRaw = m['id'];
  final id = idRaw == null ? '' : '$idRaw';
  var photo = '${m['photo'] ?? ''}'.trim();
  final extra = int.tryParse(id);
  if (photo.isEmpty && extra != null && kaddishExtraPhotos.containsKey(extra)) {
    photo = kaddishExtraPhotos[extra]!;
  }
  final thumb = '${m['photoThumbUrl'] ?? m['photoUrl'] ?? ''}'.trim();
  String? photoUrl;
  if (thumb.isNotEmpty) {
    photoUrl = absoluteKaddishUrl(thumb);
  } else if (photo.isNotEmpty) {
    photoUrl = photoUrlFromKaddish(photo, m['photoCrop']);
  }

  final death = m['gregorianDateOfDeath'];
  int? deathYear = (m['deathYear'] as num?)?.toInt();
  int? deathMonth = (m['deathMonth'] as num?)?.toInt();
  int? deathDay = (m['deathDay'] as num?)?.toInt();
  if (death is Map) {
    deathYear ??= (death['year'] as num?)?.toInt();
    deathMonth ??= (death['month'] as num?)?.toInt();
    deathDay ??=
        (death['date'] as num?)?.toInt() ?? (death['day'] as num?)?.toInt();
  }

  final hebrew = m['hebrew'];
  var hebrewName = '${m['hebrewName'] ?? ''}'.trim();
  if (hebrewName.isEmpty) {
    if (hebrew is String) {
      hebrewName = hebrew.trim();
    } else if (hebrew is Map) {
      hebrewName = '${hebrew['name'] ?? hebrew['he'] ?? ''}'.trim();
    }
  }

  final title = '${m['title'] ?? ''}'.trim();
  final bioText = '${m['text'] ?? ''}'.trim();
  final storedHebrew = hebrewDeathLabelFromKaddish(m['hebrewDateOfDeath']);
  final yahrzeit = (deathYear != null && deathMonth != null && deathDay != null)
      ? hebrewYahrzeitFromGregorian(
          year: deathYear,
          month: deathMonth,
          day: deathDay,
        )
      : null;
  return Grave(
    id: 'kaddish-$id',
    name: '${m['name'] ?? ''}'.trim(),
    hebrewName: hebrewName,
    birthYear: (m['birthYear'] as num?)?.toInt(),
    deathYear: deathYear ?? 0,
    deathMonth: deathMonth,
    deathDay: deathDay,
    section: '${m['section'] ?? ''}'.trim(),
    row: '${m['row'] ?? ''}'.trim(),
    notes: title.isEmpty ? const {} : {'he': title, 'en': title, 'ru': title},
    photoUrl: photoUrl,
    hebrewDeathLabel: (yahrzeit != null && yahrzeit.label.isNotEmpty)
        ? yahrzeit.label
        : storedHebrew,
    biographyHtml: bioText.isEmpty ? null : bioText,
  );
}
