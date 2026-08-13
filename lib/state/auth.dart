import 'dart:async';

import 'package:flutter/material.dart';

import '../services/cloud_sync.dart';

/// Admin authentication.
///
/// When Firebase Auth email/password is enabled, credentials must match a
/// Firebase user. If Auth is not ready yet, any non-empty credentials still
/// unlock the local (IndexedDB) admin. Firestore writes are attempted anyway
/// while test-mode / open rules allow them.
class AuthController extends ChangeNotifier {
  bool _loggedIn = false;
  String _email = '';

  static const _rejectCodes = {
    'invalid-credential',
    'user-not-found',
    'wrong-password',
    'invalid-email',
    'too-many-requests',
    'user-disabled',
  };

  bool get isLoggedIn => _loggedIn;
  String get email => _email;
  bool get cloudEnabled => CloudSync.instance.enabled;
  bool get cloudSignedIn => CloudSync.instance.signedIn;

  Future<String?> login(String email, String password) async {
    if (email.trim().isEmpty || password.isEmpty) return 'empty';
    if (CloudSync.instance.enabled) {
      final err = await CloudSync.instance.signIn(email, password);
      if (err != null && _rejectCodes.contains(err)) return err;
    }
    CloudSync.instance.adminSession = true;
    _loggedIn = true;
    _email = email.trim();
    notifyListeners();
    return null;
  }

  void logout() {
    _loggedIn = false;
    _email = '';
    CloudSync.instance.adminSession = false;
    notifyListeners();
    unawaited(CloudSync.instance.signOut());
  }
}
