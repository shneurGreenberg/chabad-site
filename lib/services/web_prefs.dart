import 'web_prefs_stub.dart'
    if (dart.library.js_interop) 'web_prefs_html.dart' as impl;

void writePref(String key, String value) => impl.writePref(key, value);

String? readPref(String key) => impl.readPref(key);

void removePref(String key) => impl.removePref(key);

void openUrl(String url) => impl.openUrl(url);
