import 'package:flutter/material.dart';

/// Delikatne, globalne tło z pikselową siatką i dekoracyjnymi kafelkami.
class PixelBackdrop extends StatelessWidget {
  const PixelBackdrop({
    super.key,
    required this.child,
    required this.accentColor,
    required this.backgroundColor,
  });

  final Widget child;
  final Color accentColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: backgroundColor,
      child: CustomPaint(
        painter: _PixelBackdropPainter(accentColor: accentColor),
        child: child,
      ),
    );
  }
}

class _PixelBackdropPainter extends CustomPainter {
  const _PixelBackdropPainter({required this.accentColor});

  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = accentColor.withOpacity(0.055)
      ..strokeWidth = 1
      ..isAntiAlias = false;
    const cell = 24.0;
    for (var x = 0.0; x <= size.width; x += cell) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var y = 0.0; y <= size.height; y += cell) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final blockPaint = Paint()
      ..color = accentColor.withOpacity(0.10)
      ..isAntiAlias = false;
    final softPaint = Paint()
      ..color = accentColor.withOpacity(0.045)
      ..isAntiAlias = false;
    const block = 8.0;
    for (var row = 0; row < 4; row++) {
      for (var column = 0; column < 4; column++) {
        if ((row + column) % 2 != 0) continue;
        canvas.drawRect(
          Rect.fromLTWH(
            size.width - 18 - (column * block),
            18 + (row * block),
            block - 1,
            block - 1,
          ),
          row == 0 || column == 0 ? blockPaint : softPaint,
        );
        if (row < 3 && column < 3) {
          canvas.drawRect(
            Rect.fromLTWH(
              18 + (column * block),
              size.height - 18 - (row * block),
              block - 1,
              block - 1,
            ),
            softPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PixelBackdropPainter oldDelegate) =>
      oldDelegate.accentColor != accentColor;
}
