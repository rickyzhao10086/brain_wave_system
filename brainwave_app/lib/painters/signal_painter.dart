import 'dart:math' as math;

import 'package:flutter/material.dart';

class SignalPainter extends CustomPainter {
  const SignalPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: .06)
      ..strokeWidth = 1;

    for (var i = 1; i < 5; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final colors = [
      const Color(0xff22d3ee),
      const Color(0xffd946ef),
      const Color(0xff60a5fa),
      const Color(0xff8b5cf6),
    ];

    for (var row = 0; row < colors.length; row++) {
      final path = Path();
      final base = size.height * (.16 + row * .22);

      for (var x = 0.0; x <= size.width; x += 3) {
        final y = base +
            math.sin(x / (6 + row * 2)) * (5 + row) +
            math.sin(x / 15) * 2;
        if (x == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      canvas.drawPath(
        path,
        Paint()
          ..color = colors[row]
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
