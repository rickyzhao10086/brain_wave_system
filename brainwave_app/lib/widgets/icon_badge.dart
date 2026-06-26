import 'package:flutter/material.dart';

class IconBadge extends StatelessWidget {
  const IconBadge({
    required this.icon,
    required this.colors,
    this.size = 42,
    super.key,
  });

  final IconData icon;
  final List<Color> colors;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: Colors.white, size: size * .52),
    );
  }
}
