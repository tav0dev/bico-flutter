class Agendamento {
  final String id;
  final String prestadorId;
  final String clienteId;
  final String? servicoId;
  final DateTime dataHoraInicio;
  final DateTime dataHoraFim;
  final String status; // pendente, confirmado, concluido, cancelado
  final int? precoCobradoCentavos;

  // Campos extras populados via JOIN do Supabase
  final String? clienteNome;
  final String? servicoNome;

  Agendamento({
    required this.id,
    required this.prestadorId,
    required this.clienteId,
    this.servicoId,
    required this.dataHoraInicio,
    required this.dataHoraFim,
    required this.status,
    this.precoCobradoCentavos,
    this.clienteNome,
    this.servicoNome,
  });

  factory Agendamento.fromJson(Map<String, dynamic> json) {
    // Tratando os Joins, se existirem na resposta
    String? cName;
    if (json['clientes'] != null && json['clientes'] is Map) {
      cName = json['clientes']['nome'];
    }

    String? sName;
    if (json['servicos'] != null && json['servicos'] is Map) {
      sName = json['servicos']['nome'];
    }

    return Agendamento(
      id: json['id'],
      prestadorId: json['prestador_id'],
      clienteId: json['cliente_id'],
      servicoId: json['servico_id'],
      dataHoraInicio: DateTime.parse(json['data_hora_inicio']).toLocal(),
      dataHoraFim: DateTime.parse(json['data_hora_fim']).toLocal(),
      status: json['status'] ?? 'pendente',
      precoCobradoCentavos: json['preco_cobrado_centavos'],
      clienteNome: cName,
      servicoNome: sName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'prestador_id': prestadorId,
      'cliente_id': clienteId,
      'servico_id': servicoId,
      'data_hora_inicio': dataHoraInicio.toUtc().toIso8601String(),
      'data_hora_fim': dataHoraFim.toUtc().toIso8601String(),
      'status': status,
      if (precoCobradoCentavos != null) 'preco_cobrado_centavos': precoCobradoCentavos,
    };
  }
}
