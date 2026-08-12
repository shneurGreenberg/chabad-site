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
    this.telegramMessageId,
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
  int? telegramMessageId;
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
  });
  final String id;
  Loc title;
  Loc description;
  Loc schedule;
  Loc audience;
  IconData icon;
  int color;
  Uint8List? imageBytes;
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
  });
  final String id;
  Loc event;
  int year;
  List<String> tags; // tagged person names (used by "AI face search")
  int color;
  IconData icon;
  Uint8List? imageBytes;
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
  });
  final String id;
  String name;
  String hebrewName;
  int? birthYear;
  int deathYear;
  String section;
  String row;
  Loc notes;
}

class HistoryEvent {
  HistoryEvent({
    required this.year,
    required this.title,
    required this.description,
  });
  String year;
  Loc title;
  Loc description;
}

class TourStop {
  TourStop({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    this.icon = Icons.location_on_outlined,
  });
  final String id;
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
  });
  final String id;
  Loc name;
  Loc description;
  double price;
  ProductCategory category;
  int color;
  IconData icon;
  Uint8List? imageBytes;
}

class Shiur {
  Shiur({
    required this.id,
    required this.title,
    required this.rabbi,
    required this.topic,
    required this.durationMinutes,
    required this.date,
  });
  final String id;
  Loc title;
  Loc rabbi;
  Loc topic;
  int durationMinutes;
  DateTime date;
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
    required this.hours,
  });
  Loc name;
  Loc address;
  String phone;
  String email;
  List<MapEntry<Loc, String>> hours; // day -> hours
}

/// A photo that replaces the default blue banner on a page.
class PageBanner {
  PageBanner({this.bytes, this.alignX = 0, this.alignY = 0});
  Uint8List? bytes;
  double alignX;
  double alignY;

  bool get hasImage => bytes != null && bytes!.isNotEmpty;
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

