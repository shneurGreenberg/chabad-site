import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models.dart';

Loc locFrom(dynamic v) {
  if (v is! Map) return {};
  return {
    for (final e in v.entries) e.key.toString(): '${e.value ?? ''}',
  };
}

/// Hours used to be a plain string; keep old snapshots readable.
Loc locFromFlexible(dynamic v) {
  if (v is String) {
    final s = v.trim();
    if (s.isEmpty) return {};
    return {'he': s, 'en': s, 'ru': s};
  }
  return locFrom(v);
}

Map<String, String> locTo(Loc loc) => Map<String, String>.from(loc);

String? compactImageUrl(String? url) {
  if (url == null || url.isEmpty || url.startsWith('data:')) return null;
  return url;
}

String? imageIdOf(String kind, String id, {Uint8List? bytes}) {
  if (bytes == null || bytes.isEmpty) return null;
  return '$kind:$id';
}

String? bytesToB64(Uint8List? bytes) {
  if (bytes == null || bytes.isEmpty) return null;
  return base64Encode(bytes);
}

Uint8List? b64ToBytes(dynamic v) {
  if (v is! String || v.isEmpty) return null;
  try {
    return base64Decode(v);
  } catch (_) {
    return null;
  }
}

IconData iconFrom(dynamic code, IconData fallback) {
  final n = code is num ? code.toInt() : int.tryParse('$code');
  if (n == null) return fallback;
  // IconData.codePoint is typed as a const parameter; runtime restore is intentional.
  // ignore: non_const_argument_for_const_parameter
  return IconData(n, fontFamily: 'MaterialIcons');
}

int iconTo(IconData icon) => icon.codePoint;

Map<String, dynamic> newsToJson(NewsArticle a) => {
      'id': a.id,
      'title': locTo(a.title),
      'body': locTo(a.body),
      'date': a.date.toIso8601String(),
      'category': locTo(a.category),
      'imageColor': a.imageColor,
      'icon': iconTo(a.icon),
      'source': a.source.name,
      'published': a.published,
      'imageUrl': compactImageUrl(a.imageUrl),
      'imageId': imageIdOf('news', a.id, bytes: a.imageBytes),
      'telegramMessageId': a.telegramMessageId,
      'telegramPublishedId': a.telegramPublishedId,
      'telegramPublishedAt': a.telegramPublishedAt?.toIso8601String(),
    };

NewsArticle newsFromJson(dynamic raw) {
  final m = Map<String, dynamic>.from(raw as Map);
  return NewsArticle(
    id: '${m['id']}',
    title: locFrom(m['title']),
    body: locFrom(m['body']),
    date: DateTime.tryParse('${m['date']}') ?? DateTime.now(),
    category: locFrom(m['category']),
    imageColor: (m['imageColor'] as num?)?.toInt() ?? 0xFF1E3A8A,
    icon: iconFrom(m['icon'], Icons.article_outlined),
    source: NewsSource.values.firstWhere(
      (e) => e.name == m['source'],
      orElse: () => NewsSource.manual,
    ),
    published: m['published'] != false,
    imageBytes: b64ToBytes(m['image']),
    imageUrl: compactImageUrl(
      m['imageUrl'] is String ? '${m['imageUrl']}' : null,
    ),
    telegramMessageId: (m['telegramMessageId'] as num?)?.toInt(),
    telegramPublishedId: (m['telegramPublishedId'] as num?)?.toInt(),
    telegramPublishedAt: DateTime.tryParse('${m['telegramPublishedAt'] ?? ''}'),
  );
}

Map<String, dynamic> programToJson(Program p) => {
      'id': p.id,
      'title': locTo(p.title),
      'description': locTo(p.description),
      'schedule': locTo(p.schedule),
      'audience': locTo(p.audience),
      'icon': iconTo(p.icon),
      'color': p.color,
      'imageUrl': compactImageUrl(p.imageUrl),
      'imageId': imageIdOf('program', p.id, bytes: p.imageBytes),
    };

