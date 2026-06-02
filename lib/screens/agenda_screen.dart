import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/bico_provider.dart';
import '../providers/agendamentos_provider.dart';
import '../widgets/top_bar.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/agendamento_sheet.dart';

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
      context.read<AgendamentosProvider>().loadAgendamentos();
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
    final tokens = context.watch<BicoNotifier>().tokens;
    final agendamentosProvider = context.watch<AgendamentosProvider>();

    // Filtrar os agendamentos do Supabase para o dia selecionado
    final dayEvents = agendamentosProvider.agendamentos.where((a) {
      final local = a.dataHoraInicio;
      return local.day == _selectedDate.day && 
             local.month == _selectedDate.month && 
             local.year == _selectedDate.year && 
             a.status != 'cancelado';
    }).map((a) {
      final start = a.dataHoraInicio;
      final end = a.dataHoraFim;
      
      Color color;
      if (a.status == 'concluido') color = tokens.green;
      else if (a.status == 'confirmado') color = tokens.purple;
      else color = tokens.orange; // Pendente
      
      return (
        id: a.id,
        agendamento: a,
        time: DateFormat('HH:mm').format(start),
        start: start,
        dur: end.difference(start).inMinutes / 60.0,
        title: '${a.servicoNome ?? 'Serviço'} • ${a.clienteNome?.split(' ').first ?? 'Cliente'}',
        color: color,
      );
    }).toList();

    return Scaffold(
      backgroundColor: tokens.bg,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: BicoTopBar(
              title: DateFormat('MMMM yyyy', 'pt_BR').format(_selectedDate).toUpperCase(),
              leading: IconButton(
                onPressed: () => agendamentosProvider.loadAgendamentos(),
                icon: agendamentosProvider.isLoading 
                  ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: tokens.text))
                  : Icon(Icons.refresh, size: 20, color: tokens.text),
              ),
              trailing: const SizedBox(width: 48), // Espaço vazio para alinhar o título ao centro
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
                        if (_selectedDate.day == DateTime.now().day && _selectedDate.month == DateTime.now().month)
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
                            child: GestureDetector(
                              onTap: () {
                                AgendamentoSheet.show(context, tokens, agendamento: e.agendamento);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: e.color.withAlpha(30),
                                  border: Border(left: BorderSide(color: e.color, width: 4)),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                padding: const EdgeInsets.all(8),
                                child: Text(e.title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: tokens.text), overflow: TextOverflow.ellipsis),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),

                // MENSAGEM DE ERRO/AVISO (Aparece se não houver eventos)
                if (!agendamentosProvider.isLoading && dayEvents.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.event_busy, size: 48, color: tokens.text.withAlpha(50)),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhum agendamento para este dia.',
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
          SafeArea(
            top: false,
            child: BicoBottomNav(active: NavTab.agenda, onTap: widget.onNavTap),
          ),
        ],
      ),
    );
  }
}
