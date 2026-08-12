final Map<String, String> _mem = {};

void writePref(String key, String value) => _mem[key] = value;

String? readPref(String key) => _mem[key];

void removePref(String key) => _mem.remove(key);
