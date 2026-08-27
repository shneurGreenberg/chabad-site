import '../models.dart';

/// Live Novosibirsk kaddish registry used by the cemetery page.
const kaddishHost = 'https://synagogue-kadish-shneur.amvera.io';
const kaddishPeopleApi = '$kaddishHost/s/novosibirsk/api/people';
const kaddishBoardApi = '$kaddishHost/s/novosibirsk/api/board';
const kaddishPhotoBase = '$kaddishHost/photos/';

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

String photoUrlFromKaddish(String filename, dynamic crop) {
  final name = filename.trim();
  if (name.isEmpty) return '';
  final query = <String>['w=280'];
  if (crop is Map) {
    final x = crop['x'];
    final y = crop['y'];
    final z = crop['zoom'] ?? crop['z'];
    if (x is num && x != 50) query.add('cx=$x');
    if (y is num && y != 50) query.add('cy=$y');
    if (z is num && z != 1) query.add('cz=$z');
  }
  return '$kaddishPhotoBase$name?${query.join('&')}';
}

/// Resolves a kaddish photo URL to a same-origin path for web deployment.
/// During GitHub Pages deployment, photos are downloaded to kaddish-photos/.
/// This function extracts the filename and returns the local path.
String resolveKaddishPhotoUrl(String? url) {
  final src = url?.trim() ?? '';
  if (src.isEmpty) return '';
  
  // Extract filename from URLs like:
  // - https://synagogue-kadish-shneur.amvera.io/photos/123.jpg?w=280
  // - https://synagogue-kadish-shneur.amvera.io/photos/123.jpg
  final uri = Uri.tryParse(src);
  if (uri != null && uri.pathSegments.isNotEmpty) {
    final filename = uri.pathSegments.last;
    if (filename.isNotEmpty) {
      return 'kaddish-photos/$filename';
    }
  }
  
  return src;
}

String hebrewDeathLabelFromKaddish(dynamic raw) {
  if (raw is String) return raw.trim();
  if (raw is Map) {
    return '${raw['label'] ?? raw['he'] ?? raw['text'] ?? ''}'.trim();
  }
  return '';
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
    hebrewDeathLabel: hebrewDeathLabelFromKaddish(m['hebrewDateOfDeath']),
  );
}

List<Grave> mergeKaddishGraves(List<Grave> live, List<Grave> bundled) {
  if (live.isEmpty) return bundled;
  final extras = {for (final g in bundled) g.id: g};
  return [
    for (final g in live) _withLocalExtras(g, extras[g.id]),
  ];
}

Grave _withLocalExtras(Grave live, Grave? bundled) {
  if (bundled == null) return live;
  if (live.hebrewName.isEmpty && bundled.hebrewName.isNotEmpty) {
    live.hebrewName = bundled.hebrewName;
  }
  if (live.section.isEmpty && bundled.section.isNotEmpty) {
    live.section = bundled.section;
  }
  if (live.row.isEmpty && bundled.row.isNotEmpty) {
    live.row = bundled.row;
  }
  live.birthYear ??= bundled.birthYear;
  if ((live.photoUrl == null || live.photoUrl!.trim().isEmpty) &&
      bundled.photoUrl != null &&
      bundled.photoUrl!.trim().isNotEmpty) {
    live.photoUrl = bundled.photoUrl;
  }
  if (live.hebrewDeathLabel.isEmpty && bundled.hebrewDeathLabel.isNotEmpty) {
    live.hebrewDeathLabel = bundled.hebrewDeathLabel;
  }
  return live;
}
