import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bico_provider.dart';
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
  String _activeChannel = 'all';

  static const _channels = [
    _Channel(id: 'all', label: 'Tudo', icon: Icons.all_inbox_outlined),
    _Channel(id: 'wpp', label: 'WhatsApp', icon: Icons.chat_outlined),
    _Channel(
      id: 'instagram',
      label: 'Instagram',
      icon: Icons.camera_alt_outlined,
    ),
    _Channel(id: 'messenger', label: 'Messenger', icon: Icons.forum_outlined),
    _Channel(id: 'email', label: 'Email', icon: Icons.mail_outline),
    _Channel(id: 'sms', label: 'SMS', icon: Icons.sms_outlined),
    _Channel(id: 'site', label: 'Site', icon: Icons.language_outlined),
  ];

  static const _messages = [
    _InboxMessage(
      name: 'Carla Mendes',
      preview: 'Posso remarcar pra quinta as 16h?',
      time: '14:32',
      unread: 2,
      channel: 'wpp',
      online: true,
      aiSuggest: false,
      isLead: false,
      sent: false,
      urgent: true,
    ),
    _InboxMessage(
      name: 'Joao Pedro',
      preview: 'Confirmado para amanha. Pode manter!',
      time: '11:08',
      unread: 0,
      channel: 'sms',
      online: false,
      aiSuggest: false,
      isLead: false,
      sent: false,
      urgent: false,
    ),
    _InboxMessage(
      name: 'Lia Faria',
      preview: 'Voce: enviei o orcamento, qualquer duvida me chama.',
      time: '10:14',
      unread: 0,
      channel: 'instagram',
      online: false,
      aiSuggest: false,
      isLead: false,
      sent: true,
      urgent: false,
    ),
    _InboxMessage(
      name: 'Pedro Rocha',
      preview: 'Bom dia! Quanto custa um pacote mensal?',
      time: 'Ontem',
      unread: 1,
      channel: 'messenger',
      online: false,
      aiSuggest: true,
      isLead: true,
      sent: false,
      urgent: false,
    ),
    _InboxMessage(
      name: 'Beatriz Lima',
      preview: 'Obrigada pela sessao de hoje!',
      time: 'Ontem',
      unread: 0,
      channel: 'wpp',
      online: false,
      aiSuggest: false,
      isLead: false,
      sent: false,
      urgent: false,
    ),
    _InboxMessage(
      name: 'Formulario do site',
      preview: 'Novo pedido: preciso de atendimento na zona sul.',
      time: 'seg',
      unread: 1,
      channel: 'site',
      online: false,
      aiSuggest: true,
      isLead: true,
      sent: false,
      urgent: true,
    ),
    _InboxMessage(
      name: 'Tomaz Andrade',
      preview: 'Beleza, te aviso semana que vem',
      time: 'seg',
      unread: 0,
      channel: 'email',
      online: false,
      aiSuggest: false,
      isLead: false,
      sent: false,
      urgent: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<BicoNotifier>().tokens;
    final visibleMessages = _visibleMessages();
    final unread = _messages.fold<int>(0, (sum, item) => sum + item.unread);
    final leads = _messages.where((item) => item.isLead).length;
    final urgent = _messages.where((item) => item.urgent).length;

    return Scaffold(
      backgroundColor: tokens.bg,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: BicoTopBar(
              title: 'Mensagens',
              subtitle: 'WhatsApp, Instagram, email, SMS e leads',
              large: true,
              trailing: IconButton(
                tooltip: 'Buscar',
                onPressed: () {},
                icon: Icon(Icons.search, size: 21, color: tokens.text),
              ),
            ),
          ),
          _summary(tokens, unread: unread, leads: leads, urgent: urgent),
          _channelStrip(tokens),
          _channelNote(tokens),
          Expanded(
            child: visibleMessages.isEmpty
                ? _emptyState(tokens)
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 8),
                    itemCount: visibleMessages.length,
                    itemBuilder: (ctx, i) {
                      final message = visibleMessages[i];
                      return _MessageTile(
                        message: message,
                        onTap: () =>
                            Navigator.pushNamed(context, '/inbox-thread'),
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

  Widget _summary(
    dynamic tokens, {
    required int unread,
    required int leads,
    required int urgent,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Row(
        children: [
          _SummaryBox(value: unread.toString(), label: 'Nao lidas'),
          const SizedBox(width: 8),
          _SummaryBox(value: leads.toString(), label: 'Novos leads'),
          const SizedBox(width: 8),
          _SummaryBox(value: urgent.toString(), label: 'Responder hoje'),
        ],
      ),
    );
  }

  Widget _channelStrip(dynamic tokens) {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        scrollDirection: Axis.horizontal,
        itemCount: _channels.length,
        separatorBuilder: (_, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final channel = _channels[index];
          final selected = _activeChannel == channel.id;
          final count = channel.id == 'all'
              ? _messages.length
              : _messages.where((m) => m.channel == channel.id).length;
          final unread = channel.id == 'all'
              ? _messages.fold<int>(0, (sum, m) => sum + m.unread)
              : _messages
                    .where((m) => m.channel == channel.id)
                    .fold<int>(0, (sum, m) => sum + m.unread);

          return GestureDetector(
            onTap: () => setState(() => _activeChannel = channel.id),
            child: Container(
              width: channel.id == 'all' ? 88 : 116,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: selected ? tokens.green : tokens.bgSoft,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selected ? tokens.green : tokens.borderSoft,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        channel.icon,
                        color: selected
                            ? Colors.white
                            : _channelColor(tokens, channel.id),
                        size: 18,
                      ),
                      const Spacer(),
                      if (unread > 0)
                        Container(
                          constraints: const BoxConstraints(minWidth: 18),
                          height: 18,
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected ? Colors.white : tokens.green,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            unread.toString(),
                            style: TextStyle(
                              color: selected ? tokens.green : Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    channel.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? Colors.white : tokens.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    count == 1 ? '1 conversa' : '$count conversas',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? Colors.white70 : tokens.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _channelNote(dynamic tokens) {
    final channel = _channels.firstWhere((item) => item.id == _activeChannel);
    final text = switch (channel.id) {
      'all' => 'Central unica para nao perder cliente entre aplicativos.',
      'wpp' => 'Prioridade para agenda, confirmacao e conversa rapida.',
      'instagram' => 'Bom para leads vindos de posts, stories e direct.',
      'messenger' => 'Util para clientes que chegam pela pagina do Facebook.',
      'email' => 'Melhor para orcamentos, comprovantes e mensagens longas.',
      'sms' => 'Bom para lembretes curtos quando a pessoa nao responde.',
      'site' => 'Pedidos do formulario entram como lead para virar contato.',
      _ => '',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: tokens.bgSoft,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: tokens.borderSoft),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: tokens.textMuted, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: tokens.textMuted,
                  fontSize: 12,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(dynamic tokens) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'Nenhuma conversa neste canal.',
          textAlign: TextAlign.center,
          style: TextStyle(color: tokens.textMuted),
        ),
      ),
    );
  }

  List<_InboxMessage> _visibleMessages() {
    if (_activeChannel == 'all') return _messages;
    return _messages
        .where((message) => message.channel == _activeChannel)
        .toList();
  }

  Color _channelColor(dynamic tokens, String channel) {
    return switch (channel) {
      'wpp' => const Color(0xFF25D366),
      'instagram' => tokens.purple,
      'messenger' => const Color(0xFF0084FF),
      'email' => tokens.orange,
      'sms' => tokens.green,
      'site' => const Color(0xFF0891B2),
      _ => tokens.textMuted,
    };
  }
}

class _SummaryBox extends StatelessWidget {
  final String value;
  final String label;

  const _SummaryBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<BicoNotifier>().tokens;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
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
                color: tokens.textMuted,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageTile extends StatelessWidget {
  final _InboxMessage message;
  final VoidCallback? onTap;

  const _MessageTile({required this.message, this.onTap});

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<BicoNotifier>().tokens;
    final channelColor = _channelColor(tokens, message.channel);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: message.unread > 0 ? tokens.bg : Colors.transparent,
          border: Border(bottom: BorderSide(color: tokens.borderSoft)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                BicoAvatar(name: message.name, size: 44),
                if (message.online)
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
                  bottom: -3,
                  right: -3,
                  child: Container(
                    width: 19,
                    height: 19,
                    decoration: BoxDecoration(
                      color: channelColor,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: tokens.bg, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      _channelIcon(message.channel),
                      color: Colors.white,
                      size: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          message.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: message.unread > 0
                                ? FontWeight.w800
                                : FontWeight.w700,
                            color: tokens.text,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        message.time,
                        style: TextStyle(
                          fontSize: 12,
                          color: message.unread > 0
                              ? tokens.green
                              : tokens.textFaint,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          message.preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: message.unread > 0
                                ? tokens.text
                                : tokens.textMuted,
                            fontWeight: message.unread > 0
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (message.aiSuggest) ...[
                        const SizedBox(width: 6),
                        const AISparkle(size: 11),
                      ],
                      if (message.unread > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          constraints: const BoxConstraints(minWidth: 18),
                          height: 18,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: tokens.green,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Text(
                            '${message.unread}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _ChannelPill(
                        label: _channelLabel(message.channel),
                        color: channelColor,
                      ),
                      if (message.isLead)
                        BicoPill(text: 'lead', color: 'purple', size: 'sm'),
                      if (message.urgent)
                        BicoPill(text: 'hoje', color: 'orange', size: 'sm'),
                      if (message.sent)
                        BicoPill(
                          text: 'respondido',
                          color: 'green',
                          size: 'sm',
                        ),
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

  Color _channelColor(dynamic tokens, String channel) {
    return switch (channel) {
      'wpp' => const Color(0xFF25D366),
      'instagram' => tokens.purple,
      'messenger' => const Color(0xFF0084FF),
      'email' => tokens.orange,
      'sms' => tokens.green,
      'site' => const Color(0xFF0891B2),
      _ => tokens.textMuted,
    };
  }

  IconData _channelIcon(String channel) {
    return switch (channel) {
      'wpp' => Icons.chat_outlined,
      'instagram' => Icons.camera_alt_outlined,
      'messenger' => Icons.forum_outlined,
      'email' => Icons.mail_outline,
      'sms' => Icons.sms_outlined,
      'site' => Icons.language_outlined,
      _ => Icons.chat_bubble_outline,
    };
  }

  String _channelLabel(String channel) {
    return switch (channel) {
      'wpp' => 'WhatsApp',
      'instagram' => 'Instagram',
      'messenger' => 'Messenger',
      'email' => 'Email',
      'sms' => 'SMS',
      'site' => 'Site',
      _ => 'Canal',
    };
  }
}

class _ChannelPill extends StatelessWidget {
  final String label;
  final Color color;

  const _ChannelPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _Channel {
  final String id;
  final String label;
  final IconData icon;

  const _Channel({required this.id, required this.label, required this.icon});
}

class _InboxMessage {
  final String name;
  final String preview;
  final String time;
  final int unread;
  final String channel;
  final bool online;
  final bool aiSuggest;
  final bool isLead;
  final bool sent;
  final bool urgent;

  const _InboxMessage({
    required this.name,
    required this.preview,
    required this.time,
    required this.unread,
    required this.channel,
    required this.online,
    required this.aiSuggest,
    required this.isLead,
    required this.sent,
    required this.urgent,
  });
}
