import 'dart:async';

import 'package:flutter/material.dart';

import '../models.dart';
import '../services/cloud_sync.dart';
import '../services/persist.dart';
import '../services/web_prefs.dart';

/// Admin authentication.
///
/// Firebase Auth is required for cloud writes after Firestore rules lock.
/// A local editor PIN unlocks content panels without Telegram / settings.
class AuthController extends ChangeNotifier {
  bool _loggedIn = false;
  String _email = '';
  AdminRole _role = AdminRole.admin;

  static const editorPinKey = 'chabad_editor_pin';
  static const editorEmailsKey = 'chabad_editor_emails';

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
  AdminRole get role => _role;
  bool get isAdmin => _loggedIn && _role == AdminRole.admin;
  bool get isEditor => _loggedIn && _role == AdminRole.editor;
  bool get cloudEnabled => CloudSync.instance.enabled;
  bool get cloudSignedIn => CloudSync.instance.signedIn;

  static String editorPin() => (readPref(editorPinKey) ?? '').trim();

  static Future<void> saveEditorPin(String pin) async {
    writePref(editorPinKey, pin.trim());
    try {
      await persistPut(editorPinKey, pin.trim());
    } catch (_) {}
  }

  bool _isAdminEmail(String email, String adminEmails) {
    final allow = adminEmails
        .split(RegExp(r'[,;\s]+'))
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.contains('@'))
        .toSet();
    if (allow.isEmpty) return true;
    return allow.contains(email);
  }

  Future<String?> login(
    String email,
    String password, {
    String adminEmails = 'admin@chabad-city.org',
  }) async {
    if (email.trim().isEmpty || password.isEmpty) return 'empty';
    final trimmed = email.trim().toLowerCase();
    final pin = editorPin();
    final editorMail = trimmed.contains('editor@') ||
        trimmed == 'editor@chabad-city.org';
    if (pin.isNotEmpty && password == pin && editorMail) {
      _role = AdminRole.editor;
      _loggedIn = true;
      _email = trimmed;
      CloudSync.instance.adminSession = false;
      notifyListeners();
      return null;
    }

    if (CloudSync.instance.enabled) {
      final err = await CloudSync.instance.signIn(email, password);
      if (err != null && _rejectCodes.contains(err)) return err;
      if (err == null) {
        _role = _isAdminEmail(trimmed, adminEmails)
            ? AdminRole.admin
            : AdminRole.editor;
        CloudSync.instance.adminSession = true;
        _loggedIn = true;
        _email = trimmed;
        notifyListeners();
        return null;
      }
    }
    CloudSync.instance.adminSession = true;
    _role = AdminRole.admin;
    _loggedIn = true;
    _email = trimmed;
    notifyListeners();
    return null;
  }

  void logout() {
    _loggedIn = false;
    _email = '';
    _role = AdminRole.admin;
    CloudSync.instance.adminSession = false;
    notifyListeners();
    unawaited(CloudSync.instance.signOut());
  }
}
