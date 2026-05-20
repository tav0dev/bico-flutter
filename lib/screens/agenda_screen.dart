import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/bicco_provider.dart';
import '../widgets/top_bar.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/ai_sparkle.dart';

class AgendaScreen extends StatefulWidget {
  final ValueChanged<NavTab>? onNavTap;
  const AgendaScreen({super.key, this.onNavTap});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  late DateTime _selectedDate;
  late List<DateTime> _weekDays;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _generateWeek(DateTime.now());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BiccoNotifier>().fetchGoogleEvents();
    });
  }

  void _generateWeek(DateTime date) {
    final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
    _weekDays = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));
  }

  static const _hours = [7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20];
  static const _hourHeight = 64.0;

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<BiccoNotifier>();
    final tokens = notifier.tokens;

    // LÓGICA DE FILTRAGEM ROBUSTA
    final dayEvents = notifier.googleEvents.where((e) {
      if (e.start?.dateTime != null) {
        final local = e.start!.dateTime!.toLocal();
        return local.day == _selectedDate.day && local.month == _selectedDate.month && local.year == _selectedDate.year;
      } else if (e.start?.date != null) {
        // Evento de dia inteiro: Comparar sem converter timezone
        // Google retorna data de dia inteiro como meia-noite UTC do dia
        final d = e.start!.date!;
        return d.day == _selectedDate.day && d.month == _selectedDate.month && d.year == _selectedDate.year;
      }
      return false;
    }).map((e) {
      DateTime start;
      DateTime end;
      bool isAllDay = e.start?.dateTime == null;

      if (isAllDay) {
        start = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 8, 0);
        end = start.add(const Duration(hours: 1));
      } else {
        start = e.start!.dateTime!.toLocal();
        end = (e.end?.dateTime ?? start.add(const Duration(hours: 1))).toLocal();
      }
      
      return (
        id: e.id ?? '',
        time: DateFormat('HH:mm').format(start),
        start: start,
        dur: end.difference(start).inMinutes / 60.0,
        title: e.summary ?? '(Sem título)',
        color: tokens.green,
        ai: e.description?.contains('AI') ?? false,
      );
    }).toList();

    // Remover duplicatas por ID (caso o evento venha de múltiplas agendas compartilhadas)
    final seen = <String>{};
    dayEvents.retainWhere((e) => seen.add(e.id));

    return Scaffold(
      backgroundColor: tokens.bg,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: BiccoTopBar(
              title: DateFormat('MMMM yyyy', 'pt_BR').format(_selectedDate).toUpperCase(),
              leading: IconButton(
                onPressed: () => notifier.fetchGoogleEvents(),
                icon: notifier.isLoadingEvents 
                  ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: tokens.text))
                  : Icon(Icons.refresh, size: 20, color: tokens.text),
              ),
              trailing: IconButton(
                onPressed: () {
                  if (notifier.isGoogleLoggedIn) {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: tokens.bg,
                        title: Text('Conta Google', style: TextStyle(color: tokens.text)),
                        content: Text('Deseja desconectar sua conta do Google Calendar?', style: TextStyle(color: tokens.text)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('CANCELAR')),
                          TextButton(
                            onPressed: () {
                              notifier.logoutGoogle();
                              Navigator.pop(ctx);
                            }, 
                            child: Text('LOGOUT', style: TextStyle(color: tokens.red))
                          ),
                        ],
                      ),
                    );
                  } else {
                    notifier.fetchGoogleEvents();
                  }
                },
                icon: Icon(
                  notifier.isGoogleLoggedIn ? Icons.account_circle : Icons.login, 
                  color: notifier.isGoogleLoggedIn ? tokens.green : tokens.textFaint
                ),
              ),
            ),
          ),

          // Seletor de Dias
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: List.generate(_weekDays.length, (i) {
                final dayDate = _weekDays[i];
                final isSelected = dayDate.day == _selectedDate.day && dayDate.month == _selectedDate.month;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedDate = dayDate),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? tokens.green : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(DateFormat('EEE', 'pt_BR').format(dayDate).toUpperCase(),
                            style: TextStyle(fontSize: 10, color: isSelected ? Colors.white : tokens.text.withAlpha(150))),
                          Text('${dayDate.day}',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : tokens.text)),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          Expanded(
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.only(left: 48, right: 12, bottom: 20),
                  child: SizedBox(
                    height: _hours.length * _hourHeight,
                    child: Stack(
                      children: [
                        // Linhas das Horas
                        ...List.generate(_hours.length, (i) => Positioned(
                          top: i * _hourHeight, left: 0, right: 0,
                          child: Container(height: _hourHeight, decoration: BoxDecoration(border: Border(top: BorderSide(color: tokens.borderSoft))))
                        )),
                        
                        // Labels das Horas
                        ...List.generate(_hours.length, (i) => Positioned(
                          top: i * _hourHeight - 8, left: -44, width: 40,
                          child: Text('${_hours[i]}:00', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, color: tokens.textFaint))
                        )),

                        // Linha do Horário Atual
                        if (_selectedDate.day == DateTime.now().day)
                          Positioned(
                            top: (DateTime.now().hour - 7) * _hourHeight + (DateTime.now().minute / 60.0) * _hourHeight,
                            left: 0, right: 0,
                            child: Container(height: 2, color: tokens.red),
                          ),

                        // Eventos
                        ...dayEvents.map((e) {
                          double top = (e.start.hour - 7) * _hourHeight + (e.start.minute / 60.0) * _hourHeight;
                          double height = (e.dur * _hourHeight) - 2;
                          if (top < 0) return const SizedBox();
                          
                          return Positioned(
                            top: top, left: 4, right: 4, height: height < 20 ? 20 : height,
                            child: Container(
                              decoration: BoxDecoration(
                                color: e.color.withAlpha(30),
                                border: Border(left: BorderSide(color: e.color, width: 4)),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              padding: const EdgeInsets.all(8),
                              child: Text(e.title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: tokens.text), overflow: TextOverflow.ellipsis),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),

                // MENSAGEM DE ERRO/AVISO (Aparece se não houver eventos)
                if (!notifier.isLoadingEvents && dayEvents.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.event_busy, size: 48, color: tokens.text.withAlpha(50)),
                          const SizedBox(height: 16),
                          Text(
                            notifier.googleEvents.isEmpty 
                                ? 'Nenhum evento carregado do Google.\nVerifique se você autorizou o login.' 
                                : 'Nenhum compromisso para este dia.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: tokens.text.withAlpha(100)),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          BiccoBottomNav(active: NavTab.agenda, onTap: widget.onNavTap),
        ],
      ),
    );
  }
}
