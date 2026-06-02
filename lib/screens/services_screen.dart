import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/bico_provider.dart';
import '../providers/servicos_provider.dart';
import '../models/servico.dart';
import '../widgets/top_bar.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/bico_card.dart';
import '../widgets/pill.dart';
import '../widgets/toggle.dart';

class ServicesScreen extends StatefulWidget {
  final ValueChanged<NavTab>? onNavTap;
  const ServicesScreen({super.key, this.onNavTap});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ServicosProvider>().loadServicos();
    });
  }

  void _showServiceSheet(BuildContext context, dynamic tokens, {Servico? servico}) {
    final isEdit = servico != null;
    final nomeController = TextEditingController(text: servico?.nome ?? '');
    final precoController = TextEditingController(
      text: isEdit ? (servico.precoCentavos / 100).toStringAsFixed(2).replaceAll('.', ',') : ''
    );
    final duracaoController = TextEditingController(
      text: isEdit ? servico.duracaoMinutos.toString() : ''
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: tokens.bg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20, right: 20, top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isEdit ? 'Editar Serviço' : 'Novo Serviço', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: tokens.text)),
              const SizedBox(height: 16),
              TextField(
                controller: nomeController,
                style: TextStyle(color: tokens.text),
                decoration: InputDecoration(
                  labelText: 'Nome do serviço',
                  labelStyle: TextStyle(color: tokens.textMuted),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: precoController,
                      style: TextStyle(color: tokens.text),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Preço (R\$)',
                        labelStyle: TextStyle(color: tokens.textMuted),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: duracaoController,
                      style: TextStyle(color: tokens.text),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Duração (min)',
                        labelStyle: TextStyle(color: tokens.textMuted),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tokens.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    if (nomeController.text.isEmpty || precoController.text.isEmpty || duracaoController.text.isEmpty) {
                      return;
                    }
                    if (isEdit) {
                      final updated = Servico(
                        id: servico.id,
                        prestadorId: servico.prestadorId,
                        nome: nomeController.text,
                        descricao: servico.descricao,
                        precoCentavos: (double.parse(precoController.text.replaceAll(',', '.')) * 100).toInt(),
                        duracaoMinutos: int.parse(duracaoController.text),
                        ativo: servico.ativo,
                        ordem: servico.ordem,
                      );
                      Navigator.pop(ctx);
                      await context.read<ServicosProvider>().updateServico(updated);
                    } else {
                      final novo = Servico(
                        id: '',
                        prestadorId: '', // Vai ser preenchido no Provider
                        nome: nomeController.text,
                        precoCentavos: (double.parse(precoController.text.replaceAll(',', '.')) * 100).toInt(),
                        duracaoMinutos: int.parse(duracaoController.text),
                        ativo: true,
                        ordem: 0,
                      );
                      Navigator.pop(ctx);
                      await context.read<ServicosProvider>().addServico(novo);
                    }
                  },
                  child: const Text('Salvar', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<BicoNotifier>().tokens;
    final servicosProvider = context.watch<ServicosProvider>();
    final servicos = servicosProvider.servicos;
    final isLoading = servicosProvider.isLoading;
    final activeCount = servicos.where((s) => s.ativo).length;

    return Scaffold(
      backgroundColor: tokens.bg,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: BicoTopBar(
              title: 'Serviços',
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
                '$activeCount serviços ativos',
                style: TextStyle(fontSize: 14, color: tokens.textMuted),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: tokens.green))
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    children: [
                      ...servicos.map((s) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Dismissible(
                            key: Key(s.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: tokens.red,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            onDismissed: (direction) {
                              servicosProvider.deleteServico(s.id);
                            },
                            child: GestureDetector(
                              onTap: () => _showServiceSheet(context, tokens, servico: s),
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
                                        color: s.ativo ? tokens.greenSoft : tokens.borderSoft,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.access_time,
                                        size: 20,
                                        color: s.ativo ? tokens.green : tokens.textMuted,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Wrap(
                                            crossAxisAlignment: WrapCrossAlignment.center,
                                            spacing: 8,
                                            children: [
                                              Text(
                                                s.nome,
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                  color: tokens.text,
                                                  letterSpacing: -0.005,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Row(
                                            children: [
                                              Icon(Icons.access_time, size: 12, color: tokens.textMuted),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${s.duracaoMinutos} min',
                                                style: TextStyle(fontSize: 13, color: tokens.textMuted),
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                'R\$ ${(s.precoCentavos / 100).toStringAsFixed(2).replaceAll(".", ",")}',
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
                                        servicosProvider.toggleAtivo(s.id, s.ativo);
                                      },
                                      child: BicoToggle(on: s.ativo),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            ),
                          ),
                        );
                      }),

                      // Add new button (dashed)
                      GestureDetector(
                        onTap: () => _showServiceSheet(context, tokens),
                        child: Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            border: Border.all(color: tokens.border, style: BorderStyle.solid),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add, size: 16, color: tokens.textMuted),
                              const SizedBox(width: 8),
                              Text(
                                'Cadastrar novo serviço',
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
            child: BicoBottomNav(active: NavTab.services, onTap: widget.onNavTap),
          ),
        ],
      ),
    );
  }
}
