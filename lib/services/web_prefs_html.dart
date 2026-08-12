import 'package:web/web.dart' as web;

void writePref(String key, String value) {
  web.window.localStorage.setItem(key, value);
}

String? readPref(String key) => web.window.localStorage.getItem(key);

void removePref(String key) {
  web.window.localStorage.removeItem(key);
}
