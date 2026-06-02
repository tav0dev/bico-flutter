import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/bico_provider.dart';
import '../providers/servicos_provider.dart';
import '../widgets/top_bar.dart';
import '../widgets/ai_sparkle.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  String _fullCaption = "Clique em Gerar para criar um post baseado nos seus serviços!";
  String _typed = "Clique em Gerar para criar um post baseado nos seus serviços!";
  bool _generating = false;
  Timer? _timer;
  int _typedLen = 0;

  final _hashtags = ['#serviços', '#agendaaberta', '#novidade'];
  final _channelActive = [true, true, false]; // Instagram, WhatsApp Status, Facebook

  void _startGenerate() {
    final servicosProvider = context.read<ServicosProvider>();
    final servicos = servicosProvider.servicos.where((s) => s.ativo).toList();
    final prestador = context.read<BicoNotifier>().prestador;

    String text;
    if (servicos.isEmpty) {
      text = "Parece que você ainda não cadastrou nenhum serviço ativo! Vá na tela inicial, clique em 'Criar serviço' e depois volte aqui para eu criar posts incríveis para você. ✨";
    } else {
      servicos.shuffle();
      final s = servicos.first;
      final price = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format((s.precoCentavos ?? 0) / 100);
      final hasPrice = (s.precoCentavos ?? 0) > 0;
      
      final templates = [
        "Vocês pediram e a agenda está aberta! ✨\n\nEstou com horários disponíveis para: ${s.nome}.\n\n⏱️ Duração: ${s.duracaoMinutos} min\n${hasPrice ? '💳 Valor: $price\n' : ''}\nNão deixe para depois, os horários esgotam rápido. Me manda um direct ou acesse o link da bio para garantir o seu! 👇",
        "Precisando de ${s.nome}? Deixa comigo! 💪\n\nTenho alguns horários livres essa semana para te atender com toda a qualidade que você merece.\n\n👉 Manda uma mensagem e vamos agendar!",
        "Um lembrete rápido: ainda tenho vagas para ${s.nome} esta semana! 🚀\n\nSe você estava adiando, essa é a hora. Corre no link da bio para marcar seu horário antes que preencha tudo. 😉",
      ];
      
      templates.shuffle();
      text = templates.first;
    }

    _fullCaption = text;
    _timer?.cancel();
    
    setState(() {
      _generating = true;
      _typed = '';
      _typedLen = 0;
    });
    
    _timer = Timer.periodic(const Duration(milliseconds: 15), (t) {
      final step = (1 + (DateTime.now().millisecondsSinceEpoch % 4)).clamp(1, 4).toInt();
      _typedLen = (_typedLen + step).clamp(0, _fullCaption.length);
      if (_typedLen >= _fullCaption.length) {
        t.cancel();
        setState(() {
          _typed = _fullCaption;
          _generating = false;
        });
      } else {
        setState(() => _typed = _fullCaption.substring(0, _typedLen));
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<BicoNotifier>().tokens;
    final channels = ['Instagram', 'WhatsApp Status', 'Facebook'];

    return Scaffold(
      backgroundColor: tokens.bg,
      body: SafeArea(
        child: Column(
          children: [
            BicoTopBar(
              title: 'Criar post',
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close, size: 22, color: tokens.text),
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
              ),
              trailing: GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: _typed));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Texto copiado para a área de transferência!'))
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: tokens.green,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Copiar Texto',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                children: [
                  // Photo placeholder
                  AspectRatio(
                    aspectRatio: 4 / 5,
                    child: Container(
                      decoration: BoxDecoration(
                        color: tokens.bgSoft,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: tokens.border),
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: CustomPaint(
                              painter: _StripePainter(
                                color1: tokens.bgSoft,
                                color2: tokens.borderSoft,
                              ),
                              size: Size.infinite,
                            ),
                          ),
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.image_outlined, size: 36, color: tokens.textFaint),
                                const SizedBox(height: 8),
                                Text(
                                  'foto ou vídeo.jpg',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: tokens.textMuted,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xD90F172A),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.edit_outlined, size: 14, color: Colors.white),
                                  SizedBox(width: 6),
                                  Text(
                                    'Trocar',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // AI generate row
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: tokens.orangeSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const AISparkle(size: 14),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Tuco pode criar uma legenda automática com base nos seus serviços cadastrados.',
                            style: TextStyle(
                              fontSize: 13,
                              color: tokens.text,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _startGenerate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: tokens.orange,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.refresh, size: 13, color: Colors.white),
                                SizedBox(width: 5),
                                Text(
                                  'Gerar',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Caption
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Legenda',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: tokens.text,
                        ),
                      ),
                      Text(
                        '${_typed.length}/2200',
                        style: TextStyle(fontSize: 12, color: tokens.textFaint),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    constraints: const BoxConstraints(minHeight: 120),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: tokens.bgSoft,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: tokens.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            _typed,
                            style: TextStyle(
                              fontSize: 14,
                              color: tokens.text,
                              height: 1.5,
                              letterSpacing: -0.005,
                            ),
                          ),
                        ),
                        if (_generating)
                          _BlinkingCursor(color: tokens.orange),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Hashtags
                  Row(
                    children: [
                      Text(
                        'Hashtags',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: tokens.text,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const AISparkle(size: 11),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ..._hashtags.map((h) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: tokens.purpleSoft,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          h,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: tokens.purple,
                          ),
                        ),
                      )),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          border: Border.all(color: tokens.border),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '+ adicionar',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: tokens.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Channel chips
                  Text(
                    'Copiar para',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: tokens.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(channels.length, (i) {
                      final active = _channelActive[i];
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: i < channels.length - 1 ? 8 : 0),
                          child: GestureDetector(
                            onTap: () => setState(() => _channelActive[i] = !_channelActive[i]),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: active ? tokens.greenSoft : tokens.bgSoft,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: active ? tokens.green : tokens.border,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (active) ...[
                                    Icon(Icons.check, size: 13, color: tokens.green),
                                    const SizedBox(width: 5),
                                  ],
                                  Flexible(
                                    child: Text(
                                      channels[i],
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: active ? tokens.green : tokens.textMuted,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
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

class _StripePainter extends CustomPainter {
  final Color color1;
  final Color color2;

  const _StripePainter({required this.color1, required this.color2});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color2;
    const stripeWidth = 10.0;
    for (double x = -size.height; x < size.width + size.height; x += stripeWidth * 2) {
      final path = Path()
        ..moveTo(x, 0)
        ..lineTo(x + stripeWidth, 0)
        ..lineTo(x + stripeWidth + size.height, size.height)
        ..lineTo(x + size.height, size.height)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_StripePainter old) => old.color2 != color2;
}

class _BlinkingCursor extends StatefulWidget {
  final Color color;

  const _BlinkingCursor({required this.color});

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) => Opacity(
        opacity: _ctrl.value < 0.5 ? 1.0 : 0.0,
        child: Container(
          width: 2,
          height: 14,
          color: widget.color,
          margin: const EdgeInsets.only(left: 1, top: 2),
        ),
      ),
    );
  }
}