Program programFromJson(dynamic raw) {
  final m = Map<String, dynamic>.from(raw as Map);
  return Program(
    id: '${m['id']}',
    title: locFrom(m['title']),
    description: locFrom(m['description']),
    schedule: locFrom(m['schedule']),
    audience: locFrom(m['audience']),
    icon: iconFrom(m['icon'], Icons.groups_outlined),
    color: (m['color'] as num?)?.toInt() ?? 0xFF0EA5E9,
    imageBytes: b64ToBytes(m['image']),
    imageUrl: compactImageUrl(
      m['imageUrl'] is String ? '${m['imageUrl']}' : null,
    ),
  );
}

Map<String, dynamic> productToJson(Product p) => {
      'id': p.id,
      'name': locTo(p.name),
      'description': locTo(p.description),
      'price': p.price,
      'category': p.category.name,
      'color': p.color,
      'icon': iconTo(p.icon),
      'imageUrl': compactImageUrl(p.imageUrl),
      'imageId': imageIdOf('product', p.id, bytes: p.imageBytes),
    };

Product productFromJson(dynamic raw) {
  final m = Map<String, dynamic>.from(raw as Map);
  return Product(
    id: '${m['id']}',
    name: locFrom(m['name']),
    description: locFrom(m['description']),
    price: (m['price'] as num?)?.toDouble() ?? 0,
    category: ProductCategory.values.firstWhere(
      (e) => e.name == m['category'],
      orElse: () => ProductCategory.judaica,
    ),
    color: (m['color'] as num?)?.toInt() ?? 0xFF059669,
    icon: iconFrom(m['icon'], Icons.shopping_bag_outlined),
    imageBytes: b64ToBytes(m['image']),
    imageUrl: compactImageUrl(
      m['imageUrl'] is String ? '${m['imageUrl']}' : null,
    ),
  );
}

Map<String, dynamic> galleryShotToJson(String albumId, GalleryShot s) => {
      'id': s.id,
      'imageUrl': compactImageUrl(s.imageUrl),
      'imageId': imageIdOf('gallery', '$albumId:${s.id}', bytes: s.imageBytes),
    };

GalleryShot galleryShotFromJson(dynamic raw) {
  final m = Map<String, dynamic>.from(raw as Map);
  return GalleryShot(
    id: '${m['id']}',
    imageBytes: b64ToBytes(m['image']),
    imageUrl: compactImageUrl(
      m['imageUrl'] is String ? '${m['imageUrl']}' : null,
    ),
  );
}

Map<String, dynamic> galleryToJson(GalleryPhoto p) => {
      'id': p.id,
      'event': locTo(p.event),
      'year': p.year,
      'tags': p.tags,
      'color': p.color,
      'icon': iconTo(p.icon),
      'imageUrl': compactImageUrl(p.imageUrl),
      'imageId': imageIdOf('gallery', p.id, bytes: p.imageBytes),
      'photos': [for (final s in p.photos) galleryShotToJson(p.id, s)],
    };

GalleryPhoto galleryFromJson(dynamic raw) {
  final m = Map<String, dynamic>.from(raw as Map);
  final id = '${m['id']}';
  final photos = <GalleryShot>[
    if (m['photos'] is List)
      for (final item in m['photos'] as List) galleryShotFromJson(item),
  ];
  final imageBytes = b64ToBytes(m['image']);
  final imageUrl = compactImageUrl(
    m['imageUrl'] is String ? '${m['imageUrl']}' : null,
  );
  if (photos.isEmpty &&
      ((imageBytes != null && imageBytes.isNotEmpty) ||
          (imageUrl != null && imageUrl.isNotEmpty))) {
    photos.add(GalleryShot(
      id: '${id}_cover',
      imageBytes: imageBytes,
      imageUrl: imageUrl,
    ));
  }
  return GalleryPhoto(
    id: id,
    event: locFrom(m['event']),
    year: (m['year'] as num?)?.toInt() ?? DateTime.now().year,
    tags: [
      for (final t in (m['tags'] as List? ?? const [])) '$t',
    ],
    color: (m['color'] as num?)?.toInt() ?? 0xFF1D4ED8,
    icon: iconFrom(m['icon'], Icons.photo_camera_back_outlined),
    imageBytes: imageBytes,
    imageUrl: imageUrl,
    photos: photos,
  );
}

