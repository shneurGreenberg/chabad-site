import 'dart:typed_data';

import 'package:flutter/material.dart';

/// A piece of text available in the three supported languages.
///
/// Keys are locale codes: `he`, `en`, `ru`.
typedef Loc = Map<String, String>;

/// Resolves a [Loc] map for the given [lang], falling back gracefully.
String trLoc(Loc map, String lang) {
  if (map.containsKey(lang) && map[lang]!.trim().isNotEmpty) return map[lang]!;
  if (map.containsKey('en') && map['en']!.trim().isNotEmpty) return map['en']!;
  if (map.containsKey('he') && map['he']!.trim().isNotEmpty) return map['he']!;
  return map.values.isNotEmpty ? map.values.first : '';
}

enum NewsSource { manual, telegram }

class NewsArticle {
  NewsArticle({
    required this.id,
    required this.title,
    required this.body,
    required this.date,
    required this.category,
    this.imageColor = 0xFF1E3A8A,
    this.icon = Icons.article_outlined,
    this.source = NewsSource.manual,
    this.published = true,
    this.imageBytes,
    this.imageUrl,
    this.telegramMessageId,
    this.telegramPublishedId,
    this.telegramPublishedAt,
  });

  final String id;
  Loc title;
  Loc body;
  DateTime date;
  Loc category;
  int imageColor;
  IconData icon;
  NewsSource source;
  bool published;
  Uint8List? imageBytes;
  String? imageUrl;
  int? telegramMessageId;
  int? telegramPublishedId;
  DateTime? telegramPublishedAt;

  bool get hasImage =>
      (imageBytes != null && imageBytes!.isNotEmpty) ||
      (imageUrl != null && imageUrl!.isNotEmpty);

  bool get onTelegram =>
      source == NewsSource.telegram ||
      telegramMessageId != null ||
      telegramPublishedId != null;
}

class SiteLocation {
  SiteLocation({
    required this.cityName,
    required this.latitude,
    required this.longitude,
    required this.timezone,
    this.query = '',
  });

  String cityName;
  String query;
  double latitude;
  double longitude;
  String timezone;

  static SiteLocation jerusalem() => SiteLocation(
        cityName: 'ירושלים',
        query: 'ירושלים',
        latitude: 31.7683,
        longitude: 35.2137,
        timezone: 'Asia/Jerusalem',
      );

  static SiteLocation novosibirsk() => SiteLocation(
        cityName: 'נובוסיבירסק',
        query: 'Novosibirsk',
        latitude: 55.0284,
        longitude: 82.9283,
        timezone: 'Asia/Novosibirsk',
      );
}

class Zman {
  Zman({required this.name, required this.time, this.highlight = false});
  Loc name;
  String time;
  bool highlight;
}

class Program {
  Program({
    required this.id,
    required this.title,
    required this.description,
    required this.schedule,
    required this.audience,
    this.icon = Icons.groups_outlined,
    this.color = 0xFF0EA5E9,
    this.imageBytes,
    this.imageUrl,
  });
  final String id;
  Loc title;
  Loc description;
  Loc schedule;
  Loc audience;
  IconData icon;
  int color;
  Uint8List? imageBytes;
  String? imageUrl;

  bool get hasImage =>
      (imageBytes != null && imageBytes!.isNotEmpty) ||
      (imageUrl != null && imageUrl!.isNotEmpty);
}

class GalleryShot {
  GalleryShot({
    required this.id,
    this.imageBytes,
    this.imageUrl,
  });
  final String id;
  Uint8List? imageBytes;
  String? imageUrl;

  bool get hasImage =>
      (imageBytes != null && imageBytes!.isNotEmpty) ||
      (imageUrl != null && imageUrl!.isNotEmpty);
}

class GalleryPhoto {
  GalleryPhoto({
    required this.id,
    required this.event,
    required this.year,
    required this.tags,
    required this.color,
    this.icon = Icons.photo_camera_back_outlined,
    this.imageBytes,
    this.imageUrl,
    List<GalleryShot>? photos,
  }) : photos = photos ?? [];
  final String id;
  Loc event;
  int year;
  List<String> tags;
  int color;
  IconData icon;
  Uint8List? imageBytes;
  String? imageUrl;
  List<GalleryShot> photos;

  Uint8List? get coverBytes {
    if (imageBytes != null && imageBytes!.isNotEmpty) return imageBytes;
    for (final s in photos) {
      if (s.imageBytes != null && s.imageBytes!.isNotEmpty) return s.imageBytes;
    }
    return null;
  }

  String? get coverUrl {
    if (imageUrl != null && imageUrl!.isNotEmpty) return imageUrl;
    for (final s in photos) {
      if (s.imageUrl != null && s.imageUrl!.isNotEmpty) return s.imageUrl;
    }
    return null;
  }

