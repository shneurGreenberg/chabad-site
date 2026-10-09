import 'dart:convert';

import '../services/persist.dart';
import '../services/web_prefs.dart';
import 'tenant_seed.dart';

const _registryKey = 'chabad_local_tenants';

/// Browser-local tenant packages (preview via `?tenant=`).
class TenantRegistry {
  TenantRegistry._();
  static final TenantRegistry instance = TenantRegistry._();

  Future<Map<String, TenantSeedPackage>> loadAll() async {
    final raw = await persistGet(_registryKey) ?? readPref(_registryKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final m = jsonDecode(raw);
      if (m is! Map) return {};
      final out = <String, TenantSeedPackage>{};
      for (final e in m.entries) {
        final id = '${e.key}'.trim().toLowerCase();
        if (id.isEmpty) continue;
        final v = e.value;
        if (v is! Map) continue;
        out[id] = TenantSeedPackage.fromExportJson(
          Map<String, dynamic>.from(v.cast<String, dynamic>()),
        );
      }
      return out;
    } catch (_) {
      return {};
    }
  }

  Future<void> save(TenantSeedPackage package) async {
    final all = await loadAll();
    all[package.id] = package;
    await _write(all);
  }

  Future<void> remove(String id) async {
    final all = await loadAll();
    all.remove(id);
    await _write(all);
  }

  Future<TenantSeedPackage?> get(String id) async {
    final all = await loadAll();
    return all[id];
  }

  Future<void> _write(Map<String, TenantSeedPackage> all) async {
    final encoded = jsonEncode({
      for (final e in all.entries) e.key: e.value.toExportJson(),
    });
    writePref(_registryKey, encoded);
    await persistPut(_registryKey, encoded);
  }
}
