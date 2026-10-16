import 'dart:math';

import 'package:flutter/material.dart';

import '../../../utils/theme.dart';

/// Approximates `.bg-linen` (an SVG fractalNoise overlay) and the parchment
/// grid texture from the library body. Paints a very faint speckle + cross
/// hatch over a parchment fill so backgrounds read as woven paper, not flat.
class LinenOverlay extends StatelessWidget {
  const LinenOverlay({
    super.key,
    required this.child,
    this.baseColor = AppColors.surface,
  });

  final Widget child;
  final Color baseColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: baseColor),
      child: CustomPaint(
        painter: _LinenPainter(),
        child: child,
      ),
    );
  }
}

class _LinenPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dot = Paint()..color = AppColors.onSurface.withValues(alpha: 0.02);
    final density = (size.width * size.height / 900).clamp(0, 4000).toInt();
    final r = Random(42); // reseed each paint for identical pattern
    for (var i = 0; i < density; i++) {
      final dx = r.nextDouble() * size.width;
      final dy = r.nextDouble() * size.height;
      canvas.drawCircle(Offset(dx, dy), 0.5, dot);
    }

    // Faint 8px grid like `.card-texture` / body background.
    final grid = Paint()
      ..color = AppColors.onSurface.withValues(alpha: 0.015)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 8) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += 8) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
  }

  @override
  bool shouldRepaint(covariant _LinenPainter oldDelegate) => false;
}
