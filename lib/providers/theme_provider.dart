import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ValueNotifier<ThemeMode> {
  static const String _prefsKey = 'growlog_theme_mode';
  static const int _system = 0;
  static const int _light = 1;
  static const int _dark = 2;

  ThemeProvider() : super(ThemeMode.system) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getInt(_prefsKey) ?? _system;
      value = _intToMode(cached);
    } catch (e) {
      value = ThemeMode.system;
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefsKey, _modeToInt(mode));
      value = mode;
    } catch (e) {
      debugPrint('ThemeProvider.setTheme error: $e');
    }
  }

  static int _modeToInt(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return _light;
      case ThemeMode.dark:
        return _dark;
      case ThemeMode.system:
      default:
        return _system;
    }
  }

  static ThemeMode _intToMode(int value) {
    switch (value) {
      case _light:
        return ThemeMode.light;
      case _dark:
        return ThemeMode.dark;
      case _system:
      default:
        return ThemeMode.system;
    }
  }
}
