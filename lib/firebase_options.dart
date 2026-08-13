import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Public web Firebase config for project `chabad-site-c60ae`.
///
/// The web apiKey is a client identifier, not a service-account secret.
/// Writes are gated by Firebase Auth (email/password) + security rules.
/// `--dart-define=FIREBASE_*` still overrides these defaults if set.
///
/// Console (one-time): enable Firestore, Storage, and Authentication
/// (Email/Password) at https://console.firebase.google.com/project/chabad-site-c60ae
class DefaultFirebaseOptions {
  static const _apiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: 'AIzaSyCfhL30p5gq9K4S2RfDXsx6PZXzTz_wvUg',
  );
  static const _projectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'chabad-site-c60ae',
  );

  static bool get isConfigured => _apiKey.isNotEmpty && _projectId.isNotEmpty;

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: _apiKey,
    appId: String.fromEnvironment(
      'FIREBASE_APP_ID',
      defaultValue: '1:625650476552:web:a8f8172e2a17ba8a8813bd',
    ),
    messagingSenderId: String.fromEnvironment(
      'FIREBASE_MESSAGING_SENDER_ID',
      defaultValue: '625650476552',
    ),
    projectId: _projectId,
    authDomain: String.fromEnvironment(
      'FIREBASE_AUTH_DOMAIN',
      defaultValue: 'chabad-site-c60ae.firebaseapp.com',
    ),
    storageBucket: String.fromEnvironment(
      'FIREBASE_STORAGE_BUCKET',
      defaultValue: 'chabad-site-c60ae.firebasestorage.app',
    ),
    measurementId: String.fromEnvironment(
      'FIREBASE_MEASUREMENT_ID',
      defaultValue: 'G-87SS9JELY1',
    ),
  );
}