Map<String, dynamic> bannerToJson(PageBanner b) => {
      'url': compactImageUrl(b.imageUrl),
      'x': b.alignX,
      'y': b.alignY,
    };

PageBanner bannerFromJson(dynamic raw) {
  if (raw is! Map) return PageBanner();
  final m = Map<String, dynamic>.from(raw);
  return PageBanner(
    bytes: b64ToBytes(m['image']),
    imageUrl: compactImageUrl(m['url'] is String ? '${m['url']}' : null),
    alignX: (m['x'] as num?)?.toDouble() ?? 0,
    alignY: (m['y'] as num?)?.toDouble() ?? 0,
  );
}

Map<String, dynamic> leadToJson(Lead l) => {
      'id': l.id,
      'name': l.name,
      'email': l.email,
      'phone': l.phone,
      'topic': locTo(l.topic),
      'date': l.date.toIso8601String(),
      'status': l.status.name,
      'source': l.source,
    };

Lead leadFromJson(dynamic raw) {
  final m = Map<String, dynamic>.from(raw as Map);
  return Lead(
    id: '${m['id']}',
    name: '${m['name'] ?? ''}',
    email: '${m['email'] ?? ''}',
    phone: '${m['phone'] ?? ''}',
    topic: locFrom(m['topic']),
    date: DateTime.tryParse('${m['date']}') ?? DateTime.now(),
    status: LeadStatus.values.firstWhere(
      (e) => e.name == m['status'],
      orElse: () => LeadStatus.fresh,
    ),
    source: '${m['source'] ?? 'website'}',
  );
}

Map<String, dynamic> donationToJson(Donation d) => {
      'id': d.id,
      'donor': d.donor,
      'amount': d.amount,
      'campaign': locTo(d.campaign),
      'date': d.date.toIso8601String(),
    };

Donation donationFromJson(dynamic raw) {
  final m = Map<String, dynamic>.from(raw as Map);
  return Donation(
    id: '${m['id']}',
    donor: '${m['donor'] ?? ''}',
    amount: (m['amount'] as num?)?.toDouble() ?? 0,
    campaign: locFrom(m['campaign']),
    date: DateTime.tryParse('${m['date']}') ?? DateTime.now(),
  );
}

Map<String, dynamic> botToJson(BotConfig b) => {
      'name': b.name,
      'handle': b.handle,
      'enabled': b.enabled,
      'lastSync': b.lastSync.toIso8601String(),
      'itemsSynced': b.itemsSynced,
    };

void botFromJson(BotConfig target, dynamic raw) {
  if (raw is! Map) return;
  final m = Map<String, dynamic>.from(raw);
  target.name = '${m['name'] ?? target.name}';
  target.handle = '${m['handle'] ?? target.handle}';
  target.enabled = m['enabled'] != false;
  target.lastSync =
      DateTime.tryParse('${m['lastSync']}') ?? target.lastSync;
  target.itemsSynced =
      (m['itemsSynced'] as num?)?.toInt() ?? target.itemsSynced;
}

Map<String, dynamic> locationToJson(SiteLocation l) => {
      'city': l.cityName,
      'query': l.query,
      'lat': l.latitude,
      'lon': l.longitude,
      'tz': l.timezone,
    };

