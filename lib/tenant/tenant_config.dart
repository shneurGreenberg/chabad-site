import '../models.dart';

/// Per-community branding, contacts, integrations, and defaults.
class TenantConfig {
  TenantConfig({
    required this.tenantId,
    required this.communityName,
    required this.cityName,
    required this.tagline,
    required this.aboutSubtitle,
    required this.aboutBody,
    required this.address,
    required this.phone,
    required this.email,
    required this.hours,
    required this.staff,
    required this.social,
    required this.whatsAppDigits,
    required this.defaultAdminEmails,
    required this.defaultPaletteId,
    required this.emblemAssetPath,
    required this.locationQuery,
    required this.latitude,
    required this.longitude,
    required this.timezone,
    required this.kaddishHost,
    required this.kaddishServiceId,
    required this.seoTitle,
    required this.enabledLanguages,
    required this.defaultLanguage,
    required this.telegramChannelHint,
    required this.landlineDigits,
    this.primaryColorHex,
    this.accentColorHex,
    this.sourceCredit = '',
  });

  final String tenantId;
  final Loc communityName;
  final Loc cityName;
  final Loc tagline;
  final Loc aboutSubtitle;
  final Loc aboutBody;
  final Loc address;
  final String phone;
  final String email;
  final List<MapEntry<Loc, Loc>> hours;
  final List<StaffContact> staff;
  final TenantSocialLinks social;
  final String whatsAppDigits;
  final String defaultAdminEmails;
  final String defaultPaletteId;
  final String emblemAssetPath;
  final String locationQuery;
  final double latitude;
  final double longitude;
  final String timezone;
  final String kaddishHost;
  final String kaddishServiceId;
  final String seoTitle;
  final List<String> enabledLanguages;
  final String defaultLanguage;
  final String telegramChannelHint;
  /// Synagogue landline digits (no +) — WhatsApp buttons fall back to secretary.
  final String landlineDigits;
  final String? primaryColorHex;
  final String? accentColorHex;
  final String sourceCredit;

  String get whatsAppUrl => 'https://wa.me/$whatsAppDigits';

  String get kaddishBoardUrl => '$kaddishHost/s/$kaddishServiceId';

  String get kaddishBoardApi => '$kaddishBoardUrl/api/board';

  String get kaddishBoardFullApi => '$kaddishBoardApi?slim=0';

  String get kaddishBoardPersonApi => '$kaddishBoardUrl/api/board/person';

  String get kaddishPhotoBase => '$kaddishHost/photos/';

  SiteLocation toSiteLocation() => SiteLocation(
        cityName: trLoc(cityName, 'he'),
        query: locationQuery,
        latitude: latitude,
        longitude: longitude,
        timezone: timezone,
      );

  SiteCopy toSiteCopy() => SiteCopy(
        name: Map<String, String>.from(communityName),
        city: Map<String, String>.from(cityName),
        tagline: Map<String, String>.from(tagline),
        aboutSubtitle: Map<String, String>.from(aboutSubtitle),
        aboutBody: Map<String, String>.from(aboutBody),
      );

  ContactInfo toContactInfo() => ContactInfo(
        name: Map<String, String>.from(communityName),
        address: Map<String, String>.from(address),
        phone: phone,
        email: email,
        hours: hours,
        staff: staff,
      );

  SiteLinks toSiteLinks() => social.toSiteLinks(
        whatsAppUrl: whatsAppUrl,
        adminEmails: defaultAdminEmails,
      );

  TenantConfig copyWith({
    String? tenantId,
    Loc? communityName,
    bool? migrated,
  }) {
    return TenantConfig(
      tenantId: tenantId ?? this.tenantId,
      communityName: communityName ?? this.communityName,
      cityName: cityName,
      tagline: tagline,
      aboutSubtitle: aboutSubtitle,
      aboutBody: aboutBody,
      address: address,
      phone: phone,
      email: email,
      hours: hours,
      staff: staff,
      social: social,
      whatsAppDigits: whatsAppDigits,
      defaultAdminEmails: defaultAdminEmails,
      defaultPaletteId: defaultPaletteId,
      emblemAssetPath: emblemAssetPath,
      locationQuery: locationQuery,
      latitude: latitude,
      longitude: longitude,
      timezone: timezone,
      kaddishHost: kaddishHost,
      kaddishServiceId: kaddishServiceId,
      seoTitle: seoTitle,
      enabledLanguages: enabledLanguages,
      defaultLanguage: defaultLanguage,
      telegramChannelHint: telegramChannelHint,
      landlineDigits: landlineDigits,
      primaryColorHex: primaryColorHex,
      accentColorHex: accentColorHex,
      sourceCredit: sourceCredit,
    );
  }

