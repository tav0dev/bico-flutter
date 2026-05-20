import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bicco_provider.dart';

class AISparkle extends StatelessWidget {
  final double size;

  const AISparkle({super.key, this.size = 14});

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<BiccoNotifier>().tokens;
    return Container(
      width: size + 6,
      height: size + 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: tokens.orangeSoft,
      ),
      child: Icon(Icons.auto_awesome, size: size - 2, color: tokens.orange),
    );
  }
}
