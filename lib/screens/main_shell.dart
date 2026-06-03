import 'package:flutter/material.dart';
import '../widgets/bottom_nav.dart';
import 'dashboard_screen.dart';
import 'agenda_screen.dart';
import 'inbox_screen.dart';
import 'services_screen.dart';
import 'clients_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  NavTab _active = NavTab.home;

  void _onNav(NavTab tab) => setState(() => _active = tab);

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: _active.index,
      children: [
        DashboardScreen(onNavTap: _onNav),
        AgendaScreen(onNavTap: _onNav),
        InboxScreen(onNavTap: _onNav),
        ServicesScreen(onNavTap: _onNav),
        ClientsScreen(onNavTap: _onNav),
      ],
    );
  }
}
