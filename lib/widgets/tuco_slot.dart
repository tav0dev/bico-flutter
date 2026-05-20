import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bicco_provider.dart';
import '../theme/tokens.dart';

class TucoSlot extends StatelessWidget {
  final double size;
  final String? mode;

  const TucoSlot({super.key, this.size = 96, this.mode});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<BiccoNotifier>();
    final tokens = notifier.tokens;
    final effectiveMode = mode ?? notifier.tucoMode;

    if (effectiveMode == 'hidden') return const SizedBox.shrink();

    if (effectiveMode == 'placeholder') {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: tokens.border, width: 1.5),
          color: tokens.bgSoft,
        ),
        child: Center(
          child: Text(
            'Tuco\nillustration',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: (size * 0.11).clamp(9.0, double.infinity),
              color: tokens.textFaint,
              height: 1.2,
            ),
          ),
        ),
      );
    }

    // 'simple' — geometric stand-in
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Body — purple circle
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tokens.purple,
            ),
          ),
          // Navy overalls band (bottom 38%)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: size * 0.38,
            child: Container(
              decoration: BoxDecoration(
                color: BiccoTokens.light.navy,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(size / 2),
                  bottomRight: Radius.circular(size / 2),
                ),
              ),
            ),
          ),
          // Eye white
          Positioned(
            top: size * 0.28,
            left: size * 0.32,
            child: Container(
              width: size * 0.13,
              height: size * 0.13,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: Center(
                child: Container(
                  width: size * 0.13 * 0.6,
                  height: size * 0.13 * 0.6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: BiccoTokens.light.navy,
                  ),
                ),
              ),
            ),
          ),
          // Beak
          Positioned(
            top: size * 0.36,
            left: size * 0.54,
            child: CustomPaint(
              size: Size(size * 0.28, size * 0.16),
              painter: _BeakPainter(color: tokens.orange, size: size),
            ),
          ),
        ],
      ),
    );
  }
}

class _BeakPainter extends CustomPainter {
  final Color color;
  final double size;

  _BeakPainter({required this.color, required this.size});

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final paint = Paint()..color = color;
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size * 0.28, size * 0.08);
    path.lineTo(0, size * 0.16);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BeakPainter old) => old.color != color || old.size != size;
}
