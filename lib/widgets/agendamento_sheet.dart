import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/agendamento.dart';
import '../models/cliente.dart';
import '../models/servico.dart';
import '../providers/agendamentos_provider.dart';
import '../providers/bico_provider.dart';
import '../providers/clientes_provider.dart';
import '../providers/servicos_provider.dart';

class AgendamentoSheet extends StatefulWidget {
  final dynamic tokens;
  final Agendamento? agendamento;
  final DateTime? initialStart;

  const AgendamentoSheet({
    super.key,
    required this.tokens,
    this.agendamento,
    this.initialStart,
  });

  static void show(
    BuildContext context,
    dynamic tokens, {
    Agendamento? agendamento,
    DateTime? initialStart,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: tokens.bg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AgendamentoSheet(
        tokens: tokens,
        agendamento: agendamento,
        initialStart: initialStart,
      ),
    );
  }

  @override
  State<AgendamentoSheet> createState() => _AgendamentoSheetState();
}

class _AgendamentoSheetState extends State<AgendamentoSheet> {
  static const _slotMinutes = 30;
  static const _startHour = 7;
  static const _endHour = 20;

  Cliente? _selectedCliente;
  Servico? _selectedServico;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.agendamento?.dataHoraInicio ?? widget.initialStart;
    if (initial != null) {
      _selectedDate = DateTime(initial.year, initial.month, initial.day);
      _selectedTime = TimeOfDay.fromDateTime(initial);
    }
  }

  Future<void> _save(BuildContext context) async {
    if (_selectedCliente == null ||
        _selectedDate == null ||
        _selectedTime == null) {
      return;
    }

    setState(() => _isLoading = true);

    final startDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
    final duration = _selectedServico?.duracaoMinutos ?? 60;
    final endDateTime = startDateTime.add(Duration(minutes: duration));
    final isEdit = widget.agendamento != null;

    final agendamento = Agendamento(
      id: isEdit ? widget.agendamento!.id : '',
      prestadorId: isEdit ? widget.agendamento!.prestadorId : '',
      clienteId: _selectedCliente!.id,
      servicoId: _selectedServico?.id,
      dataHoraInicio: startDateTime,
      dataHoraFim: endDateTime,
      status: isEdit ? widget.agendamento!.status : 'confirmado',
      precoCobradoCentavos:
          _selectedServico?.precoCentavos ??
          widget.agendamento?.precoCobradoCentavos,
    );

    if (isEdit) {
      await context.read<AgendamentosProvider>().updateAgendamento(agendamento);
    } else {
      await context.read<AgendamentosProvider>().addAgendamento(agendamento);
    }

    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete(BuildContext context) async {
    if (widget.agendamento == null) return;
    setState(() => _isLoading = true);
    await context.read<AgendamentosProvider>().deleteAgendamento(
      widget.agendamento!.id,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;
    final clientes = context
        .watch<ClientesProvider>()
        .clientes
        .where((c) => c.id.isNotEmpty)
        .toList();
    final seenClienteIds = <String>{};
    clientes.removeWhere((c) => !seenClienteIds.add(c.id));
    if (_selectedCliente != null &&
        !clientes.any((c) => c.id == _selectedCliente!.id)) {
      _selectedCliente = null;
    }
    final agendamentosProvider = context.watch<AgendamentosProvider>();
    final googleEvents = context.watch<BicoNotifier>().googleEvents;
    final servicos = context
        .watch<ServicosProvider>()
        .servicos
        .where((s) => s.ativo && s.id.isNotEmpty)
        .toList();
    final seenServicoIds = <String>{};
    servicos.removeWhere((s) => !seenServicoIds.add(s.id));
    if (_selectedServico != null &&
        !servicos.any((s) => s.id == _selectedServico!.id)) {
      _selectedServico = null;
    }
    final isEdit = widget.agendamento != null;

    if (isEdit && _selectedCliente == null) {
      try {
        _selectedCliente = clientes.firstWhere(
          (c) => c.id == widget.agendamento!.clienteId,
        );
      } catch (_) {}
    }
    if (isEdit &&
        widget.agendamento!.servicoId != null &&
        _selectedServico == null) {
      try {
        _selectedServico = servicos.firstWhere(
          (s) => s.id == widget.agendamento!.servicoId,
        );
      } catch (_) {}
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.86,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEdit ? 'Editar agendamento' : 'Novo agendamento',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: tokens.text,
                    ),
                  ),
                  if (isEdit)
                    IconButton(
                      onPressed: () => _delete(context),
                      icon: Icon(Icons.delete_outline, color: tokens.red),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              _dropdown<String>(
                tokens: tokens,
                label: 'Cliente',
                value: _selectedCliente?.id,
                hint: 'Selecione um cliente',
                items: clientes.map((cliente) => cliente.id).toList(),
                labelFor: (id) => _clienteById(clientes, id)?.nome ?? 'Cliente',
                onChanged: (value) => setState(
                  () => _selectedCliente = _clienteById(clientes, value),
                ),
              ),
              const SizedBox(height: 16),
              _dropdown<String>(
                tokens: tokens,
                label: 'Servico',
                value: _selectedServico?.id,
                hint: 'Selecione um servico',
                items: servicos.map((servico) => servico.id).toList(),
                labelFor: (id) =>
                    _servicoById(servicos, id)?.nome ?? 'Servico',
                onChanged: (value) => setState(() {
                  _selectedServico = _servicoById(servicos, value);
                  if (_selectedTime != null &&
                      !_isSlotAvailable(
                        _selectedTime!,
                        agendamentosProvider.agendamentos,
                        googleEvents,
                      )) {
                    _selectedTime = null;
                  }
                }),
              ),
              const SizedBox(height: 16),
              Text(
                'Data',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: tokens.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? DateTime.now(),
                    firstDate: DateTime.now().subtract(
                      const Duration(days: 30),
                    ),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() {
                      _selectedDate = date;
                      if (_selectedTime != null &&
                          !_isSlotAvailable(
                            _selectedTime!,
                            agendamentosProvider.agendamentos,
                            googleEvents,
                          )) {
                        _selectedTime = null;
                      }
                    });
                  }
                },
                child: _fieldShell(
                  tokens,
                  Text(
                    _selectedDate == null
                        ? 'Escolher data'
                        : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                    style: TextStyle(
                      color: _selectedDate == null
                          ? tokens.textMuted
                          : tokens.text,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Bloco de tempo',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: tokens.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _availabilityHint(),
                style: TextStyle(
                  color: tokens.textMuted,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _timeBlocks().map((time) {
                  final selected =
                      _selectedTime?.hour == time.hour &&
                      _selectedTime?.minute == time.minute;
                  final available = _isSlotAvailable(
                    time,
                    agendamentosProvider.agendamentos,
                    googleEvents,
                  );
                  final activeSelected = selected && available;
                  return GestureDetector(
                    onTap: available
                        ? () => setState(() => _selectedTime = time)
                        : null,
                    child: Container(
                      width: 72,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: activeSelected
                            ? tokens.green
                            : available
                            ? tokens.bgSoft
                            : tokens.bgSoft.withAlpha(70),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: activeSelected
                              ? tokens.green
                              : available
                              ? tokens.borderSoft
                              : tokens.borderSoft.withAlpha(90),
                        ),
                      ),
                      child: Text(
                        _formatTimeBlock(time),
                        style: TextStyle(
                          color: activeSelected
                              ? Colors.white
                              : available
                              ? tokens.text
                              : tokens.textFaint,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: tokens.green,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed:
                            (_selectedCliente != null &&
                                _selectedDate != null &&
                                _selectedTime != null &&
                                _isSlotAvailable(
                                  _selectedTime!,
                                  agendamentosProvider.agendamentos,
                                  googleEvents,
                                ))
                            ? () => _save(context)
                            : null,
                        child: Text(
                          isEdit
                              ? 'Salvar alteracoes'
                              : 'Confirmar agendamento',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dropdown<T>({
    required dynamic tokens,
    required String label,
    required T? value,
    required String hint,
    required List<T> items,
    required String Function(T item) labelFor,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: tokens.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: tokens.borderSoft),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              hint: Text(hint, style: TextStyle(color: tokens.textMuted)),
              isExpanded: true,
              dropdownColor: tokens.bg,
              style: TextStyle(color: tokens.text),
              items: items
                  .map(
                    (item) => DropdownMenuItem(
                      value: item,
                      child: Text(labelFor(item)),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _fieldShell(dynamic tokens, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(color: tokens.borderSoft),
        borderRadius: BorderRadius.circular(10),
      ),
      child: child,
    );
  }

  Servico? _servicoById(List<Servico> servicos, String? id) {
    if (id == null) return null;
    for (final servico in servicos) {
      if (servico.id == id) return servico;
    }
    return null;
  }

  Cliente? _clienteById(List<Cliente> clientes, String? id) {
    if (id == null) return null;
    for (final cliente in clientes) {
      if (cliente.id == id) return cliente;
    }
    return null;
  }

  List<TimeOfDay> _timeBlocks() {
    final blocks = <TimeOfDay>[];
    for (
      var minutes = _startHour * 60;
      minutes <= _endHour * 60;
      minutes += _slotMinutes
    ) {
      blocks.add(TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60));
    }
    return blocks;
  }

  bool _isSlotAvailable(
    TimeOfDay time,
    List<Agendamento> agendamentos,
    List<dynamic> googleEvents,
  ) {
    if (_selectedDate == null) return false;

    final start = _dateTimeFor(time);
    final end = start.add(Duration(minutes: _selectedDurationMinutes));
    final workdayEnd = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _endHour,
    );

    if (end.isAfter(workdayEnd)) return false;

    final currentId = widget.agendamento?.id;
    final hasInternalConflict = agendamentos.any((agendamento) {
      if (agendamento.id == currentId || agendamento.status == 'cancelado') {
        return false;
      }
      return _overlaps(
        start,
        end,
        agendamento.dataHoraInicio,
        agendamento.dataHoraFim,
      );
    });
    if (hasInternalConflict) return false;

    return !googleEvents.any((event) {
      final eventStart =
          event.start?.dateTime?.toLocal() ?? event.start?.date?.toLocal();
      final eventEnd =
          event.end?.dateTime?.toLocal() ??
          event.end?.date?.toLocal() ??
          eventStart?.add(const Duration(hours: 1));
      if (eventStart == null || eventEnd == null) return false;
      return _overlaps(start, end, eventStart, eventEnd);
    });
  }

  DateTime _dateTimeFor(TimeOfDay time) {
    return DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      time.hour,
      time.minute,
    );
  }

  bool _overlaps(
    DateTime start,
    DateTime end,
    DateTime reservedStart,
    DateTime reservedEnd,
  ) {
    return start.isBefore(reservedEnd) && end.isAfter(reservedStart);
  }

  int get _selectedDurationMinutes {
    if (_selectedServico != null && _selectedServico!.duracaoMinutos > 0) {
      return _selectedServico!.duracaoMinutos;
    }
    if (widget.agendamento != null) {
      return widget.agendamento!.dataHoraFim
          .difference(widget.agendamento!.dataHoraInicio)
          .inMinutes;
    }
    return 60;
  }

  String _availabilityHint() {
    final duration = _durationLabel(_selectedDurationMinutes);
    final serviceName = _selectedServico?.nome;
    if (_selectedDate == null) {
      return 'Escolha a data para ver os blocos livres.';
    }
    if (serviceName == null) {
      return 'Sem servico selecionado, estou considerando $duration.';
    }
    return '$serviceName dura $duration. Horarios em cinza nao cabem ou ja estao reservados.';
  }

  String _durationLabel(int minutes) {
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    final hourText = hours == 1 ? '1 hora' : '$hours horas';
    if (rest == 0) return hourText;
    return '$hourText e $rest min';
  }

  String _formatTimeBlock(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
