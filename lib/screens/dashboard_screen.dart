import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/bico_provider.dart';
import '../providers/agendamentos_provider.dart';
import '../providers/clientes_provider.dart';
import '../providers/servicos_provider.dart';
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
      context.read<ClientesProvider>().loadClientes();
      context.read<ServicosProvider>().loadServicos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<BicoNotifier>();
    final tokens = notifier.tokens;
    final agendamentosProvider = context.watch<AgendamentosProvider>();
    final clientesProvider = context.watch<ClientesProvider>();
    final servicosProvider = context.watch<ServicosProvider>();

    final hoje = agendamentosProvider.agendamentosHoje;
    final proximo = agendamentosProvider.nextAgendamento;
    final concluidosHoje = hoje.where((a) => a.status == 'concluido').length;
    final pendentesHoje = hoje
        .where((a) => a.status == 'pendente' || a.status == 'confirmado')
        .length;
    final faturamentoHoje = hoje
        .where((a) => a.status == 'concluido')
        .fold(0.0, (sum, a) => sum + ((a.precoCobradoCentavos ?? 0) / 100));
    final servicosAtivos = servicosProvider.servicos
        .where((s) => s.ativo)
        .length;

    return Scaffold(
      backgroundColor: tokens.bg,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: BicoTopBar(
              title: 'Ola, ${_firstName(notifier.prestador?['nome_completo'])}',
              subtitle: DateFormat(
                'EEEE, d MMM',
                'pt_BR',
              ).format(DateTime.now()),
              leading: GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/profile'),
                child: BicoAvatar(
                  name: notifier.prestador?['nome_completo'] ?? 'Perfil',
                  size: 40,
                ),
              ),
              trailing: IconButton(
                tooltip: 'Perfil',
                onPressed: () => Navigator.pushNamed(context, '/profile'),
                icon: Icon(Icons.tune, size: 22, color: tokens.text),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              children: [
                _TodayPanel(
                  totalHoje: hoje.length,
                  concluidosHoje: concluidosHoje,
                  pendentesHoje: pendentesHoje,
                  faturamentoHoje: faturamentoHoje,
                  proximo: proximo,
                  isLoading: agendamentosProvider.isLoading,
                  onNewAppointment: () => _openNewAppointment(tokens),
                  onOpenAgenda: () => widget.onNavTap?.call(NavTab.agenda),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: BicoButton(
                        full: true,
                        size: BtnSize.lg,
                        onPressed: () => _openNewAppointment(tokens),
                        child: const Row(
                          children: [
                            Icon(Icons.add),
                            SizedBox(width: 8),
                            Text('Agendar'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: BicoButton(
                        full: true,
                        variant: BtnVariant.ai,
                        size: BtnSize.lg,
                        onPressed: () =>
                            Navigator.pushNamed(context, '/create-post'),
                        child: const Row(
                          children: [
                            Icon(Icons.campaign),
                            SizedBox(width: 8),
                            Text('Divulgar'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _SectionTitle(
                  title: 'Modulos',
                  subtitle: 'Cada area resolve uma tarefa do dia a dia.',
                ),
                const SizedBox(height: 10),
                _ModuleGrid(
                  modules: [
                    _ModuleData(
                      title: 'Agenda',
                      subtitle: 'Blocos de horario, dia, semana e mes.',
                      action: 'Ver blocos',
                      icon: Icons.calendar_view_week_outlined,
                      color: tokens.green,
                      onTap: () => widget.onNavTap?.call(NavTab.agenda),
                    ),
                    _ModuleData(
                      title: 'Mensagens',
                      subtitle: 'WhatsApp, Instagram e Messenger juntos.',
                      action: 'Abrir inbox',
                      icon: Icons.forum_outlined,
                      color: tokens.purple,
                      badge: 'novo',
                      onTap: () => widget.onNavTap?.call(NavTab.inbox),
                    ),
                    _ModuleData(
                      title: 'Divulgar',
                      subtitle: 'Posts, ofertas e botao de turbinar.',
                      action: 'Criar post',
                      icon: Icons.campaign_outlined,
                      color: tokens.orange,
                      onTap: () => Navigator.pushNamed(context, '/create-post'),
                    ),
                    _ModuleData(
                      title: 'Servicos',
                      subtitle: 'Preco, duracao e cor na agenda.',
                      action: 'Organizar',
                      icon: Icons.work_outline,
                      color: tokens.text,
                      onTap: () => widget.onNavTap?.call(NavTab.services),
                    ),
                    _ModuleData(
                      title: 'Clientes',
                      subtitle: 'Contatos, historico e retornos.',
                      action: 'Ver lista',
                      icon: Icons.people_outline,
                      color: tokens.greenDark,
                      onTap: () => widget.onNavTap?.call(NavTab.clients),
                    ),
                    _ModuleData(
                      title: 'Perfil',
                      subtitle: 'Dados, cidade, tema e preferencias.',
                      action: 'Ajustar',
                      icon: Icons.person_outline,
                      color: tokens.textMuted,
                      onTap: () => Navigator.pushNamed(context, '/profile'),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _SectionTitle(
                  title: 'Seu app hoje',
                  subtitle: 'Um resumo curto para saber por onde comecar.',
                ),
                const SizedBox(height: 10),
                _MetricsRow(
                  metrics: [
                    _MetricData('Hoje', hoje.length.toString(), 'agenda'),
                    _MetricData(
                      'Clientes',
                      clientesProvider.clientes.length.toString(),
                      'base',
                    ),
                    _MetricData(
                      'Servicos',
                      servicosAtivos.toString(),
                      'ativos',
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _SetupList(
                  hasServices: servicosProvider.servicos.isNotEmpty,
                  hasClients: clientesProvider.clientes.isNotEmpty,
                  hasGoogleCalendar: notifier.hasGoogleCalendarToken,
                  hasAppointment: proximo != null,
                  isLoadingGoogle: notifier.isLoadingEvents,
                  onServices: () => widget.onNavTap?.call(NavTab.services),
                  onClients: () => widget.onNavTap?.call(NavTab.clients),
                  onGoogle: notifier.signInWithGoogle,
                  onAgenda: () => _openNewAppointment(tokens),
                ),
                const SizedBox(height: 18),
                _TucoSuggestion(
                  hasAppointment: proximo != null,
                  onCreatePost: () =>
                      Navigator.pushNamed(context, '/create-post'),
                  onOpenInbox: () => widget.onNavTap?.call(NavTab.inbox),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: BicoBottomNav(active: NavTab.home, onTap: widget.onNavTap),
          ),
        ],
      ),
    );
  }

  String _firstName(dynamic value) {
    final text = (value ?? '').toString().trim();
    if (text.isEmpty) return 'Prestador';
    return text.split(RegExp(r'\s+')).first;
  }

  void _openNewAppointment(dynamic tokens) {
    final now = DateTime.now();
    final rounded = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      ((now.minute ~/ 30) + 1) * 30,
    );
    AgendamentoSheet.show(context, tokens, initialStart: rounded);
  }
}

class _TodayPanel extends StatelessWidget {
  final int totalHoje;
  final int concluidosHoje;
  final int pendentesHoje;
  final double faturamentoHoje;
  final dynamic proximo;
  final bool isLoading;
  final VoidCallback onNewAppointment;
  final VoidCallback? onOpenAgenda;

  const _TodayPanel({
    required this.totalHoje,
    required this.concluidosHoje,
    required this.pendentesHoje,
    required this.faturamentoHoje,
    required this.proximo,
    required this.isLoading,
    required this.onNewAppointment,
    this.onOpenAgenda,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<BicoNotifier>().tokens;

    return BicoCard(
      borderRadius: 8,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hoje',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: tokens.text,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$totalHoje agendamentos',
                      style: TextStyle(fontSize: 13, color: tokens.textMuted),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: onOpenAgenda,
                icon: Icon(Icons.arrow_forward, size: 16, color: tokens.green),
                label: Text('Agenda', style: TextStyle(color: tokens.green)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _MiniStat(
                label: 'Pendentes',
                value: pendentesHoje.toString(),
                color: tokens.orange,
              ),
              _MiniStat(
                label: 'Concluidos',
                value: concluidosHoje.toString(),
                color: tokens.green,
              ),
              _MiniStat(
                label: 'Faturado',
                value: _money(faturamentoHoje),
                color: tokens.green,
              ),
            ],
          ),
          Divider(color: tokens.borderSoft, height: 28),
          if (isLoading)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: CircularProgressIndicator(color: tokens.green),
              ),
            )
          else if (proximo == null)
            _EmptyNextAppointment(onNewAppointment: onNewAppointment)
          else
            _NextAppointment(agendamento: proximo),
        ],
      ),
    );
  }

  String _money(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<BicoNotifier>().tokens;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: tokens.textMuted),
          ),
        ],
      ),
    );
  }
}

class _EmptyNextAppointment extends StatelessWidget {
  final VoidCallback onNewAppointment;

  const _EmptyNextAppointment({required this.onNewAppointment});

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<BicoNotifier>().tokens;

    return Row(
      children: [
        Icon(Icons.event_available_outlined, color: tokens.textMuted, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Nenhum horario futuro. Crie um bloco na agenda.',
            style: TextStyle(fontSize: 13, color: tokens.textMuted),
          ),
        ),
        TextButton(
          onPressed: onNewAppointment,
          child: Text('Criar', style: TextStyle(color: tokens.green)),
        ),
      ],
    );
  }
}

class _NextAppointment extends StatelessWidget {
  final dynamic agendamento;

  const _NextAppointment({required this.agendamento});

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<BicoNotifier>().tokens;
    final start = agendamento.dataHoraInicio as DateTime;
    final end = agendamento.dataHoraFim as DateTime;
    final dateText = _isToday(start)
        ? 'Hoje'
        : DateFormat('d MMM', 'pt_BR').format(start);

    return Row(
      children: [
        Container(
          width: 64,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: tokens.greenSoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(
                DateFormat('HH:mm').format(start),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: tokens.green,
                ),
              ),
              Text(
                _durationLabel(end.difference(start).inMinutes),
                style: TextStyle(fontSize: 10.5, color: tokens.green),
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
                agendamento.servicoNome ?? 'Servico',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: tokens.text,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$dateText com ${agendamento.clienteNome ?? 'cliente'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: tokens.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String _durationLabel(int minutes) {
    if (minutes < 60) return '${minutes}min';
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    if (rest == 0) return '${hours}h';
    return '${hours}h${rest.toString().padLeft(2, '0')}';
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<BicoNotifier>().tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: tokens.text,
          ),
        ),
        const SizedBox(height: 3),
        Text(subtitle, style: TextStyle(fontSize: 13, color: tokens.textMuted)),
      ],
    );
  }
}

class _ModuleGrid extends StatelessWidget {
  final List<_ModuleData> modules;

  const _ModuleGrid({required this.modules});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720 ? 3 : 2;
        final tileHeight = constraints.maxWidth >= 420 ? 176.0 : 198.0;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: modules.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: tileHeight,
          ),
          itemBuilder: (context, index) => _ModuleTile(data: modules[index]),
        );
      },
    );
  }
}

