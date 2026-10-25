import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Globalny wygląd aplikacji. Kolory tła, tekstu i znaczków są niezależne.
class AppAppearance {
  AppAppearance._();

  static const _backgroundKey = 'appearance_background_dark';
  static const _textKey = 'appearance_text_color';
  static const _badgeKey = 'appearance_badge_color';

  static final ValueNotifier<bool> darkBackground = ValueNotifier<bool>(false);
  static final ValueNotifier<Color> textColor = ValueNotifier<Color>(const Color(0xFF202124));
  static final ValueNotifier<Color> badgeColor = ValueNotifier<Color>(const Color(0xFF2E7D32));

  static const colorOptions = <String, Color>{
    'Czarny': Color(0xFF202124),
    'Biały': Color(0xFFFFFFFF),
    'Czerwony': Color(0xFFD32F2F),
    'Pomarańczowy': Color(0xFFEF6C00),
    'Żółty': Color(0xFFF9A825),
    'Zielony': Color(0xFF2E7D32),
    'Niebieski': Color(0xFF1565C0),
    'Fioletowy': Color(0xFF7B1FA2),
    'Różowy': Color(0xFFC2185B),
  };

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    darkBackground.value = prefs.getBool(_backgroundKey) ?? false;
    textColor.value = Color(prefs.getInt(_textKey) ?? const Color(0xFF202124).value);
    badgeColor.value = Color(prefs.getInt(_badgeKey) ?? const Color(0xFF2E7D32).value);
  }

  static Future<void> setDarkBackground(bool value) async {
    darkBackground.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_backgroundKey, value);
  }

  static Future<void> setTextColor(Color value) async {
    textColor.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_textKey, value.value);
  }

  static Future<void> setBadgeColor(Color value) async {
    badgeColor.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_badgeKey, value.value);
  }
}