  List<GalleryShot> get displayPhotos {
    if (photos.isNotEmpty) return photos;
    if (coverBytes != null || (coverUrl != null && coverUrl!.isNotEmpty)) {
      return [
        GalleryShot(id: '${id}_cover', imageBytes: imageBytes, imageUrl: imageUrl),
      ];
    }
    return const [];
  }

  int get photoCount => displayPhotos.length;

  bool get hasImage =>
      coverBytes != null || (coverUrl != null && coverUrl!.isNotEmpty);
}

enum Era { present, past }

class FamousPerson {
  FamousPerson({
    required this.id,
    required this.name,
    required this.profession,
    required this.bio,
    required this.era,
    this.color = 0xFF7C3AED,
    this.initials = '',
  });
  final String id;
  Loc name;
  Loc profession;
  Loc bio;
  Era era;
  int color;
  String initials;
}

class Grave {
  Grave({
    required this.id,
    required this.name,
    required this.hebrewName,
    required this.birthYear,
    required this.deathYear,
    required this.section,
    required this.row,
    required this.notes,
    this.photoUrl,
    this.deathMonth,
    this.deathDay,
  });
  final String id;
  String name;
  String hebrewName;
  int? birthYear;
  int deathYear;
  int? deathMonth;
  int? deathDay;
  String section;
  String row;
  Loc notes;
  String? photoUrl;

  String get deathLabel {
    if (deathYear <= 0) return '';
    if (deathDay != null && deathMonth != null) {
      final d = deathDay.toString().padLeft(2, '0');
      final m = deathMonth.toString().padLeft(2, '0');
      return '$d.$m.$deathYear';
    }
    return '$deathYear';
  }
}

class StaffContact {
  StaffContact({
    required this.name,
    required this.role,
    required this.phone,
  });
  Loc name;
  Loc role;
  String phone;
}

class HistoryEvent {
  HistoryEvent({
    String? id,
    required this.year,
    required this.title,
    required this.description,
  }) : id = id ?? 'hist-$year';
  String id;
  String year;
  Loc title;
  Loc description;
}

class SiteCopy {
  SiteCopy({
    required this.name,
    required this.city,
    required this.tagline,
    required this.aboutSubtitle,
    required this.aboutBody,
  });
  Loc name;
  Loc city;
  Loc tagline;
  Loc aboutSubtitle;
  Loc aboutBody;

  static SiteCopy defaults() => SiteCopy(
        name: {
          'he': 'בית חב״ד בית מנחם',
          'en': 'Chabad Beit Menachem',
          'ru': 'Хабад Бейт Менахем',
        },
        city: {
          'he': 'נובוסיבירסק',
          'en': 'Novosibirsk',
          'ru': 'Новосибирск',
        },
        tagline: {
          'he':
              'בית הכנסת והמרכז הקהילתי היהודי בנובוסיבירסק — בית חם לכל יהודי סיביר',
          'en':
              'The synagogue and Jewish community center in Novosibirsk — a home for every Jew in Siberia',
          'ru':
              'Синагога и еврейский общинный центр Новосибирска — дом для каждого еврея Сибири',
        },
        aboutSubtitle: {
          'he': 'בית הכנסת בית מנחם, רחוב שצ׳טינקינה 68, נובוסיבירסק',
          'en': 'Beit Menachem synagogue, 68 Shchetinkina St., Novosibirsk',
          'ru': 'Синагога Бейт Менахем, ул. Щетинкина, 68, Новосибирск',
        },
        aboutBody: {
          'he':
              'בית מנחם הוא המרכז הקהילתי היהודי ובית הכנסת בנובוסיבירסק. הוא נקרא על שם הרבי מליובאוויטש, רבי מנחם מנדל שניאורסון. בראש הקהילה עומדים שליחי חב״ד הרב שניאור זלמן זקלס ורעייתו הרבנית מרים. המבנה נחנך ב־28 באוגוסט 2013: בית כנסת, מקווה לגברים ולנשים, ספרייה, אולם אירועים, חנות כשרה ומרכז ילדים. ליד הקהילה פועלים ליד אור אבנר (משנת 2000) ומרכז «לב» לילדים עם צרכים מיוחדים.',
          'en':
              'Beit Menachem is the Jewish community center and synagogue in Novosibirsk, named for the Lubavitcher Rebbe, Rabbi Menachem Mendel Schneerson. It is led by Chabad emissaries Rabbi Shneur Zalman Zaklos and Rebbetzin Miriam. The building opened on 28 August 2013: sanctuary, men\'s and women\'s mikveh, library, banquet hall, kosher shop and children\'s center. The community also runs Or Avner school (since 2000) and the Lev center for children with special needs.',
          'ru':
              '«Бейт Менахем» — еврейский общинный центр и синагога Новосибирска, названная в честь Любавичского Ребе Менахема-Мендла Шнеерсона. Общину возглавляют посланники Хабада раввин Шнеур Залман Заклос и раббанит Мириам. Здание открыто 28 августа 2013 года: синагога, мужская и женская миквы, библиотека, праздничный зал, кошерный магазин и детский центр. При общине работают лицей «Ор Авнер» (с 2000) и центр «Лев» для детей с особыми потребностями.',
        },
      );
}

