class Servico {
  final String id;
  final String prestadorId;
  final String nome;
  final String? descricao;
  final int precoCentavos;
  final int duracaoMinutos;
  final bool ativo;
  final int ordem;

  Servico({
    required this.id,
    required this.prestadorId,
    required this.nome,
    this.descricao,
    required this.precoCentavos,
    required this.duracaoMinutos,
    required this.ativo,
    required this.ordem,
  });

  factory Servico.fromJson(Map<String, dynamic> json) {
    return Servico(
      id: json['id'],
      prestadorId: json['prestador_id'],
      nome: json['nome'],
      descricao: json['descricao'],
      precoCentavos: json['preco_centavos'] ?? 0,
      duracaoMinutos: json['duracao_minutos'] ?? 0,
      ativo: json['ativo'] ?? true,
      ordem: json['ordem'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'prestador_id': prestadorId,
      'nome': nome,
      if (descricao != null) 'descricao': descricao,
      'preco_centavos': precoCentavos,
      'duracao_minutos': duracaoMinutos,
      'ativo': ativo,
      'ordem': ordem,
    };
  }
}
