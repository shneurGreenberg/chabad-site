import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';
import 'image_compress.dart';

class CloudPull {
  CloudPull({required this.snapshot, required this.images});
  final Map<String, dynamic> snapshot;
  final Map<String, Uint8List> images;
}

/// Firestore-only sync (Spark/free). Images live in `media/{id}`, not Storage.
class CloudSync {
  CloudSync._();
  static final CloudSync instance = CloudSync._();

  static bool _initialized = false;
  static bool _initFailed = false;

  static const _maxDataUrlChars = 700000;

  /// Set while the admin UI is open (local fallback or Firebase Auth).
  bool adminSession = false;

  String? lastError;
  DateTime? lastOkAt;

  bool get enabled => DefaultFirebaseOptions.isConfigured && !_initFailed;
  bool get signedIn =>
      enabled && FirebaseAuth.instance.currentUser != null;

  Future<void> init() async {
    if (!DefaultFirebaseOptions.isConfigured || _initialized) return;
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _initialized = true;
      lastError = null;
    } catch (e) {
      _initFailed = true;
      lastError = 'init:$e';
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

  /// Writes content collections + one `media` doc per image.
  /// Tries even without Auth (Firestore test-mode / open window).
  /// Returns null on success, or an error code.
  Future<String?> push({
    required Map<String, dynamic> snapshot,
    required Map<String, Uint8List> images,
  }) async {
    await init();
    if (!enabled) {
      lastError = 'unavailable';
      return 'unavailable';
    }
    if (!signedIn && !adminSession) {
      lastError = 'not-signed-in';
      return 'not-signed-in';
    }

    try {
      final db = FirebaseFirestore.instance;
      final now = DateTime.now().toIso8601String();
      final mediaIds = [for (final k in images.keys) mediaDocId(k)];

      await db.collection('site').doc('content').set({
        'v': 3,
        'seq': snapshot['seq'],
        'updatedAt': now,
        'mapsKey': snapshot['mapsKey'],
        'location': snapshot['location'],
        'contact': snapshot['contact'],
        'cart': snapshot['cart'],
        'telegramBot': snapshot['telegramBot'],
        'socialBot': snapshot['socialBot'],
        'lang': snapshot['lang'],
        'imageKeys': mediaIds,
      });

      await _syncList(db, 'news', _asMaps(snapshot['news']), images, 'news');
      await _syncList(
        db,
        'programs',
        _asMaps(snapshot['programs']),
        images,
        'program',
      );
      await _syncList(
        db,
        'products',
        _asMaps(snapshot['products']),
        images,
        'product',
      );
      await _syncList(
        db,
        'gallery',
        _asMaps(snapshot['gallery']),
        images,
        'gallery',
      );
      await _syncList(db, 'leads', _asMaps(snapshot['leads']), images, null);
      await _syncList(
        db,
        'donations',
        _asMaps(snapshot['donations']),
        images,
        null,
      );
      await _syncSubscribers(db, _asMaps(snapshot['subscribers']));
      await _syncBanners(db, snapshot['banners'], images);
      await _syncMedia(db, images, now);
      lastError = null;
      lastOkAt = DateTime.now();
      return null;
    } on FirebaseException catch (e) {
      lastError = e.code;
      return e.code;
    } catch (e) {
      lastError = 'unknown';
      return 'unknown';
    }
  }

  Future<CloudPull?> pull() async {
    await init();
    if (!enabled) return null;
    try {
      final db = FirebaseFirestore.instance;
      final content = await db.collection('site').doc('content').get();
      if (!content.exists || content.data() == null) return null;

      final snapshot = Map<String, dynamic>.from(content.data()!);
      final split = snapshot['v'] == 3 || snapshot['news'] is! List;

      if (split) {
        snapshot['news'] = await _loadList(db, 'news');
        snapshot['programs'] = await _loadList(db, 'programs');
        snapshot['products'] = await _loadList(db, 'products');
        snapshot['gallery'] = await _loadList(db, 'gallery');
        snapshot['leads'] = await _loadList(db, 'leads');
        snapshot['donations'] = await _loadList(db, 'donations');
        snapshot['subscribers'] = await _loadList(db, 'subscribers');
        snapshot['banners'] = await _loadBanners(db);
      }

      final images = <String, Uint8List>{};
      final media = await db.collection('media').get();
      for (final d in media.docs) {
        final bytes = decodeMedia(d.data());
        if (bytes != null && bytes.isNotEmpty) {
          images[mediaKey(d.id)] = bytes;
        }
      }
      return CloudPull(snapshot: snapshot, images: images);
    } catch (_) {
      return null;
    }
  }

  static String mediaDocId(String key) => key.replaceAll('/', '__');

  static String mediaKey(String docId) => docId.replaceAll('__', '/');

  static String bannerDocId(String route) {
    if (route == '/') return 'home';
    return route.replaceAll(RegExp(r'^/+'), '').replaceAll('/', '_');
  }

  static String bannerRoute(String docId, Map<String, dynamic> data) {
    final r = data['route'];
    if (r is String && r.isNotEmpty) return r;
    if (docId == 'home') return '/';
    return '/$docId';
  }

  static Uint8List? decodeMedia(Map<String, dynamic> data) {
    final dataUrl = data['dataUrl'];
    if (dataUrl is String && dataUrl.isNotEmpty) {
      final comma = dataUrl.indexOf(',');
      if (dataUrl.startsWith('data:') && comma > 0) {
        return _b64(dataUrl.substring(comma + 1));
      }
      return _b64(dataUrl);
    }
    final raw = data['base64'] ?? data['bytes'];
    if (raw is String) return _b64(raw);
    return null;
  }

  static Uint8List? _b64(String value) {
    if (value.isEmpty) return null;
    try {
      return base64Decode(value);
    } catch (_) {
      return null;
    }
  }

  static List<Map<String, dynamic>> _asMaps(dynamic raw) {
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is Map) Map<String, dynamic>.from(item),
    ];
  }

  Future<List<Map<String, dynamic>>> _loadList(
    FirebaseFirestore db,
    String name,
  ) async {
    final snap = await db.collection(name).get();
    return [for (final d in snap.docs) {'id': d.id, ...d.data()}];
  }

  Future<Map<String, dynamic>> _loadBanners(FirebaseFirestore db) async {
    final snap = await db.collection('banners').get();
    return {
      for (final d in snap.docs) bannerRoute(d.id, d.data()): d.data(),
    };
  }

  Future<void> _syncList(
    FirebaseFirestore db,
    String name,
    List<Map<String, dynamic>> items,
    Map<String, Uint8List> images,
    String? imageKind,
  ) async {
    final col = db.collection(name);
    final existing = await col.get();
    final keep = <String>{};
    for (final item in items) {
      final id = '${item['id'] ?? ''}';
      if (id.isEmpty) continue;
      keep.add(id);
      final doc = Map<String, dynamic>.from(item)
        ..remove('image')
        ..remove('imageUrl');
      if (imageKind != null) {
        final key = '$imageKind:$id';
        doc['imageId'] = images.containsKey(key) ? mediaDocId(key) : null;
      }
      await col.doc(id).set(doc);
    }
    for (final d in existing.docs) {
      if (!keep.contains(d.id)) await d.reference.delete();
    }
  }

  Future<void> _syncSubscribers(
    FirebaseFirestore db,
    List<Map<String, dynamic>> items,
  ) async {
    final col = db.collection('subscribers');
    final existing = await col.get();
    final keep = <String>{};
    for (final item in items) {
      final email = '${item['email'] ?? ''}'.trim().toLowerCase();
      if (email.isEmpty) continue;
      final id = email.replaceAll('/', '_');
      keep.add(id);
      await col.doc(id).set(item);
    }
    for (final d in existing.docs) {
      if (!keep.contains(d.id)) await d.reference.delete();
    }
  }

  Future<void> _syncBanners(
    FirebaseFirestore db,
    dynamic raw,
    Map<String, Uint8List> images,
  ) async {
    final col = db.collection('banners');
    final existing = await col.get();
    final keep = <String>{};
    if (raw is Map) {
      for (final e in raw.entries) {
        final route = '${e.key}';
        final id = bannerDocId(route);
        keep.add(id);
        final data = e.value is Map
            ? Map<String, dynamic>.from(e.value as Map)
            : <String, dynamic>{};
        final key = 'banner:$route';
        data
          ..remove('image')
          ..['route'] = route
          ..['imageId'] = images.containsKey(key) ? mediaDocId(key) : null;
        await col.doc(id).set(data);
      }
    }
    for (final d in existing.docs) {
      if (!keep.contains(d.id)) await d.reference.delete();
    }
  }

  Future<void> _syncMedia(
    FirebaseFirestore db,
    Map<String, Uint8List> images,
    String now,
  ) async {
    final col = db.collection('media');
    final existing = await col.get();
    final keep = <String>{};
    for (final e in images.entries) {
      if (e.value.isEmpty) continue;
      var bytes = e.value;
      var dataUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      if (dataUrl.length > _maxDataUrlChars) {
        bytes = compressSiteImage(bytes);
        dataUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      }
      if (dataUrl.length > 900000) continue;
      final id = mediaDocId(e.key);
      keep.add(id);
      await col.doc(id).set({
        'dataUrl': dataUrl,
        'mime': 'image/jpeg',
        'updatedAt': now,
      });
    }
    for (final d in existing.docs) {
      if (!keep.contains(d.id)) await d.reference.delete();
    }
  }
}
