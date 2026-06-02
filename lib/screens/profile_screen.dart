import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bico_provider.dart';
import '../widgets/top_bar.dart';
import '../widgets/avatar.dart';
import '../widgets/bico_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<BicoNotifier>();
    final tokens = notifier.tokens;
    final prestador = notifier.prestador;

    final name = prestador?['nome_completo'] ?? 'Usuário';
    final email = prestador?['email'] ?? 'sem_email@bico.com';
    final telefone = prestador?['telefone'] ?? 'Sem telefone';
    final categoria = prestador?['categoria'] ?? 'Sem categoria';

    return Scaffold(
      backgroundColor: tokens.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BicoTopBar(
              title: 'Meu Perfil',
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back, size: 22, color: tokens.text),
              ),
              trailing: const SizedBox(width: 48), // Spacer to center title
            ),
            
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                children: [
                  // Cabeçalho do Perfil
                  Center(
                    child: Column(
                      children: [
                        BicoAvatar(name: name, size: 80),
                        const SizedBox(height: 16),
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: tokens.text,
                            letterSpacing: -0.02,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          categoria,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: tokens.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Informações de Contato
                  _SectionTitle(title: 'CONTATO', tokens: tokens),
                  const SizedBox(height: 12),
                  _InfoBox(icon: Icons.email_outlined, label: 'E-mail', value: email, tokens: tokens),
                  const SizedBox(height: 12),
                  _InfoBox(icon: Icons.phone_outlined, label: 'Telefone', value: telefone, tokens: tokens),
                  
                  const SizedBox(height: 32),

                  // Preferências (Aparência)
                  _SectionTitle(title: 'PREFERÊNCIAS', tokens: tokens),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: tokens.bgSoft,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: tokens.borderSoft),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.dark_mode_outlined, size: 20, color: tokens.textMuted),
                                const SizedBox(width: 12),
                                Text('Modo Escuro', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: tokens.text)),
                              ],
                            ),
                            Switch(
                              value: notifier.isDark,
                              activeColor: tokens.green,
                              onChanged: (val) => notifier.setDark(val),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.color_lens_outlined, size: 20, color: tokens.textMuted),
                                const SizedBox(width: 12),
                                Text('Cor do Tema', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: tokens.text)),
                              ],
                            ),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => notifier.setAccent('green'),
                                  child: Container(
                                    width: 24, height: 24,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFF16A34A),
                                      border: notifier.accent == 'green' ? Border.all(color: tokens.text, width: 2) : null,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => notifier.setAccent('purple'),
                                  child: Container(
                                    width: 24, height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFF7C3AED),
                                      border: notifier.accent == 'purple' ? Border.all(color: tokens.text, width: 2) : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Sair da Conta
                  BicoButton(
                    variant: BtnVariant.danger,
                    full: true,
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: tokens.bg,
                          title: Text('Sair', style: TextStyle(color: tokens.text)),
                          content: Text('Tem certeza que deseja desconectar sua conta?', style: TextStyle(color: tokens.textMuted)),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                Navigator.pop(context); // Close ProfileScreen
                                notifier.logoutGoogle(); // Sign out do Supabase
                              }, 
                              child: Text('Sair', style: TextStyle(color: tokens.red)),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text('Sair da conta'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final dynamic tokens;

  const _SectionTitle({required this.title, required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: tokens.textFaint,
        letterSpacing: 1.0,
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final dynamic tokens;

  const _InfoBox({
    required this.icon,
    required this.label,
    required this.value,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: tokens.bgSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.borderSoft),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: tokens.textMuted),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: tokens.textMuted, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 15, color: tokens.text, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
