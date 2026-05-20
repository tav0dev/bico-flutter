import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bicco_provider.dart';

class BiccoPill extends StatelessWidget {
  final String text;
  final String color;
  final bool soft;
  final String size;

  const BiccoPill({
    super.key,
    required this.text,
    this.color = 'green',
    this.soft = true,
    this.size = 'md',
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<BiccoNotifier>().tokens;

    Color fg, bg;
    switch (color) {
      case 'purple':
        fg = tokens.purple;
        bg = tokens.purpleSoft;
      case 'orange':
        fg = tokens.orange;
        bg = tokens.orangeSoft;
      case 'red':
        fg = tokens.red;
        bg = tokens.redSoft;
      case 'gray':
        fg = tokens.textMuted;
        bg = tokens.borderSoft;
      default: // green
        fg = tokens.green;
        bg = tokens.greenSoft;
    }

    final isSmall = size == 'sm';
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 7 : 9,
        vertical: isSmall ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: soft ? bg : fg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: soft ? fg : Colors.white,
          fontSize: isSmall ? 11 : 12,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.005,
        ),
      ),
    );
  }
}
