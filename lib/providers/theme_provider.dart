import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// NEW FILE (Phase 6, Part 3 of the fix plan): was referenced by
/// `main.dart`'s `import 'providers/theme_provider.dart'` and
/// `ThemeProvider()` construction, but its class body was never
/// actually generated in the source transcript — this was a real
/// missing-file bug that would have failed to compile.
///
/// `ValueNotifier<ThemeMode>` persisted via SharedPreferences under the
/// 'theme_mode' key: 0 = system, 1 = light, 2 = dark. Matches the
/// pattern already used by `PlantProvider` (ValueNotifier + async load
/// in the constructor, no Provider/Riverpod/Bloc).
class ThemeProvider extends ValueNotifier<ThemeMode> {
  static const _prefsKey = 'theme_mode';

  ThemeProvider() : super(ThemeMode.system) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getInt(_prefsKey);
      if (stored != null) {
        value = _modeFromInt(stored);
      }
    } catch (e) {
      debugPrint('ThemeProvider._load error: $e');
      // Falls back to the ThemeMode.system default set in the
      // constructor above — never leaves the app without a valid theme.
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    value = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefsKey, _intFromMode(mode));
    } catch (e) {
      debugPrint('ThemeProvider.setTheme error: $e');
      // Persistence failed, but `value` is already updated above, so
      // the UI reflects the choice immediately for this session even
      // if it won't survive an app restart.
    }
  }

  ThemeMode _modeFromInt(int i) {
    switch (i) {
      case 1:
        return ThemeMode.light;
      case 2:
        return ThemeMode.dark;
      case 0:
      default:
        return ThemeMode.system;
    }
  }

  int _intFromMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 1;
      case ThemeMode.dark:
        return 2;
      case ThemeMode.system:
        return 0;
    }
  }
}
