class Cliente {
  final String id;
  final String prestadorId;
  final String nome;
  final String? telefone;
  final String? email;
  final String? fotoPerfilUrl;
  final String? observacoes;
  final String pipelineStatus;
  final List<String> tags;

  Cliente({
    required this.id,
    required this.prestadorId,
    required this.nome,
    this.telefone,
    this.email,
    this.fotoPerfilUrl,
    this.observacoes,
    this.pipelineStatus = 'novo',
    this.tags = const [],
  });

  factory Cliente.fromJson(Map<String, dynamic> json) {
    final rawObservacoes = json['observacoes'] as String?;
    return Cliente(
      id: json['id'],
      prestadorId: json['prestador_id'],
      nome: json['nome'],
      telefone: json['telefone'],
      email: json['email'],
      fotoPerfilUrl: json['foto_perfil_url'],
      observacoes: _stripCrmMeta(rawObservacoes),
      pipelineStatus: _parseStatus(rawObservacoes),
      tags: _parseTags(rawObservacoes),
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
      'observacoes': _composeObservacoes(observacoes, pipelineStatus, tags),
    };
  }

  Cliente copyWith({
    String? id,
    String? prestadorId,
    String? nome,
    String? telefone,
    String? email,
    String? fotoPerfilUrl,
    String? observacoes,
    String? pipelineStatus,
    List<String>? tags,
  }) {
    return Cliente(
      id: id ?? this.id,
      prestadorId: prestadorId ?? this.prestadorId,
      nome: nome ?? this.nome,
      telefone: telefone ?? this.telefone,
      email: email ?? this.email,
      fotoPerfilUrl: fotoPerfilUrl ?? this.fotoPerfilUrl,
      observacoes: observacoes ?? this.observacoes,
      pipelineStatus: pipelineStatus ?? this.pipelineStatus,
      tags: tags ?? this.tags,
    );
  }

  bool get hasContactInfo =>
      (telefone?.trim().isNotEmpty ?? false) ||
      (email?.trim().isNotEmpty ?? false);

  static const _crmMarker = '[[bico_crm]]';

  static String? _stripCrmMeta(String? raw) {
    if (raw == null) return null;
    final markerIndex = raw.indexOf(_crmMarker);
    final clean = markerIndex >= 0 ? raw.substring(0, markerIndex) : raw;
    final trimmed = clean.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String _parseStatus(String? raw) {
    final value = _metaValue(raw, 'status')?.trim();
    if (value == null || value.isEmpty) return 'novo';
    return value;
  }

  static List<String> _parseTags(String? raw) {
    final value = _metaValue(raw, 'tags');
    if (value == null || value.trim().isEmpty) return const [];
    return value
        .split(',')
        .map((tag) => tag.trim().toLowerCase())
        .where((tag) => tag.isNotEmpty)
        .toSet()
        .toList();
  }

  static String? _metaValue(String? raw, String key) {
    if (raw == null || !raw.contains(_crmMarker)) return null;
    final lines = raw.substring(raw.indexOf(_crmMarker)).split('\n');
    final prefix = '$key=';
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith(prefix)) {
        return trimmed.substring(prefix.length);
      }
    }
    return null;
  }

  static String _composeObservacoes(
    String? observacoes,
    String pipelineStatus,
    List<String> tags,
  ) {
    final clean = observacoes?.trim();
    final normalizedTags = tags
        .map((tag) => tag.trim().toLowerCase())
        .where((tag) => tag.isNotEmpty)
        .toSet()
        .join(',');

    return [
      if (clean != null && clean.isNotEmpty) clean,
      _crmMarker,
      'status=$pipelineStatus',
      'tags=$normalizedTags',
    ].join('\n');
  }
}
