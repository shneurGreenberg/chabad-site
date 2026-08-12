import 'dart:convert';

import 'cors_proxy.dart';

/// Free MyMemory translation. Fills English and Russian from Hebrew.
class AutoTranslate {
  static Future<Map<String, String>> fromHebrew(String hebrew) async {
    final text = hebrew.trim();
    if (text.isEmpty) {
      throw Exception('empty');
    }
    final results = await Future.wait([
      _one(text, 'he|en'),
      _one(text, 'he|ru'),
    ]);
    return {'en': results[0], 'ru': results[1]};
  }

  static Future<String> _one(String text, String pair) async {
    final uri =
        'https://api.mymemory.translated.net/get?q=${Uri.encodeQueryComponent(text)}&langpair=$pair';
    final res = await CorsProxy.getDirectOrProxy(uri);
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final translated =
        (json['responseData'] as Map?)?['translatedText'] as String?;
    if (translated == null || translated.trim().isEmpty) {
      throw Exception('empty translation');
    }
    return _decodeEntities(translated.trim());
  }

  static String _decodeEntities(String s) {
    return s
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');
  }
}