class _ModuleData {
  final String title;
  final String subtitle;
  final String action;
  final IconData icon;
  final Color color;
  final String? badge;
  final VoidCallback? onTap;

  const _ModuleData({
    required this.title,
    required this.subtitle,
    required this.action,
    required this.icon,
    required this.color,
    this.badge,
    this.onTap,
  });
}

class _ModuleTile extends StatelessWidget {
  final _ModuleData data;

  const _ModuleTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<BicoNotifier>().tokens;

    return GestureDetector(
      onTap: data.onTap,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: tokens.bgSoft,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: tokens.borderSoft),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: data.color.withAlpha(28),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(data.icon, size: 18, color: data.color),
                ),
                const Spacer(),
                if (data.badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: tokens.purpleSoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      data.badge!,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: tokens.purple,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              data.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: tokens.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              data.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                height: 1.25,
                color: tokens.textMuted,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: Text(
                    data.action,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: tokens.green,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, size: 17, color: tokens.green),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricData {
  final String label;
  final String value;
  final String helper;

  const _MetricData(this.label, this.value, this.helper);
}

class _MetricsRow extends StatelessWidget {
  final List<_MetricData> metrics;

  const _MetricsRow({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<BicoNotifier>().tokens;

    return Row(
      children: metrics
          .map(
            (metric) => Expanded(
              child: Container(
                margin: EdgeInsets.only(right: metric == metrics.last ? 0 : 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: tokens.bgSoft,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: tokens.borderSoft),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metric.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: tokens.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      metric.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: tokens.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      metric.helper,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: tokens.textMuted),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _SetupList extends StatelessWidget {
  final bool hasServices;
  final bool hasClients;
  final bool hasGoogleCalendar;
  final bool hasAppointment;
  final bool isLoadingGoogle;
  final VoidCallback? onServices;
  final VoidCallback? onClients;
  final VoidCallback? onGoogle;
  final VoidCallback? onAgenda;

  const _SetupList({
    required this.hasServices,
    required this.hasClients,
    required this.hasGoogleCalendar,
    required this.hasAppointment,
    required this.isLoadingGoogle,
    this.onServices,
    this.onClients,
    this.onGoogle,
    this.onAgenda,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SetupRow(
          done: hasServices,
          title: hasServices ? 'Servicos prontos' : 'Cadastre seus servicos',
          subtitle: hasServices
              ? 'Duracao e agenda ja conversam entre si.'
              : 'Isso deixa a agenda e os posts mais faceis.',
          action: hasServices ? null : 'Abrir',
          onTap: onServices,
        ),
        _SetupRow(
          done: hasClients,
          title: hasClients ? 'Clientes no app' : 'Adicione seus clientes',
          subtitle: hasClients
              ? 'A base esta pronta para mensagens e retornos.'
              : 'Comece com os contatos que mais agendam.',
          action: hasClients ? null : 'Adicionar',
          onTap: onClients,
        ),
        _SetupRow(
          done: hasGoogleCalendar,
          title: hasGoogleCalendar
              ? 'Google Calendar conectado'
              : 'Conectar Google Calendar',
          subtitle: hasGoogleCalendar
              ? 'Eventos externos aparecem na agenda.'
              : 'Evita conflito com compromissos de fora.',
          action: hasGoogleCalendar
              ? null
              : (isLoadingGoogle ? 'Abrindo...' : 'Conectar'),
          onTap: isLoadingGoogle ? null : onGoogle,
        ),
        _SetupRow(
          done: hasAppointment,
          title: hasAppointment ? 'Agenda com movimento' : 'Crie um horario',
          subtitle: hasAppointment
              ? 'O proximo atendimento aparece no topo.'
              : 'Use blocos de 30 minutos para nao baguncar.',
          action: hasAppointment ? null : 'Criar',
          onTap: onAgenda,
          isLast: true,
        ),
      ],
    );
  }
}

class _SetupRow extends StatelessWidget {
  final bool done;
  final String title;
  final String subtitle;
  final String? action;
  final VoidCallback? onTap;
  final bool isLast;

  const _SetupRow({
    required this.done,
    required this.title,
    required this.subtitle,
    this.action,
    this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<BicoNotifier>().tokens;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: tokens.borderSoft)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: done ? tokens.greenSoft : tokens.bgSoft,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: done ? tokens.greenSoft : tokens.borderSoft,
              ),
            ),
            child: Icon(
              done ? Icons.check : Icons.circle_outlined,
              size: 16,
              color: done ? tokens.green : tokens.textMuted,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: tokens.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: tokens.textMuted),
                ),
              ],
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onTap,
              child: Text(action!, style: TextStyle(color: tokens.green)),
            ),
          ],
        ],
      ),
    );
  }
}

class _TucoSuggestion extends StatelessWidget {
  final bool hasAppointment;
  final VoidCallback? onCreatePost;
  final VoidCallback? onOpenInbox;

  const _TucoSuggestion({
    required this.hasAppointment,
    this.onCreatePost,
    this.onOpenInbox,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<BicoNotifier>().tokens;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.orangeSoft,
        borderRadius: BorderRadius.circular(8),
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
                'TUCO',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: tokens.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            hasAppointment
                ? 'Quando sobrar um horario, crie uma oferta rapida e mande para quem esta parado.'
                : 'Sua agenda ainda esta quieta. Um post simples com botao de turbinar pode trazer os primeiros contatos.',
            style: TextStyle(
              fontSize: 14,
              height: 1.35,
              color: tokens.text,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              BicoButton(
                variant: BtnVariant.ai,
                size: BtnSize.sm,
                onPressed: onCreatePost,
                child: const Text('Criar post'),
              ),
              const SizedBox(width: 8),
              BicoButton(
                variant: BtnVariant.secondary,
                size: BtnSize.sm,
                onPressed: onOpenInbox,
                child: const Text('Ver mensagens'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
