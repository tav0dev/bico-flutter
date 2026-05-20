import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bicco_provider.dart';
import '../widgets/bicco_card.dart';
import '../widgets/top_bar.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/avatar.dart';
import '../widgets/ai_sparkle.dart';
import '../widgets/bicco_button.dart';

class DashboardScreen extends StatelessWidget {
  final ValueChanged<NavTab>? onNavTap;

  const DashboardScreen({super.key, this.onNavTap});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<BiccoNotifier>();
    final tokens = notifier.tokens;

    return Scaffold(
      backgroundColor: tokens.bg,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: BiccoTopBar(
              title: 'Olá, Marina',
              subtitle: 'Quarta, 6 de maio',
              leading: const BiccoAvatar(name: 'Marina Silva', size: 40),
              trailing: Stack(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.notifications_none, size: 22, color: tokens.text),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: tokens.orange,
                        border: Border.all(color: tokens.bg, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              children: [
                // Today summary card
                BiccoCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'HOJE',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: tokens.textMuted,
                                    letterSpacing: 0.04,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '3 atendimentos',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: tokens.text,
                                    letterSpacing: -0.02,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'previsão',
                                  style: TextStyle(fontSize: 12, color: tokens.textMuted, fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  'R\$ 380',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: tokens.green,
                                    letterSpacing: -0.01,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Divider(color: tokens.borderSoft, height: 1, indent: 16, endIndent: 16),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        child: Row(
                          children: [
                            _Stat(label: 'Concluídos', value: '1', color: tokens.green),
                            _Stat(label: 'Em andamento', value: '1', color: tokens.orange),
                            _Stat(label: 'Pendente', value: '1', color: tokens.textMuted),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Next appointment
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        'Próximo',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: tokens.text,
                          letterSpacing: -0.015,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => onNavTap?.call(NavTab.agenda),
                      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4)),
                      child: Text(
                        'Ver agenda',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: tokens.green,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                BiccoCard(
                  padding: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: tokens.greenSoft,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '14:00',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: tokens.green,
                                  letterSpacing: 0.04,
                                ),
                              ),
                              Text(
                                '1h30',
                                style: TextStyle(fontSize: 10, color: tokens.green),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Treino funcional • Carla M.',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: tokens.text,
                                  letterSpacing: -0.01,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(Icons.location_on_outlined, size: 13, color: tokens.textMuted),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Studio Vila Madalena',
                                    style: TextStyle(fontSize: 13, color: tokens.textMuted),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, size: 18, color: tokens.textMuted),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // AI suggestion card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: notifier.isDark
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [tokens.orangeSoft, tokens.purpleSoft],
                          )
                        : const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFFFF7ED), Color(0xFFEEF2FF)],
                          ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: tokens.orangeSoft),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const AISparkle(size: 14),
                          const SizedBox(width: 8),
                          Text(
                            'TUCO SUGERE',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: tokens.orange,
                              letterSpacing: 0.04,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'João Pedro não confirmou o treino de amanhã. Quer que eu envie um lembrete?',
                        style: TextStyle(
                          fontSize: 15,
                          color: tokens.text,
                          fontWeight: FontWeight.w500,
                          height: 1.45,
                          letterSpacing: -0.01,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          BiccoButton(
                            variant: BtnVariant.ai,
                            size: BtnSize.sm,
                            onPressed: () {},
                            child: const Text('Enviar lembrete'),
                          ),
                          const SizedBox(width: 8),
                          BiccoButton(
                            variant: BtnVariant.ghost,
                            size: BtnSize.sm,
                            onPressed: () {},
                            child: const Text('Agora não'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Quick actions
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    'Atalhos',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: tokens.text,
                      letterSpacing: -0.015,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.5,
                  children: [
                    _QuickAction(icon: Icons.attach_money, label: 'Novo orçamento', tint: tokens.green),
                    _QuickAction(icon: Icons.people_outline, label: 'Adicionar cliente', tint: tokens.purple),
                    _QuickAction(icon: Icons.image_outlined, label: 'Criar post', tint: tokens.orange, ai: true,
                      onTap: () => Navigator.pushNamed(context, '/create-post')),
                    _QuickAction(icon: Icons.calendar_today_outlined, label: 'Bloquear horário', tint: tokens.textMuted),
                  ],
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: BiccoBottomNav(
              active: NavTab.home,
              onTap: onNavTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Stat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<BiccoNotifier>().tokens;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: -0.01,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: tokens.textMuted),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color tint;
  final bool ai;
  final VoidCallback? onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.tint,
    this.ai = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<BiccoNotifier>().tokens;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
        decoration: BoxDecoration(
          color: tokens.bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: tokens.borderSoft),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: tint.withAlpha(26),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: tint),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: tokens.text,
                    letterSpacing: -0.005,
                  ),
                ),
              ],
            ),
            if (ai)
              const Positioned(top: 0, right: 0, child: AISparkle(size: 12)),
          ],
        ),
      ),
    );
  }
}
