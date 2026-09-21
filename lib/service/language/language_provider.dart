import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'app_language_code';

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('ar'),
    Locale('fr'),
  ];

  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  Future<void> loadLocale() async {
    final prefs = await SharedPreferences.getInstance();

    final savedCode = prefs.getString(_languageKey);

    if (savedCode != null &&
        supportedLocales.any(
          (locale) => locale.languageCode == savedCode,
        )) {
      _locale = Locale(savedCode);
    } else {
      _locale = const Locale('en');
    }

    notifyListeners();
  }

  Future<void> changeLocale(String languageCode) async {
    final isSupported = supportedLocales.any(
      (locale) => locale.languageCode == languageCode,
    );

    if (!isSupported) {
      return;
    }

    if (_locale.languageCode == languageCode) {
      return;
    }

    _locale = Locale(languageCode);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);

    notifyListeners();
  }
}