import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/servico.dart';
import '../providers/bico_provider.dart';
import '../providers/servicos_provider.dart';
import '../widgets/bico_card.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/toggle.dart';
import '../widgets/top_bar.dart';

class ServicesScreen extends StatefulWidget {
  final ValueChanged<NavTab>? onNavTap;
  const ServicesScreen({super.key, this.onNavTap});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  static const _durationOptions = [
    30,
    60,
    90,
    120,
    150,
    180,
    240,
    300,
    360,
    480,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ServicosProvider>().loadServicos();
    });
  }

  void _showServiceSheet(
    BuildContext context,
    dynamic tokens, {
    Servico? servico,
  }) {
    final isEdit = servico != null;
    final nomeController = TextEditingController(text: servico?.nome ?? '');
    final precoController = TextEditingController(
      text: isEdit
          ? (servico.precoCentavos / 100)
                .toStringAsFixed(2)
                .replaceAll('.', ',')
          : '',
    );
    var selectedDuration = _durationForService(servico);

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
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEdit ? 'Editar servico' : 'Novo servico',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: tokens.text,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nomeController,
                    style: TextStyle(color: tokens.text),
                    decoration: InputDecoration(
                      labelText: 'Nome do servico',
                      labelStyle: TextStyle(color: tokens.textMuted),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: precoController,
                    style: TextStyle(color: tokens.text),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Preco (R\$)',
                      labelStyle: TextStyle(color: tokens.textMuted),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Duracao do servico',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: tokens.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _durationOptions.map((minutes) {
                      final selected = selectedDuration == minutes;
                      return GestureDetector(
                        onTap: () =>
                            setSheetState(() => selectedDuration = minutes),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: selected ? tokens.green : tokens.bgSoft,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: selected ? tokens.green : tokens.border,
                            ),
                          ),
                          child: Text(
                            _durationLabel(minutes),
                            style: TextStyle(
                              color: selected ? Colors.white : tokens.text,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tokens.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        if (nomeController.text.trim().isEmpty ||
                            precoController.text.trim().isEmpty) {
                          return;
                        }

                        final price =
                            (double.parse(
                                      precoController.text.replaceAll(',', '.'),
                                    ) *
                                    100)
                                .toInt();

                        if (isEdit) {
                          final updated = Servico(
                            id: servico.id,
                            prestadorId: servico.prestadorId,
                            nome: nomeController.text.trim(),
                            descricao: servico.descricao,
                            precoCentavos: price,
                            duracaoMinutos: selectedDuration,
                            ativo: servico.ativo,
                            ordem: servico.ordem,
                          );
                          Navigator.pop(ctx);
                          await context.read<ServicosProvider>().updateServico(
                            updated,
                          );
                        } else {
                          final novo = Servico(
                            id: '',
                            prestadorId: '',
                            nome: nomeController.text.trim(),
                            precoCentavos: price,
                            duracaoMinutos: selectedDuration,
                            ativo: true,
                            ordem: 0,
                          );
                          Navigator.pop(ctx);
                          await context.read<ServicosProvider>().addServico(
                            novo,
                          );
                        }
                      },
                      child: const Text(
                        'Salvar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  int _durationForService(Servico? servico) {
    final value = servico?.duracaoMinutos ?? 60;
    if (_durationOptions.contains(value)) return value;
    final rounded = ((value + 29) ~/ 30) * 30;
    return _durationOptions.firstWhere(
      (option) => option >= rounded,
      orElse: () => _durationOptions.last,
    );
  }

  String _durationLabel(int minutes) {
    if (minutes == 30) return '30 min';
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    final hourText = hours == 1 ? '1 hora' : '$hours horas';
    if (rest == 0) return hourText;
    if (rest == 30) return '$hourText e meia';
    return '$hourText e $rest min';
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<BicoNotifier>().tokens;
    final servicosProvider = context.watch<ServicosProvider>();
    final servicos = servicosProvider.servicos;
    final activeCount = servicos.where((s) => s.ativo).length;

    return Scaffold(
      backgroundColor: tokens.bg,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: BicoTopBar(
              title: 'Servicos',
              large: true,
              trailing: GestureDetector(
                onTap: () => _showServiceSheet(context, tokens),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: tokens.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '$activeCount servicos ativos',
                style: TextStyle(fontSize: 14, color: tokens.textMuted),
              ),
            ),
          ),
          Expanded(
            child: servicosProvider.isLoading
                ? Center(child: CircularProgressIndicator(color: tokens.green))
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    children: [
                      ...servicos.map((servico) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Dismissible(
                            key: Key(servico.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: tokens.red,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            onDismissed: (_) {
                              servicosProvider.deleteServico(servico.id);
                            },
                            child: GestureDetector(
                              onTap: () => _showServiceSheet(
                                context,
                                tokens,
                                servico: servico,
                              ),
                              child: BicoCard(
                                padding: EdgeInsets.zero,
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: servico.ativo
                                              ? tokens.greenSoft
                                              : tokens.borderSoft,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.access_time,
                                          size: 20,
                                          color: servico.ativo
                                              ? tokens.green
                                              : tokens.textMuted,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              servico.nome,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: tokens.text,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.grid_view,
                                                  size: 12,
                                                  color: tokens.textMuted,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  _durationLabel(
                                                    servico.duracaoMinutos,
                                                  ),
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: tokens.textMuted,
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Text(
                                                  'R\$ ${(servico.precoCentavos / 100).toStringAsFixed(2).replaceAll(".", ",")}',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: tokens.text,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      GestureDetector(
                                        onTap: () {
                                          servicosProvider.toggleAtivo(
                                            servico.id,
                                            servico.ativo,
                                          );
                                        },
                                        child: BicoToggle(on: servico.ativo),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      GestureDetector(
                        onTap: () => _showServiceSheet(context, tokens),
                        child: Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            border: Border.all(color: tokens.border),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add,
                                size: 16,
                                color: tokens.textMuted,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Cadastrar novo servico',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: tokens.textMuted,
                                ),
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
            child: BicoBottomNav(
              active: NavTab.services,
              onTap: widget.onNavTap,
            ),
          ),
        ],
      ),
    );
  }
}
