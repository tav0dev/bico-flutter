import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bico_provider.dart';

enum BtnVariant { primary, secondary, ghost, ai, danger }

enum BtnSize { sm, md, lg }

class BicoButton extends StatelessWidget {
  final Widget child;
  final BtnVariant variant;
  final BtnSize size;
  final bool full;
  final VoidCallback? onPressed;

  const BicoButton({
    super.key,
    required this.child,
    this.variant = BtnVariant.primary,
    this.size = BtnSize.md,
    this.full = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<BicoNotifier>().tokens;

    Color bg, fg;
    Color borderColor;
    switch (variant) {
      case BtnVariant.primary:
        bg = tokens.green;
        fg = Colors.white;
        borderColor = Colors.transparent;
      case BtnVariant.secondary:
        bg = tokens.bg;
        fg = tokens.text;
        borderColor = tokens.border;
      case BtnVariant.ghost:
        bg = Colors.transparent;
        fg = tokens.text;
        borderColor = Colors.transparent;
      case BtnVariant.ai:
        bg = tokens.orange;
        fg = Colors.white;
        borderColor = Colors.transparent;
      case BtnVariant.danger:
        bg = tokens.bg;
        fg = tokens.red;
        borderColor = tokens.border;
    }

    double height, fontSize;
    EdgeInsets padding;
    switch (size) {
      case BtnSize.sm:
        height = 32;
        fontSize = 13;
        padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
      case BtnSize.md:
        height = 44;
        fontSize = 15;
        padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10);
      case BtnSize.lg:
        height = 52;
        fontSize = 16;
        padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14);
    }

    final btn = Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: DefaultTextStyle(
            style: TextStyle(
              color: fg,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.01,
            ),
            child: IconTheme(
              data: IconThemeData(color: fg, size: size == BtnSize.sm ? 16 : 18),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [child],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (full) {
      return SizedBox(width: double.infinity, child: btn);
    }
    return btn;
  }
}
