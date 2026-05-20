import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bicco_provider.dart';
import '../widgets/top_bar.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/avatar.dart';
import '../widgets/pill.dart';

class ClientsScreen extends StatelessWidget {
  final ValueChanged<NavTab>? onNavTap;

  const ClientsScreen({super.key, this.onNavTap});

  static const _clients = [
    (name: 'Carla Mendes', tag: 'Pacote', last: 'hoje', value: 'R\$ 750/mês', recent: true, isNew: false, paused: false),
    (name: 'João Pedro', tag: 'Avulso', last: 'amanhã', value: '8 sessões', recent: false, isNew: false, paused: false),
    (name: 'Lia Faria', tag: 'Pacote', last: 'ontem', value: 'R\$ 1.080/mês', recent: false, isNew: false, paused: false),
    (name: 'Pedro Rocha', tag: 'Novo', last: 'há 3 dias', value: '—', recent: false, isNew: true, paused: false),
    (name: 'Beatriz Lima', tag: 'Pacote', last: 'há 5 dias', value: 'R\$ 750/mês', recent: false, isNew: false, paused: false),
    (name: 'Tomás Andrade', tag: 'Pausado', last: 'há 2 sem', value: '—', recent: false, isNew: false, paused: true),
    (name: 'Renata Costa', tag: 'Avulso', last: 'há 1 mês', value: '3 sessões', recent: false, isNew: false, paused: false),
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<BiccoNotifier>().tokens;

    final today = _clients.where((c) => c.recent).toList();
    final thisWeek = _clients.where((c) => !c.recent && !c.paused).take(4).toList();
    final inactive = _clients.where((c) => c.paused).toList();

    return Scaffold(
      backgroundColor: tokens.bg,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: BiccoTopBar(
              title: 'Clientes',
              large: true,
              trailing: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: tokens.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 20),
              ),
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: tokens.bgSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, size: 18, color: tokens.textMuted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Buscar cliente…',
                      style: TextStyle(fontSize: 14, color: tokens.textMuted),
                    ),
                  ),
                  Icon(Icons.tune, size: 16, color: tokens.text),
                ],
              ),
            ),
          ),

          // Stats row
          SizedBox(
            height: 58,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              children: [
                _Stat2(value: '24', label: 'ativos', tint: tokens.green),
                const SizedBox(width: 10),
                _Stat2(value: '3', label: 'novos', tint: tokens.purple),
                const SizedBox(width: 10),
                _Stat2(value: 'R\$ 6.4k', label: 'recorrente', tint: tokens.orange),
              ],
            ),
          ),

          // Client groups
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 8),
              children: [
                _ClientGroup(title: 'Hoje', clients: today, tokens: tokens),
                _ClientGroup(title: 'Esta semana', clients: thisWeek, tokens: tokens),
                _ClientGroup(title: 'Inativos', clients: inactive, tokens: tokens),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Text(
                    '24 clientes no total',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: tokens.textFaint),
                  ),
                ),
              ],
            ),
          ),

          SafeArea(
            top: false,
            child: BicoBottomNav(active: NavTab.clients, onTap: onNavTap),
          ),
        ],
      ),
    );
  }
}

class _Stat2 extends StatelessWidget {
  final String value;
  final String label;
  final Color tint;

  const _Stat2({required this.value, required this.label, required this.tint});

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<BicoNotifier>().tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      constraints: const BoxConstraints(minWidth: 90),
      decoration: BoxDecoration(
        color: tokens.bgSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: tint,
              letterSpacing: -0.01,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: tokens.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientGroup extends StatelessWidget {
  final String title;
  final List<dynamic> clients;
  final dynamic tokens;

  const _ClientGroup({required this.title, required this.clients, required this.tokens});

  @override
  Widget build(BuildContext context) {
    if (clients.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: tokens.textMuted,
              letterSpacing: 0.06,
            ),
          ),
        ),
        ...clients.asMap().entries.map((entry) {
          final i = entry.key;
          final c = entry.value;
          return Opacity(
            opacity: c.paused ? 0.6 : 1.0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                  top: i == 0 ? BorderSide(color: tokens.borderSoft) : BorderSide.none,
                  bottom: BorderSide(color: tokens.borderSoft),
                ),
              ),
              child: Row(
                children: [
                  BicoAvatar(name: c.name, size: 42),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              c.name,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: tokens.text,
                                letterSpacing: -0.005,
                              ),
                            ),
                            if (c.isNew) ...[
                              const SizedBox(width: 6),
                              const BicoPill(text: 'novo', color: 'purple', size: 'sm'),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${c.tag} • último contato ${c.last}',
                          style: TextStyle(fontSize: 12, color: tokens.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    c.value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: tokens.text,
                      letterSpacing: -0.005,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
