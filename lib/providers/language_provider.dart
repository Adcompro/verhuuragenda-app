import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _languageKey = 'preferred_language';

class LanguageNotifier extends StateNotifier<Locale?> {
  LanguageNotifier() : super(null) {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageKey);
    if (languageCode != null) {
      state = Locale(languageCode);
    }
  }

  Future<void> setLanguage(String? languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    if (languageCode == null) {
      await prefs.remove(_languageKey);
      state = null; // Use system default
    } else {
      await prefs.setString(_languageKey, languageCode);
      state = Locale(languageCode);
    }
  }

  // Returns true if using system default
  bool get isSystemDefault => state == null;
}

final languageProvider = StateNotifierProvider<LanguageNotifier, Locale?>((ref) {
  return LanguageNotifier();
});
