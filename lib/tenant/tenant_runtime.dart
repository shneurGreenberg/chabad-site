import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';
import 'tenant_blank_config.dart';
import 'nsk_tenant_config.dart';
import 'tenant_config.dart';
import 'tenant_palette.dart';
import 'tenant_paths.dart';
import 'tenant_registry.dart';
import 'tenant_resolver.dart';
import 'tenant_seed.dart';
import '../theme.dart';

export 'tenant_seed.dart' show bundledTenantIds, isBundledTenantId;

/// Tenant bootstrap outcome for the active site.
enum TenantLoadStatus { loading, ready, notFound }

/// Global tenant context initialized before [runApp].
class TenantRuntime extends ChangeNotifier {
  TenantRuntime._();
  static final TenantRuntime instance = TenantRuntime._();

  String tenantId = 'nsk';
  TenantConfig config = nskTenantConfig;
  bool nskMigrated = false;
  bool remoteLoaded = false;
  TenantLoadStatus status = TenantLoadStatus.loading;
  TenantSeedPresentation presentation = const TenantSeedPresentation();
  SitePalette? customPalette;

  TenantPaths get paths => TenantPaths(
        tenantId: tenantId,
        nskMigrated: nskMigrated,
      );

  bool get isNsk => tenantId == 'nsk';
  bool get isReady => status == TenantLoadStatus.ready;
  bool get isNotFound => status == TenantLoadStatus.notFound;

  static Future<void>? _bootFuture;

  /// Fast path: resolve tenant id from URL (sync). Full config via [ensureReady].
  static void bootstrap() {
    final uri = Uri.base;
    final id = resolveTenantIdFromUri(uri);
    instance.tenantId = id;
    if (id == 'nsk') {
      instance.config = nskTenantConfig;
      instance.status = TenantLoadStatus.ready;
      instance.customPalette = null;
    } else {
      instance.config = blankTenantConfig(id);
      instance.status = TenantLoadStatus.loading;
    }
  }

  static Future<void> ensureReady() {
    _bootFuture ??= instance._resolve();
    return _bootFuture!;
  }

  Future<void> _resolve() async {
    if (tenantId == 'nsk') {
      unawaited(_loadRemoteNsk());
      return;
    }
    try {
      Map<String, dynamic>? seedJson;
      TenantSeedPresentation pres = const TenantSeedPresentation();

      if (DefaultFirebaseOptions.isConfigured) {
        seedJson = await _loadFirestoreConfig();
      }
      if (seedJson == null) {
        seedJson = await loadBundledTenantJson(tenantId);
        if (seedJson != null) {
          pres = presentationFromSeed(seedJson, tenantId);
        }
      }
      if (seedJson == null) {
        final local = await TenantRegistry.instance.get(tenantId);
        if (local != null) {
          seedJson = local.json;
          pres = _presentationFromPackage(local);
        }
      }

      if (seedJson == null) {
        status = TenantLoadStatus.notFound;
        remoteLoaded = true;
        notifyListeners();
        return;
      }

      config = tenantConfigFromSeed(seedJson, tenantId: tenantId);
      if (pres.photoAssetPaths.isEmpty) {
        pres = presentationFromSeed(seedJson, tenantId);
      }
      presentation = pres;
      customPalette = paletteFromTenantHex(
        config.primaryColorHex,
        config.accentColorHex,
      );
      status = TenantLoadStatus.ready;
      remoteLoaded = true;
      notifyListeners();
    } catch (_) {
      status = TenantLoadStatus.notFound;
      remoteLoaded = true;
      notifyListeners();
    }
  }

  TenantSeedPresentation _presentationFromPackage(TenantSeedPackage pkg) {
    final photos = <String>[];
    final logo = '${pkg.json['logo'] ?? ''}'.trim();
    if (logo.isNotEmpty && pkg.imageFiles.containsKey(logo)) {
      // Local preview uses memory in repository — asset paths not used.
    }
    for (final f in pkg.json['photos'] is List ? pkg.json['photos'] as List : []) {
      final name = '$f'.trim();
      if (name.isNotEmpty && pkg.imageFiles.containsKey(name)) {
        photos.add('local-seed:$name');
      }
    }
    return TenantSeedPresentation(
      photoAssetPaths: photos,
      sourceCredit: '${pkg.json['sourceCredit'] ?? ''}',
    );
  }

  Future<Map<String, dynamic>?> _loadFirestoreConfig() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      final db = FirebaseFirestore.instance;
      final doc = await TenantPaths.tenantMetaDoc(db, tenantId)
          .get()
          .timeout(const Duration(seconds: 4));
      if (!doc.exists || doc.data() == null) return null;
      final data = doc.data();
      if (data == null) return null;
      return Map<String, dynamic>.from(data);
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadRemoteNsk() async {
    if (!DefaultFirebaseOptions.isConfigured) {
      remoteLoaded = true;
      return;
    }
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      final db = FirebaseFirestore.instance;
      final doc = await TenantPaths.tenantMetaDoc(db, tenantId)
          .get()
          .timeout(const Duration(seconds: 3));
      if (!doc.exists || doc.data() == null) {
        remoteLoaded = true;
        return;
      }
      final data = doc.data()!;
      if (data['migrated'] == true) {
        nskMigrated = true;
      }
      final merged = Map<String, dynamic>.from(data);
      merged.remove('migrated');
      config = TenantConfig.fromMap(merged, fallback: config);
      remoteLoaded = true;
      notifyListeners();
    } catch (_) {
      remoteLoaded = true;
    }
  }
}
