import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bicco_provider.dart';

enum NavTab { home, agenda, inbox, clients }

class BiccoBottomNav extends StatelessWidget {
  final NavTab active;
  final ValueChanged<NavTab>? onTap;

  const BiccoBottomNav({super.key, required this.active, this.onTap});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<BiccoNotifier>();
    final tokens = notifier.tokens;

    const items = [
      (id: NavTab.home, label: 'Início', icon: Icons.home_outlined, activeIcon: Icons.home),
      (id: NavTab.agenda, label: 'Agenda', icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today),
      (id: NavTab.inbox, label: 'Inbox', icon: Icons.chat_bubble_outline, activeIcon: Icons.chat_bubble),
      (id: NavTab.clients, label: 'Clientes', icon: Icons.people_outline, activeIcon: Icons.people),
    ];

    if (notifier.navStyle == 'fab-centered') {
      return Container(
        height: 72,
        decoration: BoxDecoration(
          color: tokens.bg,
          border: Border(top: BorderSide(color: tokens.borderSoft)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Row(
              children: [
                ...items.sublist(0, 2).map((it) => _NavBtn(item: it, active: active, tokens: tokens, navStyle: notifier.navStyle, onTap: onTap, compact: true)),
                const SizedBox(width: 56),
                ...items.sublist(2).map((it) => _NavBtn(item: it, active: active, tokens: tokens, navStyle: notifier.navStyle, onTap: onTap, compact: true)),
              ],
            ),
            Positioned(
              top: -28,
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tokens.green,
                    boxShadow: [
                      BoxShadow(
                        color: tokens.green.withAlpha(85),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 26),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: tokens.bg,
        border: Border(top: BorderSide(color: tokens.borderSoft)),
      ),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        children: items.map((it) => _NavBtn(
          item: it,
          active: active,
          tokens: tokens,
          navStyle: notifier.navStyle,
          onTap: onTap,
        )).toList(),
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final ({NavTab id, String label, IconData icon, IconData activeIcon}) item;
  final NavTab active;
  final dynamic tokens;
  final String navStyle;
  final ValueChanged<NavTab>? onTap;
  final bool compact;

  const _NavBtn({
    required this.item,
    required this.active,
    required this.tokens,
    required this.navStyle,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = active == item.id;
    final color = isActive ? tokens.green : tokens.textMuted;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap?.call(item.id),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: compact ? 8 : 6),
            Icon(
              isActive ? item.activeIcon : item.icon,
              size: 22,
              color: color,
            ),
            if (navStyle != 'icons-only') ...[
              const SizedBox(height: 3),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
            SizedBox(height: compact ? 8 : 4),
          ],
        ),
      ),
    );
  }
}