  Map<String, dynamic> toMap() => {
        'tenantId': tenantId,
        'communityName': communityName,
        'cityName': cityName,
        'tagline': tagline,
        'aboutSubtitle': aboutSubtitle,
        'aboutBody': aboutBody,
        'address': address,
        'phone': phone,
        'email': email,
        'hours': _hoursToJson(hours),
        'staff': [
          for (final s in staff)
            {
              'name': s.name,
              'role': s.role,
              'phone': s.phone,
            },
        ],
        'social': social.toMap(),
        'whatsAppDigits': whatsAppDigits,
        'defaultAdminEmails': defaultAdminEmails,
        'defaultPaletteId': defaultPaletteId,
        'emblemAssetPath': emblemAssetPath,
        'locationQuery': locationQuery,
        'latitude': latitude,
        'longitude': longitude,
        'timezone': timezone,
        'kaddishHost': kaddishHost,
        'kaddishServiceId': kaddishServiceId,
        'seoTitle': seoTitle,
        'enabledLanguages': enabledLanguages,
        'defaultLanguage': defaultLanguage,
        'telegramChannelHint': telegramChannelHint,
        'landlineDigits': landlineDigits,
        if (primaryColorHex != null) 'primaryColorHex': primaryColorHex,
        if (accentColorHex != null) 'accentColorHex': accentColorHex,
        if (sourceCredit.isNotEmpty) 'sourceCredit': sourceCredit,
      };

  static TenantConfig fromMap(
    Map<String, dynamic> raw, {
    required TenantConfig fallback,
  }) {
    return TenantConfig(
      tenantId: _str(raw['tenantId'], fallback.tenantId),
      communityName: _loc(raw['communityName'], fallback.communityName),
      cityName: _loc(raw['cityName'], fallback.cityName),
      tagline: _loc(raw['tagline'], fallback.tagline),
      aboutSubtitle: _loc(raw['aboutSubtitle'], fallback.aboutSubtitle),
      aboutBody: _loc(raw['aboutBody'], fallback.aboutBody),
      address: _loc(raw['address'], fallback.address),
      phone: _str(raw['phone'], fallback.phone),
      email: _str(raw['email'], fallback.email),
      hours: raw['hours'] != null
          ? _hoursFromJson(raw['hours'])
          : fallback.hours,
      staff: raw['staff'] != null
          ? _staffFromJson(raw['staff'])
          : fallback.staff,
      social: raw['social'] is Map
          ? TenantSocialLinks.fromMap(
              Map<String, dynamic>.from(raw['social'] as Map),
              fallback: fallback.social,
            )
          : fallback.social,
      whatsAppDigits: _str(raw['whatsAppDigits'], fallback.whatsAppDigits),
      defaultAdminEmails:
          _str(raw['defaultAdminEmails'], fallback.defaultAdminEmails),
      defaultPaletteId:
          _str(raw['defaultPaletteId'], fallback.defaultPaletteId),
      emblemAssetPath: _str(raw['emblemAssetPath'], fallback.emblemAssetPath),
      locationQuery: _str(raw['locationQuery'], fallback.locationQuery),
      latitude: _dbl(raw['latitude'], fallback.latitude),
      longitude: _dbl(raw['longitude'], fallback.longitude),
      timezone: _str(raw['timezone'], fallback.timezone),
      kaddishHost: _str(raw['kaddishHost'], fallback.kaddishHost),
      kaddishServiceId:
          _str(raw['kaddishServiceId'], fallback.kaddishServiceId),
      seoTitle: _str(raw['seoTitle'], fallback.seoTitle),
      enabledLanguages: raw['enabledLanguages'] is List
          ? [
              for (final e in raw['enabledLanguages'] as List)
                if ('$e'.trim().isNotEmpty) '$e',
            ]
          : fallback.enabledLanguages,
      defaultLanguage:
          _str(raw['defaultLanguage'], fallback.defaultLanguage),
      telegramChannelHint:
          _str(raw['telegramChannelHint'], fallback.telegramChannelHint),
      landlineDigits: _str(raw['landlineDigits'], fallback.landlineDigits),
      primaryColorHex: raw['primaryColorHex'] != null
          ? _str(raw['primaryColorHex'], '')
          : fallback.primaryColorHex,
      accentColorHex: raw['accentColorHex'] != null
          ? _str(raw['accentColorHex'], '')
          : fallback.accentColorHex,
      sourceCredit: _str(raw['sourceCredit'], fallback.sourceCredit),
    );
  }

