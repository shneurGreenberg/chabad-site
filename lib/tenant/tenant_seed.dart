import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';

import '../models.dart';
import 'tenant_blank_config.dart';
import 'tenant_config.dart';

/// Bundled tenant ids shipped under [assets/tenants/<id>/].
const List<String> bundledTenantIds = ['tomsk'];

String bundledTenantJsonAsset(String id) => 'assets/tenants/$id/tenant.json';

String bundledTenantImageAsset(String id, String fileName) =>
    'assets/tenants/$id/$fileName';

bool isBundledTenantId(String id) => bundledTenantIds.contains(id);

/// On-disk / downloadable tenant package (`tenant.json` + images).
class TenantSeedPackage {
  TenantSeedPackage({
    required this.id,
    required this.json,
    this.imageFiles = const {},
  });

  final String id;
  final Map<String, dynamic> json;
  /// Filename → raw bytes (logo, photos).
  final Map<String, Uint8List> imageFiles;

  Map<String, dynamic> toExportJson() {
    final out = Map<String, dynamic>.from(json);
    out['id'] = id;
    if (imageFiles.isNotEmpty) {
      out['imagesBase64'] = {
        for (final e in imageFiles.entries)
          e.key: base64Encode(e.value),
      };
    }
    return out;
  }

  static TenantSeedPackage fromExportJson(Map<String, dynamic> raw) {
    final id = '${raw['id'] ?? ''}'.trim().toLowerCase();
    final images = <String, Uint8List>{};
    final b64 = raw['imagesBase64'];
    if (b64 is Map) {
      for (final e in b64.entries) {
        final bytes = base64Decode('${e.value}');
        images['${e.key}'] = bytes;
      }
    }
    final copy = Map<String, dynamic>.from(raw);
    copy.remove('imagesBase64');
    return TenantSeedPackage(id: id, json: copy, imageFiles: images);
  }
}

class TenantSeedPresentation {
  const TenantSeedPresentation({
    this.photoAssetPaths = const [],
    this.sourceCredit = '',
  });

  final List<String> photoAssetPaths;
  final String sourceCredit;
}

/// Load bundled `tenant.json` for [id]. Returns null if missing.
Future<Map<String, dynamic>?> loadBundledTenantJson(String id) async {
  if (!isBundledTenantId(id)) return null;
  try {
    final raw =
        await rootBundle.loadString(bundledTenantJsonAsset(id));
    final m = jsonDecode(raw);
    if (m is! Map) return null;
    return Map<String, dynamic>.from(m.cast<String, dynamic>());
  } catch (_) {
    return null;
  }
}

TenantConfig tenantConfigFromSeed(
  Map<String, dynamic> seed, {
  required String tenantId,
}) {
  final blank = blankTenantConfig(tenantId);
  final id = _str(seed['id'], tenantId);
  final name = _loc(seed['name'], blank.communityName);
  final city = _loc(seed['city'], blank.cityName);
  final about = _loc(seed['about'], blank.aboutBody);
  final address = _loc(seed['address'], blank.address);
  final langs = seed['languages'];
  final enabled = langs is List
      ? [
          for (final e in langs)
            if ('$e'.trim().isNotEmpty) '$e',
        ]
      : blank.enabledLanguages;
  final colors = seed['colors'];
  String? primary;
  String? accent;
  if (colors is Map) {
    primary = _str(colors['primary'], '');
    accent = _str(colors['accent'], '');
    if (primary.isEmpty) primary = null;
    if (accent.isEmpty) accent = null;
  }
  final logoFile = _str(seed['logo'], '');
  final emblem = logoFile.isNotEmpty
      ? bundledTenantImageAsset(id, logoFile)
      : blank.emblemAssetPath;
  final adminEmail = _str(seed['adminEmail'], blank.defaultAdminEmails);
  final seo = trLoc(name, 'en');
  final title = seo.isNotEmpty ? '$seo | Chabad' : blank.seoTitle;

  return TenantConfig(
    tenantId: id,
    communityName: name,
    cityName: city,
    tagline: _loc(seed['tagline'], {
      'he': trLoc(name, 'he'),
      'en': trLoc(name, 'en'),
      'ru': trLoc(name, 'ru'),
    }),
    aboutSubtitle: _loc(seed['aboutSubtitle'], address),
    aboutBody: about,
    address: address,
    phone: _str(seed['phone'], blank.phone),
    email: _str(seed['email'], blank.email),
    hours: blank.hours,
    staff: blank.staff,
    social: blank.social,
    whatsAppDigits: _digits(seed['whatsApp'] ?? seed['phone']),
    defaultAdminEmails: adminEmail,
    defaultPaletteId: 'classic',
    emblemAssetPath: emblem,
    locationQuery: trLoc(address, 'en'),
    latitude: _dbl(seed['latitude'], 0),
    longitude: _dbl(seed['longitude'], 0),
    timezone: _str(seed['timezone'], blank.timezone),
    kaddishHost: blank.kaddishHost,
    kaddishServiceId: blank.kaddishServiceId,
    seoTitle: title,
    enabledLanguages: enabled.isEmpty ? blank.enabledLanguages : enabled,
    defaultLanguage: enabled.isNotEmpty ? enabled.first : blank.defaultLanguage,
    telegramChannelHint: blank.telegramChannelHint,
    landlineDigits: _digits(seed['phone']),
    primaryColorHex: primary,
    accentColorHex: accent,
    sourceCredit: _str(seed['sourceCredit'], ''),
  );
}

TenantSeedPresentation presentationFromSeed(
  Map<String, dynamic> seed,
  String tenantId,
) {
  final id = _str(seed['id'], tenantId);
  final photos = <String>[];
  final rawPhotos = seed['photos'];
  if (rawPhotos is List) {
    for (final p in rawPhotos) {
      final f = '$p'.trim();
      if (f.isEmpty) continue;
      photos.add(bundledTenantImageAsset(id, f));
    }
  }
  final logo = _str(seed['logo'], '');
  if (logo.isNotEmpty) {
    final path = bundledTenantImageAsset(id, logo);
    if (!photos.contains(path)) photos.insert(0, path);
  }
  return TenantSeedPresentation(
    photoAssetPaths: photos,
    sourceCredit: _str(seed['sourceCredit'], ''),
  );
}

TenantSeedPackage packageFromSeedJson(Map<String, dynamic> seed) {
  final id = _str(seed['id'], '');
  return TenantSeedPackage(id: id, json: Map<String, dynamic>.from(seed));
}

String _str(dynamic v, String fb) {
  if (v == null) return fb;
  final s = '$v'.trim();
  return s.isEmpty ? fb : s;
}

double _dbl(dynamic v, double fb) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? fb;
  return fb;
}

Loc _loc(dynamic v, Loc fb) {
  if (v is! Map) return fb;
  final out = Map<String, String>.from(fb);
  for (final e in v.entries) {
    out['${e.key}'] = '${e.value}';
  }
  return out;
}

String _digits(dynamic v) {
  final s = '$v';
  return s.replaceAll(RegExp(r'\D'), '');
}
