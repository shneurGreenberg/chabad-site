import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore / Storage path helper with backward-compatible NSK layout.
class TenantPaths {
  TenantPaths({
    required this.tenantId,
    required this.nskMigrated,
  });

  final String tenantId;
  final bool nskMigrated;

  bool get legacyNsk => tenantId == 'nsk' && !nskMigrated;

  CollectionReference<Map<String, dynamic>> collection(
    FirebaseFirestore db,
    String name,
  ) {
    if (legacyNsk) return db.collection(name);
    return db.collection('tenants').doc(tenantId).collection(name);
  }

  /// Published snapshot doc (`site/content` today).
  DocumentReference<Map<String, dynamic>> siteContentDoc(FirebaseFirestore db) {
    if (legacyNsk) {
      return db.collection('site').doc('content');
    }
    return db.collection('tenants').doc(tenantId).collection('site').doc('content');
  }

  /// Storage object prefix (no leading slash).
  String storagePrefix([String sub = '']) {
    final base = legacyNsk ? 'site' : 'tenants/$tenantId';
    if (sub.isEmpty) return base;
    final clean = sub.replaceAll(RegExp(r'^/+'), '');
    return '$base/$clean';
  }

  /// Document path for tenant metadata (`tenants/{id}`).
  static DocumentReference<Map<String, dynamic>> tenantMetaDoc(
    FirebaseFirestore db,
    String tenantId,
  ) {
    return db.collection('tenants').doc(tenantId);
  }
}
