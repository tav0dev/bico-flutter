class Cliente {
  final String id;
  final String prestadorId;
  final String nome;
  final String? telefone;
  final String? email;
  final String? fotoPerfilUrl;
  final String? observacoes;

  Cliente({
    required this.id,
    required this.prestadorId,
    required this.nome,
    this.telefone,
    this.email,
    this.fotoPerfilUrl,
    this.observacoes,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: json['id'],
      prestadorId: json['prestador_id'],
      nome: json['nome'],
      telefone: json['telefone'],
      email: json['email'],
      fotoPerfilUrl: json['foto_perfil_url'],
      observacoes: json['observacoes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'prestador_id': prestadorId,
      'nome': nome,
      if (telefone != null) 'telefone': telefone,
      if (email != null) 'email': email,
      if (fotoPerfilUrl != null) 'foto_perfil_url': fotoPerfilUrl,
      if (observacoes != null) 'observacoes': observacoes,
    };
  }
}
