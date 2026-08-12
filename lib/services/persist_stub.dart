final Map<String, String> _mem = {};

Future<void> persistPut(String key, String value) async {
  _mem[key] = value;
}

Future<String?> persistGet(String key) async => _mem[key];

bool isQuotaExceeded(Object error) {
  final s = error.toString().toLowerCase();
  return s.contains('quota');
}