class TourStop {
  TourStop({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    this.icon = Icons.location_on_outlined,
  });
  String id;
  Loc name;
  Loc description;
  int color;
  IconData icon;
}

enum ProductCategory { judaica, books, food }

class Product {
  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.color = 0xFF059669,
    this.icon = Icons.shopping_bag_outlined,
    this.imageBytes,
    this.imageUrl,
  });
  final String id;
  Loc name;
  Loc description;
  double price;
  ProductCategory category;
  int color;
  IconData icon;
  Uint8List? imageBytes;
  String? imageUrl;

  bool get hasImage =>
      (imageBytes != null && imageBytes!.isNotEmpty) ||
      (imageUrl != null && imageUrl!.isNotEmpty);
}

class Shiur {
  Shiur({
    required this.id,
    required this.title,
    required this.rabbi,
    required this.topic,
    required this.durationMinutes,
    required this.date,
    this.youtubeUrl = '',
  });
  final String id;
  Loc title;
  Loc rabbi;
  Loc topic;
  int durationMinutes;
  DateTime date;
  String youtubeUrl;
}

enum AdminJump { news, programs, gallery, library, bots, banners }

class AdminReminder {
  AdminReminder({
    required this.id,
    required this.jump,
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });
  final String id;
  final AdminJump jump;
  final IconData icon;
  final Color color;
  final String title;
  final String body;
}

enum LeadStatus { fresh, contacted, member }

/// A CRM lead / registration. In production this data arrives from an external
/// CRM system; here it is mock data.
class Lead {
  Lead({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.topic,
    required this.date,
    this.status = LeadStatus.fresh,
    this.source = 'website',
  });
  final String id;
  String name;
  String email;
  String phone;
  Loc topic;
  DateTime date;
  LeadStatus status;
  String source;
}

class Donation {
  Donation({
    required this.id,
    required this.donor,
    required this.amount,
    required this.campaign,
    required this.date,
  });
  final String id;
  String donor;
  double amount;
  Loc campaign;
  DateTime date;
}

class NewsletterSubscriber {
  NewsletterSubscriber({required this.email, required this.date});
  final String email;
  final DateTime date;
}

enum SubscribeResult { ok, invalid, duplicate }

class SearchHit {
  SearchHit({
    required this.groupKey,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.icon,
  });
  final String groupKey;
  final String title;
  final String subtitle;
  final String route;
  final IconData icon;
}

class BotConfig {
  BotConfig({
    required this.name,
    required this.handle,
    required this.enabled,
    required this.lastSync,
    required this.itemsSynced,
  });
  String name;
  String handle;
  bool enabled;
  DateTime lastSync;
  int itemsSynced;
}

class ContactInfo {
  ContactInfo({
    required this.name,
    required this.address,
    required this.phone,
    required this.email,
    required List<MapEntry<Loc, Loc>> hours,
    List<StaffContact>? staff,
  })  : hours = List<MapEntry<Loc, Loc>>.of(hours),
        staff = List<StaffContact>.of(staff ?? const []);
  Loc name;
  Loc address;
  String phone;
  String email;
  List<MapEntry<Loc, Loc>> hours; // day -> hours
  List<StaffContact> staff;
}

/// A photo that replaces the default blue banner on a page.
class PageBanner {
  PageBanner({this.bytes, this.imageUrl, this.alignX = 0, this.alignY = 0});
  Uint8List? bytes;
  String? imageUrl;
  double alignX;
  double alignY;

  bool get hasImage =>
      (bytes != null && bytes!.isNotEmpty) ||
      (imageUrl != null && imageUrl!.isNotEmpty);
  Alignment get alignment => Alignment(alignX, alignY);
}

class BannerSlot {
  const BannerSlot({
    required this.route,
    required this.labelKey,
    this.tall = false,
  });
  final String route;
  final String labelKey;
  final bool tall;
}

const bannerSlots = [
  BannerSlot(route: '/', labelKey: 'nav.home', tall: true),
  BannerSlot(route: '/news', labelKey: 'nav.news'),
  BannerSlot(route: '/zmanim', labelKey: 'nav.zmanim'),
  BannerSlot(route: '/programs', labelKey: 'nav.programs'),
  BannerSlot(route: '/gallery', labelKey: 'nav.gallery'),
  BannerSlot(route: '/store', labelKey: 'nav.store'),
  BannerSlot(route: '/cemetery', labelKey: 'nav.cemetery'),
  BannerSlot(route: '/famous', labelKey: 'nav.famous'),
  BannerSlot(route: '/history', labelKey: 'nav.history'),
  BannerSlot(route: '/library', labelKey: 'nav.library'),
  BannerSlot(route: '/donate', labelKey: 'nav.donate'),
  BannerSlot(route: '/contact', labelKey: 'nav.contact'),
  BannerSlot(route: '/about', labelKey: 'nav.about'),
];

