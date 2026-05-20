import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bicco_provider.dart';

class BiccoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;

  const BiccoCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 14,
  });

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<BiccoNotifier>();
    final tokens = notifier.tokens;

    Color bg;
    Border? border;
    List<BoxShadow> shadows = [];

    switch (notifier.cardStyle) {
      case 'flat':
        bg = tokens.bgSoft;
        border = null;
      case 'outlined':
        bg = tokens.bg;
        border = Border.all(color: tokens.border);
      default: // soft
        bg = tokens.bg;
        border = Border.all(color: tokens.borderSoft);
        if (!notifier.isDark) {
          shadows = [
            BoxShadow(
              color: const Color(0x0A0F172A),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ];
        }
    }

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border,
        boxShadow: shadows,
      ),
      padding: padding ?? const EdgeInsets.all(16),
      child: child,
    );
  }
}
