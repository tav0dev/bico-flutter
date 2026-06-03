import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bico_provider.dart';

enum NavTab { home, agenda, inbox, services, clients }

class BicoBottomNav extends StatelessWidget {
  final NavTab active;
  final ValueChanged<NavTab>? onTap;

  const BicoBottomNav({super.key, required this.active, this.onTap});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<BicoNotifier>();
    final tokens = notifier.tokens;

    const items = [
      (
        id: NavTab.home,
        label: 'Inicio',
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
      ),
      (
        id: NavTab.agenda,
        label: 'Agenda',
        icon: Icons.calendar_today_outlined,
        activeIcon: Icons.calendar_today,
      ),
      (
        id: NavTab.inbox,
        label: 'Mensagens',
        icon: Icons.forum_outlined,
        activeIcon: Icons.forum,
      ),
      (
        id: NavTab.services,
        label: 'Servicos',
        icon: Icons.work_outline,
        activeIcon: Icons.work,
      ),
      (
        id: NavTab.clients,
        label: 'Clientes',
        icon: Icons.people_outline,
        activeIcon: Icons.people,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: tokens.bg,
        border: Border(top: BorderSide(color: tokens.borderSoft)),
      ),
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
      child: Row(
        children: items
            .map(
              (it) => _NavBtn(
                item: it,
                active: active,
                tokens: tokens,
                navStyle: notifier.navStyle,
                onTap: onTap,
              ),
            )
            .toList(),
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

  const _NavBtn({
    required this.item,
    required this.active,
    required this.tokens,
    required this.navStyle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = active == item.id;
    final color = isActive ? tokens.green : tokens.textMuted;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap?.call(item.id),
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 56,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isActive ? item.activeIcon : item.icon,
                size: 21,
                color: color,
              ),
              if (navStyle != 'icons-only') ...[
                const SizedBox(height: 3),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
