import 'dart:convert';
import 'dart:typed_data';

import 'web_prefs.dart';

/// Shared with the HTML splash in `web/index.html` so the configured community
/// logo can paint before Flutter finishes booting.
const emblemSplashCacheKey = 'chabad_emblem_cache';

String emblemDataUrl(Uint8List bytes) =>
    'data:image/jpeg;base64,${base64Encode(bytes)}';

Uint8List? decodeEmblemCache(String? stored) {
  if (stored == null || stored.isEmpty) return null;
  final comma = stored.indexOf(',');
  final payload =
      stored.startsWith('data:') && comma >= 0 ? stored.substring(comma + 1) : stored;
  if (payload.isEmpty) return null;
  try {
    return base64Decode(payload);
  } catch (_) {
    return null;
  }
}

void writeEmblemSplashCache(Uint8List bytes) {
  if (bytes.isEmpty) return;
  writePref(emblemSplashCacheKey, emblemDataUrl(bytes));
}

Uint8List? readEmblemSplashCache() => decodeEmblemCache(readPref(emblemSplashCacheKey));

void clearEmblemSplashCache() => removePref(emblemSplashCacheKey);
