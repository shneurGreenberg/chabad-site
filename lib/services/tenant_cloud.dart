import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../firebase_options.dart';
import '../tenant/tenant_paths.dart';
import '../tenant/tenant_seed.dart';
import 'cloud_sync.dart';
import 'image_compress.dart';

/// Sanctioned Firestore writes for tenant onboarding (config + media docs).
class TenantCloudService {
  TenantCloudService._();
  static final TenantCloudService instance = TenantCloudService._();

  static const _maxDataUrlChars = 700000;

  bool get canWrite =>
      DefaultFirebaseOptions.isConfigured && CloudSync.instance.signedIn;

  Future<String?> saveTenantPackage(TenantSeedPackage package) async {
    if (!canWrite) return 'not-signed-in';
    await CloudSync.instance.init();
    try {
      final db = FirebaseFirestore.instance;
      final id = package.id;
      final json = Map<String, dynamic>.from(package.json);
      json['id'] = id;
      json['tenantId'] = id;
      json['updatedAt'] = DateTime.now().toIso8601String();

      await TenantPaths.tenantMetaDoc(db, id).set(json, SetOptions(merge: true));

      final media = db.collection('tenants').doc(id).collection('media');
      for (final e in package.imageFiles.entries) {
        var bytes = e.value;
        var dataUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        if (dataUrl.length > _maxDataUrlChars) {
          bytes = compressSiteImage(bytes);
          dataUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        }
        if (dataUrl.length > 900000) continue;
        final docId = CloudSync.mediaDocId('seed:${e.key}');
        await media.doc(docId).set({
          'dataUrl': dataUrl,
          'mime': 'image/jpeg',
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
      return null;
    } on FirebaseException catch (e) {
      return e.code;
    } catch (_) {
      return 'unknown';
    }
  }

  Future<List<Map<String, dynamic>>> listFirestoreTenants() async {
    if (!DefaultFirebaseOptions.isConfigured) return [];
    await CloudSync.instance.init();
    try {
      final snap = await FirebaseFirestore.instance.collection('tenants').get();
      return [
        for (final d in snap.docs)
          if (d.data().isNotEmpty) {'id': d.id, ...d.data()},
      ];
    } catch (_) {
      return [];
    }
  }
}
