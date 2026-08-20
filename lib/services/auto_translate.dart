import 'dart:convert';

import 'cors_proxy.dart';

/// Free MyMemory translation. Fills English and Russian from Hebrew.
class AutoTranslate {
  static const langs = ['he', 'en', 'ru'];

  static Future<Map<String, String>> fromHebrew(String hebrew) =>
      fillEmpty({'he': hebrew, 'en': '', 'ru': ''});

  /// Fills empty locale fields from the first language that has text.
  static Future<Map<String, String>> fillEmpty(Map<String, String> fields) async {
    String? srcLang;
    var srcText = '';
    for (final lang in langs) {
      final t = (fields[lang] ?? '').trim();
      if (t.isNotEmpty) {
        srcLang = lang;
        srcText = t;
        break;
      }
    }
    if (srcLang == null || srcText.isEmpty) {
      throw Exception('empty');
    }
    final out = <String, String>{};
    final jobs = <String, Future<String>>{};
    for (final lang in langs) {
      if (lang == srcLang) continue;
      if ((fields[lang] ?? '').trim().isNotEmpty) continue;
      jobs[lang] = _one(srcText, '$srcLang|$lang');
    }
    final results = await Future.wait(jobs.values);
    var i = 0;
    for (final lang in jobs.keys) {
      out[lang] = results[i++];
    }
    return out;
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
