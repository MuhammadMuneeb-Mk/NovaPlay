import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const _storageKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.system;

  ThemeProvider() {
    _load();
  }

  ThemeMode get themeMode => _themeMode;

  void setTheme(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners();
      SharedPreferences.getInstance().then(
        (prefs) => prefs.setString(_storageKey, mode.name),
      );
    }
  }

  // remember the chosen theme between visits
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_storageKey);
    final mode = ThemeMode.values.where((m) => m.name == saved).firstOrNull;
    if (mode != null && mode != _themeMode) {
      _themeMode = mode;
      notifyListeners();
    }
  }
}
