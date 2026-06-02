import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/bico_provider.dart';
import '../providers/clientes_provider.dart';
import '../providers/servicos_provider.dart';
import '../providers/agendamentos_provider.dart';
import '../models/cliente.dart';
import '../models/servico.dart';
import '../models/agendamento.dart';
import '../widgets/bico_button.dart';

class AgendamentoSheet extends StatefulWidget {
  final dynamic tokens;
  final Agendamento? agendamento;

  const AgendamentoSheet({super.key, required this.tokens, this.agendamento});

  static void show(BuildContext context, dynamic tokens, {Agendamento? agendamento}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: tokens.bg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AgendamentoSheet(tokens: tokens, agendamento: agendamento),
    );
  }

  @override
  State<AgendamentoSheet> createState() => _AgendamentoSheetState();
}

  Cliente? _selectedCliente;
  Servico? _selectedServico;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.agendamento != null) {
      _selectedDate = widget.agendamento!.dataHoraInicio;
      _selectedTime = TimeOfDay.fromDateTime(widget.agendamento!.dataHoraInicio);
      
      // We will need to set _selectedCliente and _selectedServico in build() or after provider loads
      // because they require the lists from the providers.
    }
  }

  void _save(BuildContext context) async {
    if (_selectedCliente == null || _selectedDate == null || _selectedTime == null) return;

    setState(() => _isLoading = true);

    final startDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    // Duração padrão 60 min se não houver serviço selecionado
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
      precoCobradoCentavos: _selectedServico?.precoCentavos ?? widget.agendamento?.precoCobradoCentavos,
    );

    if (isEdit) {
      await context.read<AgendamentosProvider>().updateAgendamento(agendamento);
    } else {
      await context.read<AgendamentosProvider>().addAgendamento(agendamento);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _delete(BuildContext context) async {
    if (widget.agendamento == null) return;
    setState(() => _isLoading = true);
    await context.read<AgendamentosProvider>().deleteAgendamento(widget.agendamento!.id);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;
    final clientesProvider = context.watch<ClientesProvider>();
    final servicosProvider = context.watch<ServicosProvider>();
    
    final clientes = clientesProvider.clientes;
    final servicos = servicosProvider.servicos.where((s) => s.ativo).toList();

    if (widget.agendamento != null && _selectedCliente == null) {
      try {
        _selectedCliente = clientes.firstWhere((c) => c.id == widget.agendamento!.clienteId);
      } catch (_) {}
    }
    
    if (widget.agendamento != null && widget.agendamento!.servicoId != null && _selectedServico == null) {
      try {
        _selectedServico = servicos.firstWhere((s) => s.id == widget.agendamento!.servicoId);
      } catch (_) {}
    }

    final isEdit = widget.agendamento != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20, right: 20, top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(isEdit ? 'Editar Agendamento' : 'Novo Agendamento', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: tokens.text)),
              if (isEdit)
                IconButton(
                  onPressed: () => _delete(context),
                  icon: Icon(Icons.delete_outline, color: tokens.red),
                ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Cliente
          Text('Cliente', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tokens.textMuted)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: tokens.borderSoft),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Cliente>(
                value: _selectedCliente,
                hint: Text('Selecione um cliente', style: TextStyle(color: tokens.textMuted)),
                isExpanded: true,
                dropdownColor: tokens.bg,
                style: TextStyle(color: tokens.text),
                items: clientes.map((c) => DropdownMenuItem(
                  value: c,
                  child: Text(c.nome),
                )).toList(),
                onChanged: (val) => setState(() => _selectedCliente = val),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Serviço (Opcional)
          Text('Serviço (Opcional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tokens.textMuted)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: tokens.borderSoft),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Servico>(
                value: _selectedServico,
                hint: Text('Selecione um serviço', style: TextStyle(color: tokens.textMuted)),
                isExpanded: true,
                dropdownColor: tokens.bg,
                style: TextStyle(color: tokens.text),
                items: servicos.map((s) => DropdownMenuItem(
                  value: s,
                  child: Text(s.nome),
                )).toList(),
                onChanged: (val) => setState(() => _selectedServico = val),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Data e Hora
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Data', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tokens.textMuted)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now().subtract(const Duration(days: 30)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) setState(() => _selectedDate = date);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: tokens.borderSoft),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _selectedDate == null ? 'Escolher data' : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                          style: TextStyle(color: _selectedDate == null ? tokens.textMuted : tokens.text),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Horário', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tokens.textMuted)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) setState(() => _selectedTime = time);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: tokens.borderSoft),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _selectedTime == null ? '00:00' : _selectedTime!.format(context),
                          style: TextStyle(color: _selectedTime == null ? tokens.textMuted : tokens.text),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: (_selectedCliente != null && _selectedDate != null && _selectedTime != null) 
                    ? () => _save(context) 
                    : null,
                  child: Text(isEdit ? 'Salvar Alterações' : 'Confirmar Agendamento', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
