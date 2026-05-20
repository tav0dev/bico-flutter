import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bicco_provider.dart';

class BiccoToggle extends StatelessWidget {
  final bool on;
  final ValueChanged<bool>? onChanged;

  const BiccoToggle({super.key, required this.on, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<BiccoNotifier>().tokens;
    return GestureDetector(
      onTap: onChanged != null ? () => onChanged!(!on) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36,
        height: 22,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(11),
          color: on ? tokens.green : tokens.border,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: on ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(50),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
