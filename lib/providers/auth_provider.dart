import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  String? _token;
  Map<String, dynamic>? _user;

  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  bool get isLoggedIn => _token != null;

  Future<void> setToken(String token, {Map<String, dynamic>? user}) async {
    final prefs = await SharedPreferences.getInstance();
    _token = token;
    _user = user;
    await prefs.setString('token', token);
    if (user != null) {
      await prefs.setString('user', jsonEncode(user));
    }
    notifyListeners();
  }

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    final userStr = prefs.getString('user');
    if (userStr != null) {
      _user = jsonDecode(userStr) as Map<String, dynamic>;
    }
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    _token = null;
    _user = null;
    await prefs.remove('token');
    await prefs.remove('user');
    notifyListeners();
  }
}
