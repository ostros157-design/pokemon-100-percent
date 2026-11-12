import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Globalny wygląd aplikacji. Kolory tła, tekstu i znaczków są niezależne.
class AppAppearance {
  AppAppearance._();

  static const _backgroundKey = 'appearance_background_dark';
  static const _textKey = 'appearance_text_color';
  static const _badgeKey = 'appearance_badge_color';
  static const _styleKey = 'appearance_visual_style';

  static const visualStyles = <String, String>{
    'modern': 'Nowoczesny',
    'retro': 'Retro Pokémon',
    'pixel': 'Pełny Pixel Art',
  };
  static final ValueNotifier<String> visualStyle = ValueNotifier<String>('modern');

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
    final savedStyle = prefs.getString(_styleKey) ?? 'modern';
    visualStyle.value = visualStyles.containsKey(savedStyle) ? savedStyle : 'modern';
  }

  static ShapeBorder componentShape(
    Color accent, {
    required bool pixel,
    double width = 1,
  }) {
    if (pixel) {
      return PixelShapeBorder(
        side: BorderSide(color: accent, width: width),
        step: 5,
      );
    }
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide.none,
    );
  }

  static Future<void> setVisualStyle(String value) async {
    if (!visualStyles.containsKey(value)) return;
    visualStyle.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_styleKey, value);
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


/// Kanciasta ramka z charakterystycznymi schodkami w stylu pixel art.
class PixelShapeBorder extends ShapeBorder {
  final BorderSide side;
  final double step;

  const PixelShapeBorder({
    this.side = BorderSide.none,
    this.step = 5,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  Path _path(Rect rect) {
    final inset = step.clamp(1.0, rect.shortestSide / 3);
    return Path()
      ..moveTo(rect.left + inset, rect.top)
      ..lineTo(rect.right - inset, rect.top)
      ..lineTo(rect.right - inset, rect.top + inset)
      ..lineTo(rect.right, rect.top + inset)
      ..lineTo(rect.right, rect.bottom - inset)
      ..lineTo(rect.right - inset, rect.bottom - inset)
      ..lineTo(rect.right - inset, rect.bottom)
      ..lineTo(rect.left + inset, rect.bottom)
      ..lineTo(rect.left + inset, rect.bottom - inset)
      ..lineTo(rect.left, rect.bottom - inset)
      ..lineTo(rect.left, rect.top + inset)
      ..lineTo(rect.left + inset, rect.top + inset)
      ..close();
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => _path(rect);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      _path(rect.deflate(side.width));

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none || side.width == 0) return;
    final paint = Paint()
      ..color = side.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = side.width;
    canvas.drawPath(_path(rect.deflate(side.width / 2)), paint);
  }

  @override
  ShapeBorder scale(double t) => PixelShapeBorder(
        side: side.scale(t),
        step: step * t,
      );
}
