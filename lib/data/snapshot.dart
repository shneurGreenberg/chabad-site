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

Map<String, dynamic> galleryToJson(GalleryPhoto p) => {
      'id': p.id,
      'event': locTo(p.event),
      'year': p.year,
      'tags': p.tags,
      'color': p.color,
      'icon': iconTo(p.icon),
      'imageUrl': compactImageUrl(p.imageUrl),
      'imageId': imageIdOf('gallery', p.id, bytes: p.imageBytes),
    };

GalleryPhoto galleryFromJson(dynamic raw) {
  final m = Map<String, dynamic>.from(raw as Map);
  return GalleryPhoto(
    id: '${m['id']}',
    event: locFrom(m['event']),
    year: (m['year'] as num?)?.toInt() ?? DateTime.now().year,
    tags: [
      for (final t in (m['tags'] as List? ?? const [])) '$t',
    ],
    color: (m['color'] as num?)?.toInt() ?? 0xFF1D4ED8,
    icon: iconFrom(m['icon'], Icons.photo_camera_back_outlined),
    imageBytes: b64ToBytes(m['image']),
    imageUrl: compactImageUrl(
      m['imageUrl'] is String ? '${m['imageUrl']}' : null,
    ),
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
        for (final h in c.hours) {'day': locTo(h.key), 'hours': h.value},
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
            MapEntry(locFrom(h['day']), '${h['hours'] ?? ''}'),
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
