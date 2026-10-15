import 'package:flutter/material.dart';

class ProfileProvider extends ChangeNotifier {
  String _displayName = '';
  String _identifier = '';
  String _password = '';

  String get displayName => _displayName;
  String get identifier => _identifier;
  String get password => _password;

  void setProfile({
    required String displayName,
    required String identifier,
    required String password,
  }) {
    _displayName = displayName;
    _identifier = identifier;
    _password = password;
    notifyListeners();
  }

  void updateProfile({
    String? displayName,
    String? identifier,
    String? password,
  }) {
    if (displayName != null) _displayName = displayName;
    if (identifier != null) _identifier = identifier;
    if (password != null) _password = password;
    notifyListeners();
  }

  bool verifyCurrentPassword(String currentPassword) {
    return _password == currentPassword;
  }
}