import 'package:web/web.dart' as web;

void writePref(String key, String value) {
  try {
    web.window.localStorage.setItem(key, value);
  } catch (_) {}
}

String? readPref(String key) => web.window.localStorage.getItem(key);

void removePref(String key) {
  web.window.localStorage.removeItem(key);
}

void openUrl(String url) {
  web.window.open(url, '_blank');
}

void downloadText(String filename, String text) {
  final href =
      'data:application/json;charset=utf-8,${Uri.encodeComponent(text)}';
  final a = web.document.createElement('a') as web.HTMLAnchorElement;
  a.href = href;
  a.setAttribute('download', filename);
  web.document.body?.appendChild(a);
  a.click();
  a.remove();
}
