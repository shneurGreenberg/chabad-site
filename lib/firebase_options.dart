import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Web Firebase config via `--dart-define=FIREBASE_*`.
///
/// Create a project at https://console.firebase.google.com then enable
/// Firestore, Storage, and Auth (email/password). Pass the web app config:
///
/// ```
/// flutter build web --dart-define=FIREBASE_API_KEY=... \
///   --dart-define=FIREBASE_APP_ID=... \
///   --dart-define=FIREBASE_MESSAGING_SENDER_ID=... \
///   --dart-define=FIREBASE_PROJECT_ID=... \
///   --dart-define=FIREBASE_STORAGE_BUCKET=... \
///   --dart-define=FIREBASE_AUTH_DOMAIN=...
/// ```
///
/// The web apiKey is a public client key, not a secret service-account JSON.
class DefaultFirebaseOptions {
  static bool get isConfigured {
    const key = String.fromEnvironment('FIREBASE_API_KEY');
    const project = String.fromEnvironment('FIREBASE_PROJECT_ID');
    return key.isNotEmpty && project.isNotEmpty;
  }

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
    apiKey: String.fromEnvironment('FIREBASE_API_KEY'),
    appId: String.fromEnvironment('FIREBASE_APP_ID'),
    messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
    authDomain: String.fromEnvironment('FIREBASE_AUTH_DOMAIN'),
    storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
  );
}