SiteLocation locationFromJson(dynamic raw, SiteLocation fallback) {
  if (raw is! Map) return fallback;
  final m = Map<String, dynamic>.from(raw);
  return SiteLocation(
    cityName: '${m['city'] ?? fallback.cityName}',
    query: '${m['query'] ?? fallback.query}',
    latitude: (m['lat'] as num?)?.toDouble() ?? fallback.latitude,
    longitude: (m['lon'] as num?)?.toDouble() ?? fallback.longitude,
    timezone: '${m['tz'] ?? fallback.timezone}',
  );
}

Map<String, dynamic> contactToJson(ContactInfo c) => {
      'name': locTo(c.name),
      'address': locTo(c.address),
      'phone': c.phone,
      'email': c.email,
      'hours': [
        for (final h in c.hours) {'day': locTo(h.key), 'hours': locTo(h.value)},
      ],
      'staff': [
        for (final s in c.staff)
          {
            'name': locTo(s.name),
            'role': locTo(s.role),
            'phone': s.phone,
          },
      ],
    };

void contactFromJson(ContactInfo target, dynamic raw) {
  if (raw is! Map) return;
  final m = Map<String, dynamic>.from(raw);
  final name = locFrom(m['name']);
  if (name.isNotEmpty) target.name = name;
  final address = locFrom(m['address']);
  if (address.isNotEmpty) target.address = address;
  if (m['phone'] != null) target.phone = '${m['phone']}';
  if (m['email'] != null) target.email = '${m['email']}';
  final hours = m['hours'];
  if (hours is List && hours.isNotEmpty) {
    target.hours
      ..clear()
      ..addAll([
        for (final h in hours)
          if (h is Map)
            MapEntry(locFrom(h['day']), locFromFlexible(h['hours'])),
      ]);
  }
  final staff = m['staff'];
  if (staff is List && staff.isNotEmpty) {
    target.staff
      ..clear()
      ..addAll([
        for (final s in staff)
          if (s is Map)
            StaffContact(
              name: locFrom(s['name']),
              role: locFrom(s['role']),
              phone: '${s['phone'] ?? ''}',
            ),
      ]);
  }
}

Map<String, dynamic> subscriberToJson(NewsletterSubscriber s) => {
      'email': s.email,
      'date': s.date.toIso8601String(),
    };

NewsletterSubscriber subscriberFromJson(dynamic raw) {
  final m = Map<String, dynamic>.from(raw as Map);
  return NewsletterSubscriber(
    email: '${m['email'] ?? ''}'.trim().toLowerCase(),
    date: DateTime.tryParse('${m['date']}') ?? DateTime.now(),
  );
}

Map<String, dynamic> siteCopyToJson(SiteCopy c) => {
      'name': locTo(c.name),
      'city': locTo(c.city),
      'tagline': locTo(c.tagline),
      'aboutSubtitle': locTo(c.aboutSubtitle),
      'aboutBody': locTo(c.aboutBody),
    };

void siteCopyFromJson(SiteCopy target, dynamic raw) {
  if (raw is! Map) return;
  final m = Map<String, dynamic>.from(raw);
  final name = locFrom(m['name']);
  if (name.isNotEmpty) target.name = name;
  final city = locFrom(m['city']);
  if (city.isNotEmpty) target.city = city;
  final tagline = locFrom(m['tagline']);
  if (tagline.isNotEmpty) target.tagline = tagline;
  final aboutSubtitle = locFrom(m['aboutSubtitle']);
  if (aboutSubtitle.isNotEmpty) target.aboutSubtitle = aboutSubtitle;
  final aboutBody = locFrom(m['aboutBody']);
  if (aboutBody.isNotEmpty) target.aboutBody = aboutBody;
}

Map<String, dynamic> famousToJson(FamousPerson p) => {
      'id': p.id,
      'name': locTo(p.name),
      'profession': locTo(p.profession),
      'bio': locTo(p.bio),
      'era': p.era.name,
      'color': p.color,
      'initials': p.initials,
    };

