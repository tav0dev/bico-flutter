import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bico_provider.dart';
import '../providers/clientes_provider.dart';
import '../models/cliente.dart';
import '../widgets/top_bar.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/avatar.dart';

class ClientsScreen extends StatefulWidget {
  final ValueChanged<NavTab>? onNavTap;

  const ClientsScreen({super.key, this.onNavTap});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  static const _stages = [
    (id: 'novo', label: 'Novo contato'),
    (id: 'conversa', label: 'Conversando'),
    (id: 'orcamento', label: 'Orcamento'),
    (id: 'fechado', label: 'Fechado'),
    (id: 'parado', label: 'Parado'),
  ];

  final _searchController = TextEditingController();
  String _query = '';
  String? _tagFilter;
  bool _pipelineMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientesProvider>().loadClientes();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<BicoNotifier>().tokens;
    final provider = context.watch<ClientesProvider>();
    final clientes = provider.clientes;
    final filtered = _filtered(clientes);
    final allTags = _allTags(clientes);

    return Scaffold(
      backgroundColor: tokens.bg,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: BicoTopBar(
              title: 'Contatos',
              subtitle: 'Clientes, leads e retornos em um lugar so',
              large: true,
              trailing: IconButton(
                tooltip: 'Novo contato',
                onPressed: () => _showClientSheet(context, tokens),
                icon: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: tokens.green,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
              ),
            ),
          ),
          _summary(tokens, clientes),
          _search(tokens),
          _modeSelector(tokens),
          if (allTags.isNotEmpty) _tagFilters(tokens, allTags),
          Expanded(
            child: provider.isLoading
                ? Center(child: CircularProgressIndicator(color: tokens.green))
                : filtered.isEmpty
                ? _emptyState(tokens)
                : _pipelineMode
                ? _pipeline(tokens, filtered)
                : _contactList(tokens, filtered, provider),
          ),
          SafeArea(
            top: false,
            child: BicoBottomNav(
              active: NavTab.clients,
              onTap: widget.onNavTap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summary(dynamic tokens, List<Cliente> clientes) {
    final emFechamento = clientes
        .where((c) => c.pipelineStatus == 'orcamento')
        .length;
    final fechados = clientes
        .where((c) => c.pipelineStatus == 'fechado')
        .length;
    final semContato = clientes.where((c) => !c.hasContactInfo).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Row(
        children: [
          _MetricBox(
            label: 'Contatos',
            value: clientes.length.toString(),
            helper: 'total',
          ),
          const SizedBox(width: 8),
          _MetricBox(
            label: 'Orcamentos',
            value: emFechamento.toString(),
            helper: 'em aberto',
          ),
          const SizedBox(width: 8),
          _MetricBox(
            label: 'Fechados',
            value: fechados.toString(),
            helper: semContato > 0 ? '$semContato sem telefone' : 'ativos',
          ),
        ],
      ),
    );
  }

  Widget _search(dynamic tokens) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: tokens.text, fontSize: 14),
        onChanged: (value) => setState(() => _query = value),
        decoration: InputDecoration(
          hintText: 'Buscar por nome, telefone, email ou tag',
          hintStyle: TextStyle(color: tokens.textMuted),
          prefixIcon: Icon(Icons.search, size: 18, color: tokens.textMuted),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Limpar busca',
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                  icon: Icon(Icons.close, size: 18, color: tokens.textMuted),
                ),
          filled: true,
          fillColor: tokens.bgSoft,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: tokens.borderSoft),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: tokens.borderSoft),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: tokens.green),
          ),
        ),
      ),
    );
  }

  Widget _modeSelector(dynamic tokens) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: tokens.bgSoft,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: tokens.borderSoft),
        ),
        child: Row(
          children: [
            _modeButton(tokens, false, 'Lista', Icons.list_alt_outlined),
            _modeButton(tokens, true, 'Pipeline', Icons.view_kanban_outlined),
          ],
        ),
      ),
    );
  }

  Widget _modeButton(dynamic tokens, bool mode, String label, IconData icon) {
    final selected = _pipelineMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _pipelineMode = mode),
        child: Container(
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? tokens.green : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? Colors.white : tokens.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : tokens.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tagFilters(dynamic tokens, List<String> tags) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final tag = tags[index];
          final selected = _tagFilter == tag;
          return GestureDetector(
            onTap: () => setState(() {
              _tagFilter = selected ? null : tag;
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: selected ? tokens.purple : tokens.bgSoft,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected ? tokens.purple : tokens.borderSoft,
                ),
              ),
              child: Text(
                '#$tag',
                style: TextStyle(
                  color: selected ? Colors.white : tokens.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        },
        separatorBuilder: (_, index) => const SizedBox(width: 6),
        itemCount: tags.length,
      ),
    );
  }

  Widget _contactList(
    dynamic tokens,
    List<Cliente> clientes,
    ClientesProvider provider,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
      itemCount: clientes.length,
      separatorBuilder: (_, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final cliente = clientes[index];
        return Dismissible(
          key: Key(cliente.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: tokens.red,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) => provider.deleteCliente(cliente.id),
          child: _ContactCard(
            cliente: cliente,
            onTap: () => _showClientSheet(context, tokens, cliente: cliente),
            onStageChanged: (status) => _updateStage(cliente, status),
          ),
        );
      },
    );
  }

  Widget _pipeline(dynamic tokens, List<Cliente> clientes) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
      scrollDirection: Axis.horizontal,
      itemCount: _stages.length,
      separatorBuilder: (_, index) => const SizedBox(width: 10),
      itemBuilder: (context, index) {
        final stage = _stages[index];
        final stageClientes = clientes
            .where((cliente) => cliente.pipelineStatus == stage.id)
            .toList();

        return SizedBox(
          width: 274,
          child: Container(
            decoration: BoxDecoration(
              color: tokens.bgSoft,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: tokens.borderSoft),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: Row(
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: _stageColor(tokens, stage.id),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          stage.label,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: tokens.text,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        stageClientes.length.toString(),
                        style: TextStyle(
                          color: tokens.textMuted,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(color: tokens.borderSoft, height: 1),
                Expanded(
                  child: stageClientes.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              'Sem contatos aqui',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: tokens.textFaint),
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(10),
                          itemCount: stageClientes.length,
                          separatorBuilder: (_, index) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final cliente = stageClientes[i];
                            return _PipelineCard(
                              cliente: cliente,
                              stageIndex: index,
                              onTap: () => _showClientSheet(
                                context,
                                tokens,
                                cliente: cliente,
                              ),
                              onMoveBack: index == 0
                                  ? null
                                  : () => _updateStage(
                                      cliente,
                                      _stages[index - 1].id,
                                    ),
                              onMoveForward: index == _stages.length - 1
                                  ? null
                                  : () => _updateStage(
                                      cliente,
                                      _stages[index + 1].id,
                                    ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _emptyState(dynamic tokens) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 44, color: tokens.textFaint),
            const SizedBox(height: 12),
            Text(
              'Nenhum contato encontrado.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: tokens.text,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Cadastre clientes, leads e pessoas para retorno.',
              textAlign: TextAlign.center,
              style: TextStyle(color: tokens.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: () => _showClientSheet(context, tokens),
              style: ElevatedButton.styleFrom(backgroundColor: tokens.green),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Novo contato',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClientSheet(
    BuildContext context,
    dynamic tokens, {
    Cliente? cliente,
  }) {
    final isEdit = cliente != null;
    final nomeController = TextEditingController(text: cliente?.nome ?? '');
    final telefoneController = TextEditingController(
      text: cliente?.telefone ?? '',
    );
    final emailController = TextEditingController(text: cliente?.email ?? '');
    final obsController = TextEditingController(
      text: cliente?.observacoes ?? '',
    );
    final tagController = TextEditingController();
    var selectedStatus = cliente?.pipelineStatus ?? 'novo';
    var selectedTags = [...?cliente?.tags];

    showModalBottomSheet(
      context: context,
      backgroundColor: tokens.bg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            void addTag(String value) {
              final tag = value.trim().toLowerCase().replaceAll(' ', '-');
              if (tag.isEmpty || selectedTags.contains(tag)) return;
              setSheetState(() {
                selectedTags.add(tag);
                tagController.clear();
              });
            }

            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                  left: 20,
                  right: 20,
                  top: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            isEdit ? 'Editar contato' : 'Novo contato',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: tokens.text,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: Icon(Icons.close, color: tokens.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nomeController,
                      style: TextStyle(color: tokens.text),
                      decoration: _inputDecoration(tokens, 'Nome'),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: telefoneController,
                            style: TextStyle(color: tokens.text),
                            keyboardType: TextInputType.phone,
                            decoration: _inputDecoration(
                              tokens,
                              'WhatsApp ou telefone',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: emailController,
                            style: TextStyle(color: tokens.text),
                            keyboardType: TextInputType.emailAddress,
                            decoration: _inputDecoration(tokens, 'Email'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SheetLabel('Etapa do fechamento', tokens: tokens),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _stages.map((stage) {
                        final selected = selectedStatus == stage.id;
                        return ChoiceChip(
                          label: Text(stage.label),
                          selected: selected,
                          onSelected: (_) =>
                              setSheetState(() => selectedStatus = stage.id),
                          selectedColor: _stageColor(tokens, stage.id),
                          backgroundColor: tokens.bgSoft,
                          labelStyle: TextStyle(
                            color: selected ? Colors.white : tokens.textMuted,
                            fontWeight: FontWeight.w700,
                          ),
                          side: BorderSide(color: tokens.borderSoft),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    _SheetLabel('Tags', tokens: tokens),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...selectedTags.map(
                          (tag) => InputChip(
                            label: Text('#$tag'),
                            onDeleted: () =>
                                setSheetState(() => selectedTags.remove(tag)),
                            backgroundColor: tokens.purpleSoft,
                            labelStyle: TextStyle(
                              color: tokens.purple,
                              fontWeight: FontWeight.w700,
                            ),
                            deleteIconColor: tokens.purple,
                          ),
                        ),
                        ...[
                              'vip',
                              'retorno',
                              'urgente',
                              'instagram',
                              'whatsapp',
                            ]
                            .where((tag) => !selectedTags.contains(tag))
                            .map(
                              (tag) => ActionChip(
                                label: Text('#$tag'),
                                onPressed: () => addTag(tag),
                                backgroundColor: tokens.bgSoft,
                                labelStyle: TextStyle(
                                  color: tokens.textMuted,
                                  fontWeight: FontWeight.w700,
                                ),
                                side: BorderSide(color: tokens.borderSoft),
                              ),
                            ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: tagController,
                      style: TextStyle(color: tokens.text),
                      textInputAction: TextInputAction.done,
                      onSubmitted: addTag,
                      decoration:
                          _inputDecoration(
                            tokens,
                            'Digite uma tag e aperte Enter',
                          ).copyWith(
                            suffixIcon: IconButton(
                              tooltip: 'Adicionar tag',
                              onPressed: () => addTag(tagController.text),
                              icon: Icon(Icons.add, color: tokens.green),
                            ),
                          ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: obsController,
                      style: TextStyle(color: tokens.text),
                      maxLines: 3,
                      decoration: _inputDecoration(tokens, 'Notas internas')
                          .copyWith(
                            hintText:
                                'Ex: pediu retorno sexta, prefere a tarde...',
                            hintStyle: TextStyle(color: tokens.textMuted),
                          ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: tokens.green,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          final name = nomeController.text.trim();
                          if (name.isEmpty) return;

                          final rawPhone = _normalizePhone(
                            telefoneController.text,
                          );
                          final rawEmail = emailController.text.trim().isEmpty
                              ? null
                              : emailController.text.trim();
                          final rawObs = obsController.text.trim().isEmpty
                              ? null
                              : obsController.text.trim();

                          final saved = Cliente(
                            id: cliente?.id ?? '',
                            prestadorId: cliente?.prestadorId ?? '',
                            nome: name,
                            telefone: rawPhone,
                            email: rawEmail,
                            observacoes: rawObs,
                            fotoPerfilUrl: cliente?.fotoPerfilUrl,
                            pipelineStatus: selectedStatus,
                            tags: selectedTags,
                          );

                          Navigator.pop(ctx);
                          if (isEdit) {
                            await context
                                .read<ClientesProvider>()
                                .updateCliente(saved);
                          } else {
                            await context.read<ClientesProvider>().addCliente(
                              saved,
                            );
                          }
                        },
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: const Text(
                          'Salvar contato',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration _inputDecoration(dynamic tokens, String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: tokens.textMuted),
      filled: true,
      fillColor: tokens.bgSoft,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: tokens.borderSoft),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: tokens.borderSoft),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: tokens.green),
      ),
    );
  }

  String? _normalizePhone(String value) {
    var raw = value.trim();
    if (raw.isEmpty) return null;
    raw = raw.replaceAll(RegExp(r'[^\d+]'), '');
    if (!raw.startsWith('+') && raw.isNotEmpty) raw = '+55$raw';
    return raw;
  }

  Future<void> _updateStage(Cliente cliente, String status) async {
    await context.read<ClientesProvider>().updateCliente(
      cliente.copyWith(pipelineStatus: status),
    );
  }

  List<Cliente> _filtered(List<Cliente> clientes) {
    final q = _query.trim().toLowerCase();
    return clientes.where((cliente) {
      final matchesTag =
          _tagFilter == null || cliente.tags.contains(_tagFilter);
      if (!matchesTag) return false;
      if (q.isEmpty) return true;
      final haystack = [
        cliente.nome,
        cliente.telefone ?? '',
        cliente.email ?? '',
        cliente.observacoes ?? '',
        cliente.pipelineStatus,
        ...cliente.tags,
      ].join(' ').toLowerCase();
      return haystack.contains(q);
    }).toList();
  }

  List<String> _allTags(List<Cliente> clientes) {
    return clientes.expand((cliente) => cliente.tags).toSet().toList()..sort();
  }

  Color _stageColor(dynamic tokens, String status) {
    return switch (status) {
      'novo' => tokens.textMuted,
      'conversa' => tokens.purple,
      'orcamento' => tokens.orange,
      'fechado' => tokens.green,
      'parado' => tokens.red,
      _ => tokens.textMuted,
    };
  }

  static String _stageLabel(String status) {
    return _stages
        .firstWhere((stage) => stage.id == status, orElse: () => _stages.first)
        .label;
  }
}

class _MetricBox extends StatelessWidget {
  final String label;
  final String value;
  final String helper;

  const _MetricBox({
    required this.label,
    required this.value,
    required this.helper,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<BicoNotifier>().tokens;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: tokens.bgSoft,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: tokens.borderSoft),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: tokens.text,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: tokens.text,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              helper,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: tokens.textMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final Cliente cliente;
  final VoidCallback? onTap;
  final ValueChanged<String> onStageChanged;

  const _ContactCard({
    required this.cliente,
    this.onTap,
    required this.onStageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<BicoNotifier>().tokens;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: tokens.bgSoft,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: tokens.borderSoft),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BicoAvatar(name: cliente.nome, size: 42),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          cliente.nome,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: tokens.text,
                          ),
                        ),
                      ),
                      _StagePill(status: cliente.pipelineStatus),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _contactLine(cliente),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, color: tokens.textMuted),
                  ),
                  if (cliente.tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: cliente.tags
                          .take(4)
                          .map((tag) => _TagChip(tag: tag))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _contactLine(Cliente cliente) {
    if (cliente.telefone?.isNotEmpty == true) return cliente.telefone!;
    if (cliente.email?.isNotEmpty == true) return cliente.email!;
    return 'Sem telefone ou email';
  }
}

class _PipelineCard extends StatelessWidget {
  final Cliente cliente;
  final int stageIndex;
  final VoidCallback? onTap;
  final VoidCallback? onMoveBack;
  final VoidCallback? onMoveForward;

  const _PipelineCard({
    required this.cliente,
    required this.stageIndex,
    this.onTap,
    this.onMoveBack,
    this.onMoveForward,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<BicoNotifier>().tokens;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: tokens.bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: tokens.borderSoft),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                BicoAvatar(name: cliente.nome, size: 32),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    cliente.nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: tokens.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              cliente.telefone ?? cliente.email ?? 'Sem contato',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: tokens.textMuted, fontSize: 12),
            ),
            if (cliente.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 5,
                runSpacing: 5,
                children: cliente.tags
                    .take(3)
                    .map((tag) => _TagChip(tag: tag, compact: true))
                    .toList(),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                _MoveButton(icon: Icons.chevron_left, onTap: onMoveBack),
                const Spacer(),
                _MoveButton(icon: Icons.chevron_right, onTap: onMoveForward),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MoveButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _MoveButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<BicoNotifier>().tokens;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: onTap == null ? Colors.transparent : tokens.bgSoft,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: tokens.borderSoft),
        ),
        child: Icon(
          icon,
          size: 18,
          color: onTap == null ? tokens.textFaint : tokens.textMuted,
        ),
      ),
    );
  }
}

class _StagePill extends StatelessWidget {
  final String status;

  const _StagePill({required this.status});

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<BicoNotifier>().tokens;
    final color = switch (status) {
      'novo' => tokens.textMuted,
      'conversa' => tokens.purple,
      'orcamento' => tokens.orange,
      'fechado' => tokens.green,
      'parado' => tokens.red,
      _ => tokens.textMuted,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _ClientsScreenState._stageLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String tag;
  final bool compact;

  const _TagChip({required this.tag, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<BicoNotifier>().tokens;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: tokens.purpleSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '#$tag',
        style: TextStyle(
          color: tokens.purple,
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SheetLabel extends StatelessWidget {
  final String text;
  final dynamic tokens;

  const _SheetLabel(this.text, {required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: tokens.text,
        fontSize: 13,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
