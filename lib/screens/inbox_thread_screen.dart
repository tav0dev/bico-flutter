import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bicco_provider.dart';
import '../widgets/avatar.dart';
import '../widgets/ai_sparkle.dart';

class InboxThreadScreen extends StatefulWidget {
  const InboxThreadScreen({super.key});

  @override
  State<InboxThreadScreen> createState() => _InboxThreadScreenState();
}

class _InboxThreadScreenState extends State<InboxThreadScreen> {
  bool _showSuggestions = true;

  static const _messages = [
    (from: 'them', text: 'Oi Marina! Vi seu trabalho no Instagram', time: '14:20'),
    (from: 'them', text: 'Você atende perto da Vila Madalena? Quanto custa um pacote mensal?', time: '14:20'),
    (from: 'me', text: 'Oi Carla! Atendo sim 😊 Tenho dois pacotes:\n\n• 8 sessões/mês — R\$ 750\n• 12 sessões/mês — R\$ 1.080', time: '14:25'),
    (from: 'them', text: 'Perfeito! Posso começar quinta-feira?', time: '14:30'),
    (from: 'them', text: 'Posso remarcar pra quinta às 16h?', time: '14:32'),
  ];

  static const _suggestions = [
    'Posso sim! Quinta às 16h tá confirmado ✅',
    'Quinta tenho 16h ou 18h. Qual prefere?',
    'Hoje não consigo às 16h. E às 17h30?',
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<BicoNotifier>().tokens;

    return Scaffold(
      backgroundColor: tokens.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              decoration: BoxDecoration(
                color: tokens.bg,
                border: Border(bottom: BorderSide(color: tokens.borderSoft)),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.chevron_left, size: 22, color: tokens.text),
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 4),
                  const BicoAvatar(name: 'Carla Mendes', size: 36),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Carla Mendes',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: tokens.text,
                            letterSpacing: -0.005,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: tokens.green,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'online · WhatsApp',
                              style: TextStyle(
                                fontSize: 11,
                                color: tokens.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.more_vert, size: 20, color: tokens.text),
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // AI context strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: tokens.purpleSoft,
                border: Border(bottom: BorderSide(color: tokens.borderSoft)),
              ),
              child: Row(
                children: [
                  const AISparkle(size: 13),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: TextStyle(
                          fontSize: 12,
                          color: tokens.text,
                          height: 1.4,
                        ),
                        children: [
                          TextSpan(
                            text: 'Cliente desde mar/2026 · ',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          TextSpan(
                            text: 'Pacote 8 sessões · próximo: hoje 14:00',
                            style: TextStyle(color: tokens.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Messages
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _messages.length,
                itemBuilder: (ctx, i) {
                  final msg = _messages[i];
                  final isMe = msg.from == 'me';
                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(ctx).size.width * 0.78,
                      ),
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isMe ? tokens.green : tokens.bgSoft,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(isMe ? 16 : 4),
                          bottomRight: Radius.circular(isMe ? 4 : 16),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            msg.text,
                            style: TextStyle(
                              fontSize: 14,
                              color: isMe ? Colors.white : tokens.text,
                              height: 1.4,
                              letterSpacing: -0.005,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            msg.time,
                            style: TextStyle(
                              fontSize: 10,
                              color: (isMe ? Colors.white : tokens.text).withAlpha(179),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // AI suggestions
            if (_showSuggestions)
              Container(
                decoration: BoxDecoration(
                  color: tokens.bgSoft,
                  border: Border(top: BorderSide(color: tokens.borderSoft)),
                ),
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const AISparkle(size: 11),
                        const SizedBox(width: 6),
                        Text(
                          'SUGESTÕES DO TUCO',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: tokens.orange,
                            letterSpacing: 0.04,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => setState(() => _showSuggestions = false),
                          child: Icon(Icons.close, size: 16, color: tokens.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._suggestions.map((s) => Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: tokens.bg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: tokens.border),
                      ),
                      child: Text(
                        s,
                        style: TextStyle(
                          fontSize: 13,
                          color: tokens.text,
                          height: 1.35,
                        ),
                      ),
                    )),
                  ],
                ),
              ),

            // Message input
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: tokens.bg,
                border: Border(top: BorderSide(color: tokens.borderSoft)),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.attach_file, size: 20, color: tokens.textMuted),
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: tokens.bgSoft,
                        borderRadius: BorderRadius.circular(19),
                      ),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Mensagem…',
                        style: TextStyle(fontSize: 14, color: tokens.textMuted),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: tokens.green,
                    ),
                    child: const Icon(Icons.send, size: 18, color: Colors.white),
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
