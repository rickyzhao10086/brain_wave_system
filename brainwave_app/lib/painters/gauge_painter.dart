import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Draws a circular confidence gauge: a faint full-circle track with a
/// coloured arc sweeping clockwise from the top to represent [value] (0..1).
class GaugePainter extends CustomPainter {
  const GaugePainter({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 7;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const start = -math.pi / 2;

    final track = Paint()
      ..color = Colors.white.withValues(alpha: .08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);

    final arc = Paint()
      ..shader = SweepGradient(
        startAngle: start,
        endAngle: start + 2 * math.pi,
        colors: [color.withValues(alpha: .35), color],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, start, 2 * math.pi * value.clamp(0, 1), false, arc);
  }

  @override
  bool shouldRepaint(covariant GaugePainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.color != color;
}
