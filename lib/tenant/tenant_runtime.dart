import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';
import 'nsk_tenant_config.dart';
import 'tenant_config.dart';
import 'tenant_paths.dart';
import 'tenant_resolver.dart';

/// Global tenant context initialized before [runApp].
class TenantRuntime extends ChangeNotifier {
  TenantRuntime._();
  static final TenantRuntime instance = TenantRuntime._();

  String tenantId = 'nsk';
  TenantConfig config = nskTenantConfig;
  bool nskMigrated = false;
  bool remoteLoaded = false;

  TenantPaths get paths => TenantPaths(
        tenantId: tenantId,
        nskMigrated: nskMigrated,
      );

  static void bootstrap() {
    final uri = Uri.base;
    final id = resolveTenantIdFromUri(uri);
    instance.tenantId = id;
    instance.config = nskTenantConfig.copyWith(tenantId: id);
    if (id == 'nsk') {
      instance.nskMigrated = false;
    }
    unawaited(instance._loadRemote());
  }

  Future<void> _loadRemote() async {
    if (!DefaultFirebaseOptions.isConfigured) return;
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
      if (tenantId == 'nsk' && data['migrated'] == true) {
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
