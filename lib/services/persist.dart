import 'persist_stub.dart'
    if (dart.library.js_interop) 'persist_html.dart' as impl;

class PersistQuotaException implements Exception {
  PersistQuotaException([this.message = 'quota']);
  final String message;
  @override
  String toString() => 'PersistQuotaException: $message';
}

Future<void> persistPut(String key, String value) => impl.persistPut(key, value);

Future<String?> persistGet(String key) => impl.persistGet(key);

Future<void> persistDelete(String key) => impl.persistDelete(key);

bool isQuotaExceeded(Object error) => impl.isQuotaExceeded(error);
