import 'package:flutter/material.dart';

/// Very small mock authentication for the admin area.
///
/// Any non-empty credentials are accepted — there is no real backend here.
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
    return true;
  }

  void logout() {
    _loggedIn = false;
    _email = '';
    notifyListeners();
  }
}
