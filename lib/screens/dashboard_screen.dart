import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/bico_provider.dart';
import '../providers/agendamentos_provider.dart';
import '../widgets/bico_card.dart';
import '../widgets/top_bar.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/avatar.dart';
import '../widgets/ai_sparkle.dart';
import '../widgets/bico_button.dart';
import '../widgets/agendamento_sheet.dart';

class DashboardScreen extends StatefulWidget {
  final ValueChanged<NavTab>? onNavTap;

  const DashboardScreen({super.key, this.onNavTap});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AgendamentosProvider>().loadAgendamentos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<BicoNotifier>();
    final tokens = notifier.tokens;
    
    final agendamentosProvider = context.watch<AgendamentosProvider>();
    final hoje = agendamentosProvider.agendamentosHoje;
    final proximo = agendamentosProvider.nextAgendamento;
    
    final concluidosHoje = hoje.where((a) => a.status == 'concluido').length;
    final pendentesHoje = hoje.where((a) => a.status == 'pendente' || a.status == 'confirmado').length;
    final faturamentoHoje = hoje.where((a) => a.status == 'concluido').fold(0.0, (sum, a) => sum + ((a.precoCobradoCentavos ?? 0) / 100));

    return Scaffold(
      backgroundColor: tokens.bg,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: BicoTopBar(
              title: 'Olá, ${notifier.prestador?['nome_completo']?.split(' ').first ?? 'Prestador'}',
              subtitle: DateFormat('EEEE, d \'de\' MMMM', 'pt_BR').format(DateTime.now()),
              leading: GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/profile'),
                child: BicoAvatar(name: notifier.prestador?['nome_completo'] ?? 'Perfil', size: 40),
              ),
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
                BicoCard(
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
                                  '${hoje.length} agendamentos',
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
                                  'faturado',
                                  style: TextStyle(fontSize: 12, color: tokens.textMuted, fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  'R\$ ${faturamentoHoje.toStringAsFixed(2).replaceAll('.', ',')}',
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
                            _Stat(label: 'Concluídos', value: concluidosHoje.toString(), color: tokens.green),
                            _Stat(label: 'Pendentes', value: pendentesHoje.toString(), color: tokens.orange),
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
                  ],
                ),
                const SizedBox(height: 10),
                if (agendamentosProvider.isLoading)
                  Center(child: CircularProgressIndicator(color: tokens.green))
                else if (proximo == null)
                  BicoCard(
                    child: Center(
                      child: Text('Nenhum agendamento futuro.', style: TextStyle(color: tokens.textMuted)),
                    ),
                  )
                else
                  BicoCard(
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
                                  DateFormat('HH:mm').format(proximo.dataHoraInicio),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: tokens.green,
                                    letterSpacing: 0.04,
                                  ),
                                ),
                                Text(
                                  '${proximo.dataHoraFim.difference(proximo.dataHoraInicio).inMinutes}m',
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
                                  '${proximo.servicoNome ?? 'Serviço genérico'} • ${proximo.clienteNome?.split(' ').first ?? 'Cliente'}',
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
                                      'No local',
                                      style: TextStyle(fontSize: 13, color: tokens.textMuted),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              agendamentosProvider.updateStatus(proximo.id, 'concluido');
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: tokens.green,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check, color: Colors.white, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // AI suggestion card (mocked still, but keeping style)
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
                        'Sua agenda está livre amanhã de tarde. Quer que eu envie uma oferta para seus clientes inativos?',
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
                          BicoButton(
                            variant: BtnVariant.ai,
                            size: BtnSize.sm,
                            onPressed: () {},
                            child: const Text('Enviar oferta'),
                          ),
                          const SizedBox(width: 8),
                          BicoButton(
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
                    _QuickAction(icon: Icons.calendar_month, label: 'Novo agendamento', tint: tokens.green, onTap: () {
                      AgendamentoSheet.show(context, tokens);
                    }),
                    _QuickAction(icon: Icons.people_outline, label: 'Ver clientes', tint: tokens.purple, onTap: () {
                      widget.onNavTap?.call(NavTab.clients);
                    }),
                    _QuickAction(icon: Icons.image_outlined, label: 'Criar post', tint: tokens.orange, ai: true,
                      onTap: () => Navigator.pushNamed(context, '/create-post')),
                    _QuickAction(icon: Icons.add_circle_outline, label: 'Criar serviço', tint: tokens.textMuted, onTap: () {
                      widget.onNavTap?.call(NavTab.services);
                    }),
                  ],
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: BicoBottomNav(
              active: NavTab.home,
              onTap: widget.onNavTap,
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
    final tokens = context.watch<BicoNotifier>().tokens;
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
    final tokens = context.watch<BicoNotifier>().tokens;
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
                const Spacer(),
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
