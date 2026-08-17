import 'package:http/http.dart' as http;

/// Browser-safe GET for APIs that do not send CORS headers (Telegram).
///
/// Tries a few public CORS proxies. Never include secrets in thrown messages.
class CorsProxy {
  static const _timeout = Duration(seconds: 22);

  static Future<http.Response> get(String targetUrl) async {
    final encoded = Uri.encodeComponent(targetUrl);
    final proxies = <String>[
      'https://api.allorigins.win/raw?url=$encoded',
      'https://corsproxy.io/?$encoded',
      'https://api.codetabs.com/v1/proxy?quest=$encoded',
    ];
    Object? lastError;
    for (final proxy in proxies) {
      try {
        final res = await http.get(Uri.parse(proxy)).timeout(_timeout);
        if (res.statusCode >= 200 && res.statusCode < 300 && res.bodyBytes.isNotEmpty) {
          return res;
        }
        lastError = 'HTTP ${res.statusCode}';
      } catch (e) {
        lastError = e;
      }
    }
    throw CorsProxyException(redact('$lastError'));
  }

  /// Direct GET first (works when the API allows CORS), then proxy.
  static Future<http.Response> getDirectOrProxy(String targetUrl) async {
    try {
      final res = await http.get(Uri.parse(targetUrl)).timeout(_timeout);
      if (res.statusCode >= 200 && res.statusCode < 300) return res;
    } catch (_) {}
    return get(targetUrl);
  }

  static String redact(String text) {
    return text
        .replaceAll(RegExp(r'bot\d+:[A-Za-z0-9_-]+'), 'bot[hidden]')
        .replaceAll(RegExp(r'\d{6,}:[A-Za-z0-9_-]{20,}'), '[hidden]');
  }
}

class CorsProxyException implements Exception {
  CorsProxyException(this.message);
  final String message;
  @override
  String toString() => message;
}
