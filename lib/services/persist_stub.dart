final Map<String, String> _mem = {};

Future<void> persistPut(String key, String value) async {
  _mem[key] = value;
}

Future<String?> persistGet(String key) async => _mem[key];

Future<void> persistDelete(String key) async {
  _mem.remove(key);
}

Future<List<String>> persistKeys({String prefix = ''}) async {
  return [
    for (final k in _mem.keys)
      if (prefix.isEmpty || k.startsWith(prefix)) k,
  ];
}

bool isQuotaExceeded(Object error) {
  final s = error.toString().toLowerCase();
  return s.contains('quota');
}
