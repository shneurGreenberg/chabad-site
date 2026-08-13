import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../firebase_options.dart';

/// Firestore + Storage sync. No-ops until Firebase initializes.
class CloudSync {
  CloudSync._();
  static final CloudSync instance = CloudSync._();

  static bool _initialized = false;
  static bool _initFailed = false;

  bool get enabled => DefaultFirebaseOptions.isConfigured && !_initFailed;
  bool get signedIn =>
      enabled && FirebaseAuth.instance.currentUser != null;

  Future<void> init() async {
    if (!DefaultFirebaseOptions.isConfigured || _initialized) return;
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      _initialized = true;
    } catch (_) {
      _initFailed = true;
    }
  }

  /// Returns null on success, or a short error code (`invalid-credential`, …).
  Future<String?> signIn(String email, String password) async {
    await init();
    if (!enabled) return 'unavailable';
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return e.code;
    } catch (_) {
      return 'unknown';
    }
  }

  Future<void> signOut() async {
    if (!enabled) return;
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
  }

  Future<void> push({
    required Map<String, dynamic> snapshot,
    required Map<String, Uint8List> images,
  }) async {
    await init();
    if (!signedIn) return;
    final urls = <String, String>{};
    final storage = FirebaseStorage.instance;
    for (final e in images.entries) {
      try {
        final ref = storage.ref('site/${e.key}.jpg');
        await ref.putData(
          e.value,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        urls[e.key] = await ref.getDownloadURL();
      } catch (_) {}
    }
    final payload = Map<String, dynamic>.from(snapshot)
      ..['imageUrls'] = urls
      ..['updatedAt'] = DateTime.now().toIso8601String();
    await FirebaseFirestore.instance
        .collection('site')
        .doc('content')
        .set(payload, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> pull() async {
    await init();
    if (!enabled) return null;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('site')
          .doc('content')
          .get();
      return snap.data();
    } catch (_) {
      return null;
    }
  }
}
