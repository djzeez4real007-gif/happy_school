import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global theme controller — light / dark / system.
class ThemeController extends ChangeNotifier {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  static const _key = 'theme_mode';

  ThemeMode _mode = ThemeMode.light;
  ThemeMode get mode => _mode;

  bool get isDark => _mode == ThemeMode.dark;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    switch (value) {
      case 'dark':
        _mode = ThemeMode.dark;
        break;
      case 'system':
        _mode = ThemeMode.system;
        break;
      default:
        _mode = ThemeMode.light;
    }
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final value = switch (mode) {
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
      _ => 'light',
    };
    await prefs.setString(_key, value);
  }

  Future<void> toggleDark() async {
    await setMode(isDark ? ThemeMode.light : ThemeMode.dark);
  }
}
