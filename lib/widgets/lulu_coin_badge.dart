import 'package:flutter/material.dart';

class LuluCoinBadge extends StatelessWidget {
  const LuluCoinBadge({super.key, this.size = 38});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white70, width: 1.4),
      ),
      alignment: Alignment.center,
      child: Text(
        '🐃',
        style: TextStyle(fontSize: size * 0.5),
      ),
    );
  }
}
