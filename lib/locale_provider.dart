import 'package:flutter/material.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('fr');

  Locale get locale => _locale;

  void setLocale(Locale newLocale) {
    if (!L10n.all.contains(newLocale)) return;
    _locale = newLocale;
    notifyListeners();
  }

  void clearLocale() {
    _locale = const Locale('fr');
    notifyListeners();
  }
}

class L10n {
  static const all = [
    Locale('fr'),
    Locale('en'),
    Locale('ar'),
  ];

  static String getLanguageName(String code) {
    switch (code) {
      case 'fr':
        return 'Français';
      case 'en':
        return 'English';
      case 'ar':
        return 'العربية';
      default:
        return 'Unknown';
    }
  }
}
