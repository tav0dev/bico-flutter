import 'package:flutter/material.dart';
import 'package:googleapis/calendar/v3.dart' as google;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/agendamento.dart';
import '../providers/agendamentos_provider.dart';
import '../providers/bico_provider.dart';
import '../widgets/agendamento_sheet.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/top_bar.dart';

enum _AgendaView { day, week, month, year }

class AgendaScreen extends StatefulWidget {
  final ValueChanged<NavTab>? onNavTap;
  const AgendaScreen({super.key, this.onNavTap});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  static const _slotMinutes = 30;
  static const _hours = [7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20];
  static const _hourHeight = 64.0;

  DateTime _selectedDate = DateTime.now();
  _AgendaView _view = _AgendaView.day;

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
    final entries = _entries(
      agendamentosProvider.agendamentos,
      notifier.googleEvents,
      tokens,
    );

    return Scaffold(
      backgroundColor: tokens.bg,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openNewAt(_defaultNewStart()),
        backgroundColor: tokens.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: BicoTopBar(
              title: _title(),
              subtitle: _subtitle(entries),
              leading: IconButton(
                tooltip: 'Atualizar',
                onPressed: agendamentosProvider.isLoading
                    ? null
                    : () => agendamentosProvider.loadAgendamentos(),
                icon: agendamentosProvider.isLoading
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: tokens.text,
                        ),
                      )
                    : Icon(Icons.refresh, size: 20, color: tokens.text),
              ),
            ),
          ),
          _viewSelector(tokens),
          _googleCalendarCard(tokens, notifier),
          _periodControls(tokens),
          _serviceLegend(tokens, entries),
          Expanded(child: _body(tokens, entries, agendamentosProvider)),
          SafeArea(
            top: false,
            child: BicoBottomNav(active: NavTab.agenda, onTap: widget.onNavTap),
          ),
        ],
      ),
    );
  }

  Future<void> _syncGoogleCalendar(BicoNotifier notifier) async {
    if (!notifier.hasGoogleCalendarToken) {
      await notifier.signInWithGoogle();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Conecte sua conta Google e permita acesso ao Calendar.',
          ),
        ),
      );
      return;
    }

    final ok = await notifier.fetchGoogleEvents();
    if (!mounted) return;
    final message = ok
        ? 'Google Calendar sincronizado.'
        : notifier.errorMessage ??
              'Nao consegui sincronizar. Entre com Google permitindo Calendar.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _googleCalendarCard(dynamic tokens, BicoNotifier notifier) {
    final connected = notifier.hasGoogleCalendarToken;
    final title = connected
        ? 'Sincronizar Google Calendar'
        : 'Conectar Google Calendar';
    final subtitle = connected
        ? '${notifier.googleEvents.length} eventos do Google carregados'
        : 'Mostre seus eventos do Google junto da agenda do Bico';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: notifier.isLoadingEvents
            ? null
            : () => _syncGoogleCalendar(notifier),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: connected ? tokens.greenSoft : tokens.bgSoft,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: connected ? tokens.green : tokens.borderSoft,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: connected ? tokens.green : tokens.bg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: tokens.borderSoft),
                ),
                child: notifier.isLoadingEvents
                    ? Padding(
                        padding: const EdgeInsets.all(9),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: connected ? Colors.white : tokens.green,
                        ),
                      )
                    : Icon(
                        connected ? Icons.sync : Icons.calendar_month,
                        color: connected ? Colors.white : tokens.green,
                        size: 20,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: tokens.text,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(color: tokens.textMuted, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: tokens.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _viewSelector(dynamic tokens) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: tokens.bgSoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: tokens.borderSoft),
        ),
        child: Row(
          children: [
            _viewButton(tokens, _AgendaView.day, 'Dia'),
            _viewButton(tokens, _AgendaView.week, 'Semana'),
            _viewButton(tokens, _AgendaView.month, 'Mes'),
            _viewButton(tokens, _AgendaView.year, 'Ano'),
          ],
        ),
      ),
    );
  }

  Widget _viewButton(dynamic tokens, _AgendaView view, String label) {
    final selected = view == _view;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _view = view),
        child: Container(
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? tokens.green : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : tokens.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _periodControls(dynamic tokens) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Periodo anterior',
            onPressed: () => setState(() => _selectedDate = _shift(-1)),
            icon: Icon(Icons.chevron_left, color: tokens.text),
          ),
          Expanded(
            child: Text(
              _periodLabel(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: tokens.text,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _selectedDate = DateTime.now()),
            child: Text('Hoje', style: TextStyle(color: tokens.green)),
          ),
          IconButton(
            tooltip: 'Proximo periodo',
            onPressed: () => setState(() => _selectedDate = _shift(1)),
            icon: Icon(Icons.chevron_right, color: tokens.text),
          ),
        ],
      ),
    );
  }

  Widget _serviceLegend(dynamic tokens, List<_CalendarEntry> entries) {
    final visible = _visibleEntries(entries);
    final seen = <String>{};
    final items = <_CalendarEntry>[];
    for (final entry in visible) {
      final key = entry.legendLabel;
      if (seen.add(key)) items.add(entry);
      if (items.length >= 5) break;
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 34,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final entry = items[index];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: tokens.bgSoft,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: tokens.borderSoft),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: entry.color,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  entry.legendLabel,
                  style: TextStyle(
                    color: tokens.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        },
        separatorBuilder: (_, index) => const SizedBox(width: 6),
        itemCount: items.length,
      ),
    );
  }

  Widget _body(
    dynamic tokens,
    List<_CalendarEntry> entries,
    AgendamentosProvider provider,
  ) {
    if (provider.isLoading && provider.agendamentos.isEmpty) {
      return Center(child: CircularProgressIndicator(color: tokens.green));
    }

    switch (_view) {
      case _AgendaView.day:
        return _dayView(tokens, entries);
      case _AgendaView.week:
        return _weekView(tokens, entries);
      case _AgendaView.month:
        return _monthView(tokens, entries);
      case _AgendaView.year:
        return _yearView(tokens, entries);
    }
  }

  Widget _dayView(dynamic tokens, List<_CalendarEntry> entries) {
    final dayEntries = _forDay(entries, _selectedDate);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              Icon(Icons.schedule, size: 16, color: tokens.textMuted),
              const SizedBox(width: 6),
              Text(
                'Horarios do dia',
                style: TextStyle(
                  color: tokens.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.only(left: 64, right: 12, bottom: 96),
                child: SizedBox(
                  height: _hours.length * _hourHeight,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ...List.generate(
                        _hours.length,
                        (i) => Positioned(
                          top: i * _hourHeight,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: _hourHeight,
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(color: tokens.borderSoft),
                              ),
                            ),
                          ),
                        ),
                      ),
                      ..._timeBlocksForDay(_selectedDate).map((slot) {
                        final top =
                            (slot.hour - _hours.first) * _hourHeight +
                            (slot.minute / 60.0) * _hourHeight;
                        final blocked = dayEntries.any(
                          (entry) =>
                              slot.isBefore(entry.end) &&
                              slot
                                  .add(const Duration(minutes: _slotMinutes))
                                  .isAfter(entry.start),
                        );
                        return Positioned(
                          top: top,
                          left: 0,
                          right: 0,
                          height: _hourHeight / (60 / _slotMinutes),
                          child: InkWell(
                            onTap: blocked ? null : () => _openNewAt(slot),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 1),
                              decoration: BoxDecoration(
                                color: blocked
                                    ? Colors.transparent
                                    : tokens.bgSoft.withAlpha(90),
                                border: Border(
                                  top: BorderSide(
                                    color: tokens.borderSoft.withAlpha(130),
                                  ),
                                ),
                              ),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 8),
                              child: blocked
                                  ? null
                                  : Icon(
                                      Icons.add,
                                      size: 14,
                                      color: tokens.textFaint,
                                    ),
                            ),
                          ),
                        );
                      }),
                      ..._timeBlocksForDay(_selectedDate).map((slot) {
                        final top =
                            (slot.hour - _hours.first) * _hourHeight +
                            (slot.minute / 60.0) * _hourHeight;
                        final isFullHour = slot.minute == 0;
                        return Positioned(
                          top: top - 8,
                          left: -60,
                          width: 54,
                          child: Text(
                            _timeLabel(slot),
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: isFullHour ? 11 : 10,
                              fontWeight: isFullHour
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isFullHour
                                  ? tokens.textMuted
                                  : tokens.textFaint,
                            ),
                          ),
                        );
                      }),
                      if (_isSameDay(_selectedDate, DateTime.now()))
                        Positioned(
                          top:
                              (DateTime.now().hour - 7) * _hourHeight +
                              (DateTime.now().minute / 60.0) * _hourHeight,
                          left: 0,
                          right: 0,
                          child: Container(height: 2, color: tokens.red),
                        ),
                      ...dayEntries.map((entry) {
                        final start = entry.start;
                        final top =
                            (start.hour - 7) * _hourHeight +
                            (start.minute / 60.0) * _hourHeight;
                        final height =
                            entry.end.difference(entry.start).inMinutes / 60.0;
                        if (top < 0) return const SizedBox.shrink();
                        return Positioned(
                          top: top,
                          left: 4,
                          right: 4,
                          height: (height * _hourHeight - 2).clamp(28, 180),
                          child: _eventCard(tokens, entry, dense: false),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              if (dayEntries.isEmpty)
                _emptyState(tokens, 'Nenhum evento neste dia.'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _weekView(dynamic tokens, List<_CalendarEntry> entries) {
    final days = _weekDays(_selectedDate);
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
      itemCount: days.length,
      separatorBuilder: (_, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final day = days[index];
        final dayEntries = _forDay(entries, day);
        final selected = _isSameDay(day, _selectedDate);
        return GestureDetector(
          onTap: () => setState(() {
            _selectedDate = day;
            _view = _AgendaView.day;
          }),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: selected ? tokens.greenSoft : tokens.bgSoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? tokens.green : tokens.borderSoft,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 56,
                  child: Column(
                    children: [
                      Text(
                        DateFormat('EEE', 'pt_BR').format(day).toUpperCase(),
                        style: TextStyle(fontSize: 11, color: tokens.textMuted),
                      ),
                      Text(
                        '${day.day}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: tokens.text,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: dayEntries.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            'Livre',
                            style: TextStyle(color: tokens.textFaint),
                          ),
                        )
                      : Column(
                          children: dayEntries
                              .map((entry) => _eventCard(tokens, entry))
                              .toList(),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _monthView(dynamic tokens, List<_CalendarEntry> entries) {
    final first = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final gridStart = first.subtract(Duration(days: first.weekday - 1));
    final days = List.generate(42, (i) => gridStart.add(Duration(days: i)));

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 96),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 0.78,
      ),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final day = days[index];
        final dayEntries = _forDay(entries, day);
        final inMonth = day.month == _selectedDate.month;
        final selected = _isSameDay(day, _selectedDate);
        return GestureDetector(
          onTap: () => setState(() {
            _selectedDate = day;
            _view = _AgendaView.day;
          }),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: selected ? tokens.greenSoft : tokens.bgSoft,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? tokens.green : tokens.borderSoft,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${day.day}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: inMonth ? tokens.text : tokens.textFaint,
                  ),
                ),
                const SizedBox(height: 4),
                ...dayEntries
                    .take(3)
                    .map(
                      (entry) => Container(
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: entry.color,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                if (dayEntries.length > 3)
                  Text(
                    '+${dayEntries.length - 3}',
                    style: TextStyle(fontSize: 10, color: tokens.textMuted),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _yearView(dynamic tokens, List<_CalendarEntry> entries) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 144,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        final month = index + 1;
        final monthEntries = entries
            .where(
              (entry) =>
                  entry.start.year == _selectedDate.year &&
                  entry.start.month == month,
            )
            .toList();
        return GestureDetector(
          onTap: () => setState(() {
            _selectedDate = DateTime(_selectedDate.year, month, 1);
            _view = _AgendaView.month;
          }),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: tokens.bgSoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: tokens.borderSoft),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('MMM', 'pt_BR')
                      .format(DateTime(_selectedDate.year, month, 1))
                      .toUpperCase(),
                  style: TextStyle(
                    color: tokens.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Text(
                  '${monthEntries.length}',
                  style: TextStyle(
                    color: tokens.green,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  monthEntries.length == 1 ? 'evento' : 'eventos',
                  style: TextStyle(color: tokens.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _eventCard(dynamic tokens, _CalendarEntry entry, {bool dense = true}) {
    return GestureDetector(
      onTap: entry.agendamento == null
          ? null
          : () => AgendamentoSheet.show(
              context,
              tokens,
              agendamento: entry.agendamento,
            ),
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: dense ? 6 : 0),
        padding: EdgeInsets.all(dense ? 8 : 10),
        decoration: BoxDecoration(
          color: entry.color.withAlpha(entry.isGoogle ? 22 : 32),
          borderRadius: BorderRadius.circular(8),
          border: Border(left: BorderSide(color: entry.color, width: 4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${DateFormat('HH:mm').format(entry.start)} - ${DateFormat('HH:mm').format(entry.end)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: entry.color,
                fontWeight: FontWeight.w800,
                fontSize: dense ? 12 : 14,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '${entry.title}${entry.isGoogle ? '  Google' : ''}',
              maxLines: dense ? 1 : 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: tokens.text,
                fontWeight: FontWeight.w700,
                fontSize: dense ? 12 : 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(dynamic tokens, String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy, size: 48, color: tokens.text.withAlpha(50)),
            const SizedBox(height: 16),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(color: tokens.text.withAlpha(110)),
            ),
          ],
        ),
      ),
    );
  }

  List<_CalendarEntry> _entries(
    List<Agendamento> agendamentos,
    List<google.Event> googleEvents,
    dynamic tokens,
  ) {
    final internal = agendamentos
        .where((a) => a.status != 'cancelado')
        .map((a) => _fromAgendamento(a, tokens));
    final googleEntries = googleEvents.map(
      (event) => _fromGoogle(event, tokens),
    );
    return [...internal, ...googleEntries]
      ..sort((a, b) => a.start.compareTo(b.start));
  }

  _CalendarEntry _fromAgendamento(Agendamento a, dynamic tokens) {
    final serviceName = a.servicoNome ?? 'Servico';
    final color = _serviceColor(a.servicoId ?? serviceName, tokens);
    return _CalendarEntry(
      id: a.id,
      title: '$serviceName - ${a.clienteNome?.split(' ').first ?? 'Cliente'}',
      start: a.dataHoraInicio,
      end: a.dataHoraFim,
      color: color,
      legendLabel: serviceName,
      agendamento: a,
    );
  }

  _CalendarEntry _fromGoogle(google.Event event, dynamic tokens) {
    final start =
        event.start?.dateTime?.toLocal() ??
        event.start?.date?.toLocal() ??
        DateTime.now();
    final end =
        event.end?.dateTime?.toLocal() ??
        event.end?.date?.toLocal() ??
        start.add(const Duration(hours: 1));
    return _CalendarEntry(
      id: event.id ?? event.summary ?? start.toIso8601String(),
      title: event.summary?.trim().isNotEmpty == true
          ? event.summary!
          : 'Evento Google',
      start: start,
      end: end.isAfter(start) ? end : start.add(const Duration(hours: 1)),
      color: tokens.navy,
      legendLabel: 'Google Calendar',
      isGoogle: true,
    );
  }

  Color _serviceColor(String key, dynamic tokens) {
    final palette = [
      tokens.green,
      tokens.purple,
      tokens.orange,
      tokens.red,
      const Color(0xFF0891B2),
      const Color(0xFF2563EB),
    ];
    final hash = key.codeUnits.fold<int>(0, (sum, code) => sum + code);
    return palette[hash % palette.length];
  }

  List<_CalendarEntry> _forDay(List<_CalendarEntry> entries, DateTime day) {
    return entries.where((entry) => _isSameDay(entry.start, day)).toList();
  }

  List<_CalendarEntry> _visibleEntries(List<_CalendarEntry> entries) {
    return switch (_view) {
      _AgendaView.day => _forDay(entries, _selectedDate),
      _AgendaView.week =>
        entries
            .where(
              (entry) => _weekDays(
                _selectedDate,
              ).any((day) => _isSameDay(day, entry.start)),
            )
            .toList(),
      _AgendaView.month =>
        entries
            .where(
              (entry) =>
                  entry.start.year == _selectedDate.year &&
                  entry.start.month == _selectedDate.month,
            )
            .toList(),
      _AgendaView.year =>
        entries
            .where((entry) => entry.start.year == _selectedDate.year)
            .toList(),
    };
  }

  void _openNewAt(DateTime start) {
    AgendamentoSheet.show(
      context,
      context.read<BicoNotifier>().tokens,
      initialStart: start,
    );
  }

  DateTime _defaultNewStart() {
    final now = DateTime.now();
    final base = _isSameDay(_selectedDate, now)
        ? now
        : DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
            9,
          );
    final minutes = base.hour * 60 + base.minute;
    final rounded =
        ((minutes + _slotMinutes - 1) ~/ _slotMinutes) * _slotMinutes;
    final clamped = rounded.clamp(_hours.first * 60, _hours.last * 60);
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      clamped ~/ 60,
      clamped % 60,
    );
  }

  List<DateTime> _timeBlocksForDay(DateTime day) {
    final blocks = <DateTime>[];
    for (
      var minutes = _hours.first * 60;
      minutes <= _hours.last * 60;
      minutes += _slotMinutes
    ) {
      blocks.add(
        DateTime(day.year, day.month, day.day, minutes ~/ 60, minutes % 60),
      );
    }
    return blocks;
  }

  String _timeLabel(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  List<DateTime> _weekDays(DateTime date) {
    final start = date.subtract(Duration(days: date.weekday - 1));
    return List.generate(7, (i) => start.add(Duration(days: i)));
  }

  DateTime _shift(int direction) {
    switch (_view) {
      case _AgendaView.day:
        return _selectedDate.add(Duration(days: direction));
      case _AgendaView.week:
        return _selectedDate.add(Duration(days: direction * 7));
      case _AgendaView.month:
        return DateTime(_selectedDate.year, _selectedDate.month + direction, 1);
      case _AgendaView.year:
        return DateTime(_selectedDate.year + direction, 1, 1);
    }
  }

  String _title() {
    switch (_view) {
      case _AgendaView.day:
        return DateFormat('dd MMMM yyyy', 'pt_BR').format(_selectedDate);
      case _AgendaView.week:
        return 'Agenda semanal';
      case _AgendaView.month:
        return DateFormat('MMMM yyyy', 'pt_BR').format(_selectedDate);
      case _AgendaView.year:
        return '${_selectedDate.year}';
    }
  }

  String _periodLabel() {
    switch (_view) {
      case _AgendaView.day:
        return DateFormat('EEEE, dd/MM', 'pt_BR').format(_selectedDate);
      case _AgendaView.week:
        final days = _weekDays(_selectedDate);
        return '${DateFormat('dd/MM').format(days.first)} - ${DateFormat('dd/MM').format(days.last)}';
      case _AgendaView.month:
        return DateFormat('MMMM yyyy', 'pt_BR').format(_selectedDate);
      case _AgendaView.year:
        return '${_selectedDate.year}';
    }
  }

  String _subtitle(List<_CalendarEntry> entries) {
    final visible = switch (_view) {
      _AgendaView.day => _forDay(entries, _selectedDate).length,
      _AgendaView.week =>
        entries
            .where(
              (entry) => _weekDays(
                _selectedDate,
              ).any((day) => _isSameDay(day, entry.start)),
            )
            .length,
      _AgendaView.month =>
        entries
            .where(
              (entry) =>
                  entry.start.year == _selectedDate.year &&
                  entry.start.month == _selectedDate.month,
            )
            .length,
      _AgendaView.year =>
        entries.where((entry) => entry.start.year == _selectedDate.year).length,
    };
    return visible == 1 ? '1 evento' : '$visible eventos';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _CalendarEntry {
  final String id;
  final String title;
  final DateTime start;
  final DateTime end;
  final Color color;
  final String legendLabel;
  final bool isGoogle;
  final Agendamento? agendamento;

  const _CalendarEntry({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    required this.color,
    required this.legendLabel,
    this.isGoogle = false,
    this.agendamento,
  });
}
