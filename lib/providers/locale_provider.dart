import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App language override. `null` means "follow the phone's language".
/// Persisted under 'locale_code' in SharedPreferences.
class LocaleProvider extends ValueNotifier<Locale?> {
  static const _prefsKey = 'locale_code';

  LocaleProvider() : super(null) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_prefsKey);
      if (code != null && code.isNotEmpty) value = Locale(code);
    } catch (e) {
      debugPrint('LocaleProvider._load error: $e');
    }
  }

  Future<void> setLocale(Locale? locale) async {
    value = locale;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (locale == null) {
        await prefs.remove(_prefsKey);
      } else {
        await prefs.setString(_prefsKey, locale.languageCode);
      }
    } catch (e) {
      debugPrint('LocaleProvider.setLocale error: $e');
    }
  }
}
