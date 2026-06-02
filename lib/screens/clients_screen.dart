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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientesProvider>().loadClientes();
    });
  }

  void _showClientSheet(BuildContext context, dynamic tokens, {Cliente? cliente}) {
    final isEdit = cliente != null;
    final nomeController = TextEditingController(text: cliente?.nome ?? '');
    final telefoneController = TextEditingController(text: cliente?.telefone ?? '');
    final emailController = TextEditingController(text: cliente?.email ?? '');
    final obsController = TextEditingController(text: cliente?.observacoes ?? '');

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
              Text(isEdit ? 'Editar Cliente' : 'Novo Cliente', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: tokens.text)),
              const SizedBox(height: 16),
              TextField(
                controller: nomeController,
                style: TextStyle(color: tokens.text),
                decoration: InputDecoration(
                  labelText: 'Nome completo',
                  labelStyle: TextStyle(color: tokens.textMuted),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: telefoneController,
                style: TextStyle(color: tokens.text),
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Telefone (ex: 11999999999)',
                  labelStyle: TextStyle(color: tokens.textMuted),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                style: TextStyle(color: tokens.text),
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'E-mail (opcional)',
                  labelStyle: TextStyle(color: tokens.textMuted),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: obsController,
                style: TextStyle(color: tokens.text),
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Observações',
                  labelStyle: TextStyle(color: tokens.textMuted),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
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
                    if (nomeController.text.isEmpty) return;

                    String? rawPhone = telefoneController.text.trim();
                    if (rawPhone.isEmpty) {
                      rawPhone = null;
                    } else {
                      rawPhone = rawPhone.replaceAll(RegExp(r'[^\d+]'), '');
                      if (!rawPhone.startsWith('+') && rawPhone.isNotEmpty) {
                        rawPhone = '+55$rawPhone';
                      }
                    }

                    String? rawEmail = emailController.text.trim();
                    if (rawEmail.isEmpty) rawEmail = null;

                    String? rawObs = obsController.text.trim();
                    if (rawObs.isEmpty) rawObs = null;
                    
                    if (isEdit) {
                      final updated = Cliente(
                        id: cliente.id,
                        prestadorId: cliente.prestadorId,
                        nome: nomeController.text.trim(),
                        telefone: rawPhone,
                        email: rawEmail,
                        observacoes: rawObs,
                        fotoPerfilUrl: cliente.fotoPerfilUrl,
                      );
                      Navigator.pop(ctx);
                      await context.read<ClientesProvider>().updateCliente(updated);
                    } else {
                      final novo = Cliente(
                        id: '',
                        prestadorId: '', // Preenchido no provider
                        nome: nomeController.text.trim(),
                        telefone: rawPhone,
                        email: rawEmail,
                        observacoes: rawObs,
                      );
                      Navigator.pop(ctx);
                      await context.read<ClientesProvider>().addCliente(novo);
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
    final clientesProvider = context.watch<ClientesProvider>();
    final clientes = clientesProvider.clientes;
    final isLoading = clientesProvider.isLoading;

    return Scaffold(
      backgroundColor: tokens.bg,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: BicoTopBar(
              title: 'Clientes',
              large: true,
              trailing: GestureDetector(
                onTap: () => _showClientSheet(context, tokens),
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

          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: tokens.bgSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, size: 18, color: tokens.textMuted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Buscar cliente…',
                      style: TextStyle(fontSize: 14, color: tokens.textMuted),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Lista de Clientes
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: tokens.green))
                : clientes.isEmpty
                    ? Center(
                        child: Text('Nenhum cliente cadastrado.', style: TextStyle(color: tokens.textMuted)),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 8),
                        itemCount: clientes.length,
                        itemBuilder: (ctx, i) {
                          final c = clientes[i];
                          return Dismissible(
                            key: Key(c.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(color: tokens.red),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            onDismissed: (direction) {
                              clientesProvider.deleteCliente(c.id);
                            },
                            child: GestureDetector(
                              onTap: () => _showClientSheet(context, tokens, cliente: c),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border(bottom: BorderSide(color: tokens.borderSoft)),
                                ),
                                child: Row(
                                  children: [
                                    BicoAvatar(name: c.nome, size: 42),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            c.nome,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: tokens.text,
                                              letterSpacing: -0.005,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            c.telefone != null && c.telefone!.isNotEmpty ? c.telefone! : 'Sem telefone',
                                            style: TextStyle(fontSize: 13, color: tokens.textMuted),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),

          SafeArea(
            top: false,
            child: BicoBottomNav(active: NavTab.clients, onTap: widget.onNavTap),
          ),
        ],
      ),
    );
  }
}
