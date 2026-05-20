import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bicco_provider.dart';
import '../widgets/top_bar.dart';
import '../widgets/ai_sparkle.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  static const _fullCaption =
      "Quer começar a treinar mas não sabe por onde? 💪\n\nMonte sua avaliação física comigo: a gente analisa postura, condicionamento e seus objetivos. Depois eu monto um plano feito pra sua rotina.\n\n📍 Vila Madalena · Online também\n👉 Reserva pelo link na bio";

  String _typed = _fullCaption;
  bool _generating = false;
  Timer? _timer;
  int _typedLen = 0;

  final _hashtags = ['#personaltrainer', '#vilamadalena', '#treinofuncional', '#saúde'];
  final _channelActive = [true, true, false]; // Instagram, WhatsApp Status, Facebook

  void _startGenerate() {
    _timer?.cancel();
    setState(() {
      _generating = true;
      _typed = '';
      _typedLen = 0;
    });
    _timer = Timer.periodic(const Duration(milliseconds: 20), (t) {
      final step = (1 + (DateTime.now().millisecondsSinceEpoch % 3)).clamp(1, 3).toInt();
      _typedLen = (_typedLen + step + 1).clamp(0, _fullCaption.length);
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
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: tokens.green,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Publicar',
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
                          // Diagonal stripe pattern
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
                                  'foto do treino.jpg',
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
                            'Tuco escreveu uma legenda baseada na sua foto e perfil',
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
                    'Publicar em',
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
