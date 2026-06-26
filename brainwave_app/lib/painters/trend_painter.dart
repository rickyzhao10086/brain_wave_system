import 'package:flutter/material.dart';

class TrendPainter extends CustomPainter {
  const TrendPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: .06)
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final path = Path()
      ..moveTo(0, size.height * .72)
      ..cubicTo(
        size.width * .18,
        size.height * .55,
        size.width * .26,
        size.height * .18,
        size.width * .42,
        size.height * .32,
      )
      ..cubicTo(
        size.width * .58,
        size.height * .48,
        size.width * .66,
        size.height * .76,
        size.width * .82,
        size.height * .60,
      )
      ..cubicTo(
        size.width * .90,
        size.height * .52,
        size.width,
        size.height * .54,
        size.width,
        size.height * .44,
      );

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant TrendPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
