import 'dart:math' as math;

import 'package:flutter/material.dart';

class BrainMapPainter extends CustomPainter {
  const BrainMapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * .36;
    final outline = Paint()
      ..color = Colors.white.withValues(alpha: .16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: radius * 1.45,
        height: radius * 1.9,
      ),
      outline,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      outline,
    );

    final nodes = [
      (Offset(-.35, -.35), const Color(0xffff4d6d), 13.0),
      (Offset(.0, -.2), const Color(0xff8b5cf6), 10.0),
      (Offset(.36, -.33), const Color(0xff60a5fa), 8.0),
      (Offset(-.22, .12), const Color(0xfff59e0b), 8.0),
      (Offset(.25, .15), const Color(0xff22d3ee), 9.0),
    ];

    for (final node in nodes) {
      final p = Offset(
        center.dx + node.$1.dx * radius,
        center.dy + node.$1.dy * radius,
      );
      canvas.drawCircle(
        p,
        node.$3 + 5,
        Paint()..color = node.$2.withValues(alpha: .16),
      );
      canvas.drawCircle(p, node.$3, Paint()..color = node.$2);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
