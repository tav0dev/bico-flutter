import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bicco_provider.dart';

class BiccoTopBar extends StatelessWidget {
  final String title;
  final Widget? leading;
  final Widget? trailing;
  final String? subtitle;
  final bool large;

  const BiccoTopBar({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
    this.subtitle,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<BiccoNotifier>().tokens;
    return Container(
      color: tokens.bg,
      padding: EdgeInsets.symmetric(
        horizontal: large ? 20 : 16,
        vertical: 6,
      ).copyWith(top: large ? 8 : 6, bottom: large ? 4 : 6),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: large ? 24 : 17,
                    fontWeight: large ? FontWeight.w700 : FontWeight.w600,
                    color: tokens.text,
                    letterSpacing: -0.02,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle!,
                    style: TextStyle(fontSize: 13, color: tokens.textMuted),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      ),
    );
  }
}