FamousPerson famousFromJson(dynamic raw) {
  final m = Map<String, dynamic>.from(raw as Map);
  return FamousPerson(
    id: '${m['id']}',
    name: locFrom(m['name']),
    profession: locFrom(m['profession']),
    bio: locFrom(m['bio']),
    era: Era.values.firstWhere(
      (e) => e.name == m['era'],
      orElse: () => Era.present,
    ),
    color: (m['color'] as num?)?.toInt() ?? 0xFF7C3AED,
    initials: '${m['initials'] ?? ''}',
  );
}

Map<String, dynamic> historyToJson(HistoryEvent e) => {
      'id': e.id,
      'year': e.year,
      'title': locTo(e.title),
      'description': locTo(e.description),
    };

HistoryEvent historyFromJson(dynamic raw) {
  final m = Map<String, dynamic>.from(raw as Map);
  return HistoryEvent(
    id: '${m['id'] ?? ''}'.isEmpty ? null : '${m['id']}',
    year: '${m['year'] ?? ''}',
    title: locFrom(m['title']),
    description: locFrom(m['description']),
  );
}

Map<String, dynamic> tourToJson(TourStop s) => {
      'id': s.id,
      'name': locTo(s.name),
      'description': locTo(s.description),
      'color': s.color,
      'icon': iconTo(s.icon),
    };

TourStop tourFromJson(dynamic raw) {
  final m = Map<String, dynamic>.from(raw as Map);
  return TourStop(
    id: '${m['id']}',
    name: locFrom(m['name']),
    description: locFrom(m['description']),
    color: (m['color'] as num?)?.toInt() ?? 0xFF1D4ED8,
    icon: iconFrom(m['icon'], Icons.location_on_outlined),
  );
}

Map<String, dynamic> shiurToJson(Shiur s) => {
      'id': s.id,
      'title': locTo(s.title),
      'rabbi': locTo(s.rabbi),
      'topic': locTo(s.topic),
      'durationMinutes': s.durationMinutes,
      'date': s.date.toIso8601String(),
      'youtubeUrl': s.youtubeUrl,
    };

Shiur shiurFromJson(dynamic raw) {
  final m = Map<String, dynamic>.from(raw as Map);
  return Shiur(
    id: '${m['id']}',
    title: locFrom(m['title']),
    rabbi: locFrom(m['rabbi']),
    topic: locFrom(m['topic']),
    durationMinutes: (m['durationMinutes'] as num?)?.toInt() ?? 40,
    date: DateTime.tryParse('${m['date']}') ?? DateTime.now(),
    youtubeUrl: '${m['youtubeUrl'] ?? ''}',
  );
}

Map<String, dynamic> graveToJson(Grave g) => {
      'id': g.id,
      'name': g.name,
      'hebrewName': g.hebrewName,
      'birthYear': g.birthYear,
      'deathYear': g.deathYear,
      'deathMonth': g.deathMonth,
      'deathDay': g.deathDay,
      'section': g.section,
      'row': g.row,
      'notes': locTo(g.notes),
      'photoUrl': g.photoUrl,
    };

Grave graveFromJson(dynamic raw) {
  final m = Map<String, dynamic>.from(raw as Map);
  return Grave(
    id: '${m['id']}',
    name: '${m['name'] ?? ''}',
    hebrewName: '${m['hebrewName'] ?? ''}',
    birthYear: (m['birthYear'] as num?)?.toInt(),
    deathYear: (m['deathYear'] as num?)?.toInt() ?? 0,
    deathMonth: (m['deathMonth'] as num?)?.toInt(),
    deathDay: (m['deathDay'] as num?)?.toInt(),
    section: '${m['section'] ?? ''}',
    row: '${m['row'] ?? ''}',
    notes: locFrom(m['notes']),
    photoUrl: '${m['photoUrl'] ?? ''}'.isEmpty ? null : '${m['photoUrl']}',
  );
}

List<Loc> campaignsFromJson(dynamic raw) {
  if (raw is! List) return [];
  return [
    for (final item in raw)
      if (item is Map) locFrom(item),
  ];
}
