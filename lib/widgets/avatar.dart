import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bicco_provider.dart';

class BiccoAvatar extends StatelessWidget {
  final String name;
  final double size;
  final Color? color;

  const BiccoAvatar({super.key, required this.name, this.size = 36, this.color});

  Color _pickColor(BiccoNotifier notifier) {
    final colors = [
      notifier.tokens.green,
      notifier.tokens.purple,
      notifier.tokens.orange,
      const Color(0xFF0EA5E9),
      const Color(0xFFEC4899),
      const Color(0xFF8B5CF6),
    ];
    int h = 0;
    for (final c in name.codeUnits) {
      h = ((h * 31) + c) & 0x7FFFFFFF;
    }
    return colors[h % colors.length];
  }

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<BiccoNotifier>();
    final bg = color ?? _pickColor(notifier);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
      child: Center(
        child: Text(
          _initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.38,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.01,
          ),
        ),
      ),
    );
  }
}