  static String _str(dynamic v, String fb) {
    if (v == null) return fb;
    final s = '$v'.trim();
    return s.isEmpty ? fb : s;
  }

  static double _dbl(dynamic v, double fb) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fb;
    return fb;
  }

  static Loc _loc(dynamic v, Loc fb) {
    if (v is! Map) return fb;
    final out = Map<String, String>.from(fb);
    for (final e in v.entries) {
      out['${e.key}'] = '${e.value}';
    }
    return out;
  }

  static List<Map<String, dynamic>> _hoursToJson(List<MapEntry<Loc, Loc>> h) {
    return [
      for (final e in h)
        {
          'day': e.key,
          'hours': e.value,
        },
    ];
  }

  static List<MapEntry<Loc, Loc>> _hoursFromJson(dynamic raw) {
    if (raw is! List) return const [];
    final out = <MapEntry<Loc, Loc>>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final day = item['day'];
      final hours = item['hours'];
      if (day is Map && hours is Map) {
        out.add(MapEntry(
          Map<String, String>.from(day.cast<String, dynamic>()),
          Map<String, String>.from(hours.cast<String, dynamic>()),
        ));
      }
    }
    return out;
  }

  static List<StaffContact> _staffFromJson(dynamic raw) {
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is Map)
          StaffContact(
            name: Map<String, String>.from(
              (item['name'] as Map?)?.cast<String, dynamic>() ?? {},
            ),
            role: Map<String, String>.from(
              (item['role'] as Map?)?.cast<String, dynamic>() ?? {},
            ),
            phone: '${item['phone'] ?? ''}',
          ),
    ];
  }
}

class TenantSocialLinks {
  TenantSocialLinks({
    required this.telegram,
    required this.vk,
    required this.youtube,
    required this.facebook,
    required this.instagram,
    required this.website,
    required this.donateUrl,
    required this.bankDetails,
  });

  final String telegram;
  final String vk;
  final String youtube;
  final String facebook;
  final String instagram;
  final String website;
  final String donateUrl;
  final String bankDetails;

  Map<String, dynamic> toMap() => {
        'telegram': telegram,
        'vk': vk,
        'youtube': youtube,
        'facebook': facebook,
        'instagram': instagram,
        'website': website,
        'donateUrl': donateUrl,
        'bankDetails': bankDetails,
      };

  static TenantSocialLinks fromMap(
    Map<String, dynamic> m, {
    required TenantSocialLinks fallback,
  }) {
    String s(String k) {
      final v = m[k];
      if (v == null) return '';
      return '$v'.trim();
    }
    return TenantSocialLinks(
      telegram: s('telegram').isEmpty ? fallback.telegram : s('telegram'),
      vk: s('vk').isEmpty ? fallback.vk : s('vk'),
      youtube: s('youtube').isEmpty ? fallback.youtube : s('youtube'),
      facebook: s('facebook').isEmpty ? fallback.facebook : s('facebook'),
      instagram: s('instagram').isEmpty ? fallback.instagram : s('instagram'),
      website: s('website').isEmpty ? fallback.website : s('website'),
      donateUrl: s('donateUrl').isEmpty ? fallback.donateUrl : s('donateUrl'),
      bankDetails:
          s('bankDetails').isEmpty ? fallback.bankDetails : s('bankDetails'),
    );
  }

  SiteLinks toSiteLinks({
    required String whatsAppUrl,
    required String adminEmails,
  }) {
    return SiteLinks(
      telegram: telegram,
      vk: vk,
      youtube: youtube,
      facebook: facebook,
      instagram: instagram,
      website: website,
      donateUrl: donateUrl,
      bankDetails: bankDetails,
      whatsapp: whatsAppUrl,
      adminEmails: adminEmails,
    );
  }
}
