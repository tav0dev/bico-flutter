import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bicco_provider.dart';
import '../widgets/top_bar.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/avatar.dart';
import '../widgets/pill.dart';
import '../widgets/ai_sparkle.dart';

class InboxScreen extends StatefulWidget {
  final ValueChanged<NavTab>? onNavTap;

  const InboxScreen({super.key, this.onNavTap});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  int _activeFilter = 0;

  static const _filters = ['Tudo (3)', 'Não lidas', 'WhatsApp', 'Instagram'];

  static const _messages = [
    (name: 'Carla Mendes', preview: 'Posso remarcar pra quinta às 16h?', time: '14:32', unread: 2, channel: 'wpp', online: true, aiSuggest: false, isNew: false, sent: false),
    (name: 'João Pedro', preview: 'Confirmado para amanhã 👍', time: '11:08', unread: 0, channel: 'wpp', online: false, aiSuggest: false, isNew: false, sent: false),
    (name: 'Lia Faria', preview: 'Você: enviei o orçamento, qualquer dúvida...', time: '10:14', unread: 0, channel: 'instagram', online: false, aiSuggest: false, isNew: false, sent: true),
    (name: 'Pedro Rocha', preview: 'Bom dia! Quanto custa um pacote mensal?', time: 'Ontem', unread: 1, channel: 'wpp', online: false, aiSuggest: true, isNew: false, sent: false),
    (name: 'Beatriz Lima', preview: 'Obrigada pela sessão de hoje!', time: 'Ontem', unread: 0, channel: 'wpp', online: false, aiSuggest: false, isNew: false, sent: false),
    (name: '+55 11 9 8123-4567', preview: 'Olá, vi seu perfil no Instagram...', time: 'seg', unread: 1, channel: 'wpp', online: false, aiSuggest: true, isNew: true, sent: false),
    (name: 'Tomás Andrade', preview: 'Beleza, te aviso semana que vem', time: 'seg', unread: 0, channel: 'instagram', online: false, aiSuggest: false, isNew: false, sent: false),
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<BicoNotifier>().tokens;

    return Scaffold(
      backgroundColor: tokens.bg,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: BicoTopBar(
              title: 'Mensagens',
              large: true,
              trailing: IconButton(
                onPressed: () {},
                icon: Icon(Icons.search, size: 20, color: tokens.text),
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(),
              ),
            ),
          ),

          // Filter chips
          SizedBox(
            height: 46,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              itemCount: _filters.length,
              itemBuilder: (ctx, i) => Padding(
                padding: EdgeInsets.only(right: i < _filters.length - 1 ? 6 : 0),
                child: GestureDetector(
                  onTap: () => setState(() => _activeFilter = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: i == _activeFilter ? tokens.text : tokens.bgSoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _filters[i],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: i == _activeFilter ? tokens.bg : tokens.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Message list
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (ctx, i) {
                final m = _messages[i];
                return _MessageTile(
                  message: m,
                  tokens: tokens,
                  onTap: () => Navigator.pushNamed(context, '/inbox-thread'),
                );
              },
            ),
          ),

          SafeArea(
            top: false,
            child: BicoBottomNav(active: NavTab.inbox, onTap: widget.onNavTap),
          ),
        ],
      ),
    );
  }
}

class _MessageTile extends StatelessWidget {
  final dynamic message;
  final dynamic tokens;
  final VoidCallback? onTap;

  const _MessageTile({required this.message, required this.tokens, this.onTap});

  @override
  Widget build(BuildContext context) {
    final m = message;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: m.unread > 0 ? tokens.bg : Colors.transparent,
          border: Border(
            bottom: BorderSide(color: tokens.borderSoft),
          ),
        ),
        child: Row(
          children: [
            // Avatar with channel badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                BicoAvatar(name: m.name, size: 44),
                if (m.online)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: tokens.green,
                        border: Border.all(color: tokens.bg, width: 2),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: m.channel == 'wpp'
                          ? null
                          : const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF8134AF)],
                            ),
                      color: m.channel == 'wpp' ? const Color(0xFF25D366) : null,
                      border: Border.all(color: tokens.bg, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      m.channel == 'wpp' ? 'W' : 'IG',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 7,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                m.name,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: m.unread > 0 ? FontWeight.w700 : FontWeight.w600,
                                  color: tokens.text,
                                  letterSpacing: -0.005,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (m.isNew) ...[
                              const SizedBox(width: 6),
                              BicoPill(text: 'novo', color: 'purple', size: 'sm'),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        m.time,
                        style: TextStyle(
                          fontSize: 12,
                          color: m.unread > 0 ? tokens.green : tokens.textFaint,
                          fontWeight: m.unread > 0 ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            if (m.sent) ...[
                              Icon(Icons.check, size: 12, color: tokens.textMuted),
                              const SizedBox(width: 2),
                            ],
                            Flexible(
                              child: Text(
                                m.preview,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: m.unread > 0 ? tokens.text : tokens.textMuted,
                                  fontWeight: m.unread > 0 ? FontWeight.w500 : FontWeight.w400,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (m.aiSuggest) ...[
                        const SizedBox(width: 6),
                        const AISparkle(size: 11),
                      ],
                      if (m.unread > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          constraints: const BoxConstraints(minWidth: 18),
                          height: 18,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: tokens.green,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${m.unread}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
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
