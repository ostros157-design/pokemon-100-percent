import 'package:flutter/material.dart';

/// Proste ikony rysowane z kwadratowych pikseli zamiast wygładzonych glifów.
class PixelIcon extends StatelessWidget {
  const PixelIcon({
    super.key,
    required this.name,
    this.color,
    this.size = 24,
  });

  final String name;
  final Color? color;
  final double size;

  static const Map<String, List<String>> _art = {
    'sparkles': [
      '00010000',
      '00010000',
      '00111000',
      '00010000',
      '00000000',
      '00001000',
      '00011100',
      '00001000',
    ],
    'game': [
      '00000000',
      '01111110',
      '11011011',
      '11111111',
      '11100111',
      '01111110',
      '00100100',
      '00000000',
    ],
    'grid': [
      '11011011',
      '11011011',
      '00000000',
      '11011011',
      '11011011',
      '00000000',
      '11011011',
      '11011011',
    ],
    'moon': [
      '00011100',
      '00111000',
      '01110000',
      '01100000',
      '01100000',
      '01110000',
      '00111000',
      '00011100',
    ],
    'sun': [
      '00011000',
      '10011001',
      '01011010',
      '00111100',
      '00111100',
      '01011010',
      '10011001',
      '00011000',
    ],
    'language': [
      '00011000',
      '00100100',
      '00100100',
      '01111110',
      '01000010',
      '11000011',
      '11000011',
      '00000000',
    ],
    'update': [
      '00011000',
      '00111100',
      '01111110',
      '00011000',
      '00011000',
      '00111100',
      '00011000',
      '00011000',
    ],
    'check': [
      '00000000',
      '00000011',
      '00000110',
      '01101100',
      '00111000',
      '00010000',
      '00000000',
      '00000000',
    ],
  };

  @override
  Widget build(BuildContext context) {
    final pixels = _art[name] ?? _art['grid']!;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PixelIconPainter(
          pixels: pixels,
          color: color ?? IconTheme.of(context).color ?? Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _PixelIconPainter extends CustomPainter {
  const _PixelIconPainter({required this.pixels, required this.color});

  final List<String> pixels;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..isAntiAlias = false;
    final cellWidth = size.width / 8;
    final cellHeight = size.height / 8;
    for (var y = 0; y < pixels.length; y++) {
      for (var x = 0; x < pixels[y].length; x++) {
        if (pixels[y][x] != '1') continue;
        canvas.drawRect(
          Rect.fromLTWH(
            x * cellWidth,
            y * cellHeight,
            cellWidth,
            cellHeight,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PixelIconPainter oldDelegate) =>
      oldDelegate.pixels != pixels || oldDelegate.color != color;
}
