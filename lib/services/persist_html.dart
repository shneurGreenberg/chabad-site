import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'persist.dart';

const _dbName = 'chabad_site';
const _storeName = 'kv';
const _dbVersion = 1;

web.IDBDatabase? _db;

bool isQuotaExceeded(Object error) {
  if (error is PersistQuotaException) return true;
  final s = error.toString().toLowerCase();
  return s.contains('quota') || s.contains('quotaexceeded');
}

Future<void> persistPut(String key, String value) async {
  try {
    await _idbPut(key, value);
    return;
  } catch (e) {
    if (isQuotaExceeded(e)) rethrow;
  }
  _localPut(key, value);
}

Future<String?> persistGet(String key) async {
  try {
    final fromIdb = await _idbGet(key);
    if (fromIdb != null) return fromIdb;
  } catch (_) {}
  return web.window.localStorage.getItem(key);
}

void _localPut(String key, String value) {
  try {
    web.window.localStorage.setItem(key, value);
  } catch (e) {
    if (isQuotaExceeded(e)) {
      throw PersistQuotaException('$e');
    }
    rethrow;
  }
}

Future<web.IDBDatabase> _openDb() async {
  final existing = _db;
  if (existing != null) return existing;
  final done = Completer<web.IDBDatabase>();
  final req = web.window.indexedDB.open(_dbName, _dbVersion);
  req.onupgradeneeded = (web.Event _) {
    final db = req.result as web.IDBDatabase;
    if (!db.objectStoreNames.contains(_storeName)) {
      db.createObjectStore(_storeName);
    }
  }.toJS;
  req.onsuccess = (web.Event _) {
    if (!done.isCompleted) {
      done.complete(req.result as web.IDBDatabase);
    }
  }.toJS;
  req.onerror = (web.Event _) {
    if (!done.isCompleted) {
      done.completeError(req.error ?? Exception('idb open failed'));
    }
  }.toJS;
  final db = await done.future;
  _db = db;
  return db;
}

Future<void> _idbPut(String key, String value) async {
  final db = await _openDb();
  final tx = db.transaction(_storeName.toJS, 'readwrite');
  final store = tx.objectStore(_storeName);
  final req = store.put(value.toJS, key.toJS);
  final done = Completer<void>();
  req.onsuccess = (web.Event _) {
    if (!done.isCompleted) done.complete();
  }.toJS;
  req.onerror = (web.Event _) {
    if (done.isCompleted) return;
    final err = req.error;
    final name = err?.name ?? '';
    if (name.toLowerCase().contains('quota')) {
      done.completeError(PersistQuotaException(name));
    } else {
      done.completeError(err ?? Exception('idb put failed'));
    }
  }.toJS;
  await done.future;
}

Future<String?> _idbGet(String key) async {
  final db = await _openDb();
  final tx = db.transaction(_storeName.toJS, 'readonly');
  final store = tx.objectStore(_storeName);
  final req = store.get(key.toJS);
  final done = Completer<String?>();
  req.onsuccess = (web.Event _) {
    if (done.isCompleted) return;
    final raw = req.result;
    if (raw == null) {
      done.complete(null);
      return;
    }
    final dart = raw.dartify();
    done.complete(dart is String ? dart : dart?.toString());
  }.toJS;
  req.onerror = (web.Event _) {
    if (!done.isCompleted) {
      done.completeError(req.error ?? Exception('idb get failed'));
    }
  }.toJS;
  return done.future;
}
