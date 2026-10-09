import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';

SitePalette? paletteFromTenantHex(String? primaryHex, String? accentHex) {
  final p = _parseHex(primaryHex);
  final a = _parseHex(accentHex);
  if (p == null || a == null) return null;
  final onPrimary = p.computeLuminance() > 0.45 ? const Color(0xFF12203A) : Colors.white;
  final onAccent = a.computeLuminance() > 0.55 ? const Color(0xFF12203A) : Colors.white;
  final primaryDark = Color.lerp(p, Colors.black, 0.35)!;
  final primaryMid = Color.lerp(p, Colors.white, 0.12)!;
  final accentSoft = Color.lerp(a, Colors.white, 0.35)!;
  final surface = Color.lerp(p, Colors.white, 0.92)!;
  return SitePalette(
    id: 'tenant-custom',
    name: {
      'he': 'צבעי הקהילה',
      'en': 'Community colors',
      'ru': 'Цвета общины',
    },
    isDark: false,
    primary: p,
    primaryDark: primaryDark,
    primaryMid: primaryMid,
    accent: a,
    accentSoft: accentSoft,
    surface: surface,
    card: Colors.white,
    ink: const Color(0xFF12203A),
    muted: const Color(0xFF5C6578),
    onPrimary: onPrimary,
    onAccent: onAccent,
  );
}

Color? _parseHex(String? raw) {
  if (raw == null) return null;
  var s = raw.trim();
  if (s.isEmpty) return null;
  if (s.startsWith('#')) s = s.substring(1);
  if (s.length == 6) s = 'FF$s';
  final v = int.tryParse(s, radix: 16);
  if (v == null) return null;
  return Color(v);
}
