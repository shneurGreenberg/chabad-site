import 'dart:async';

import 'package:flutter/material.dart';

import '../services/cloud_sync.dart';

/// Very small mock authentication for the admin area.
///
/// Any non-empty credentials are accepted locally. If Firebase is configured,
/// the same email/password is used to sign in so Firestore writes are allowed.
class AuthController extends ChangeNotifier {
  bool _loggedIn = false;
  String _email = '';

  bool get isLoggedIn => _loggedIn;
  String get email => _email;

  bool login(String email, String password) {
    if (email.trim().isEmpty || password.isEmpty) return false;
    _loggedIn = true;
    _email = email.trim();
    notifyListeners();
    unawaited(CloudSync.instance.signIn(_email, password));
    return true;
  }

  void logout() {
    _loggedIn = false;
    _email = '';
    notifyListeners();
    unawaited(CloudSync.instance.signOut());
  }
}
