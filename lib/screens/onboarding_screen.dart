import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bicco_provider.dart';
import '../widgets/tuco_slot.dart';
import '../widgets/bicco_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 2;
  final int _total = 4;
  String _selected = 'Personal trainer';

  static const _professions = [
    'Eletricista', 'Manicure', 'Personal trainer', 'Faxineira',
    'Encanador', 'Cabeleireiro', 'Fotógrafo', 'Confeiteira',
    'Pintor', 'Designer', 'Massoterapeuta', 'Outro',
  ];

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<BicoNotifier>();
    final tokens = notifier.tokens;

    return Scaffold(
      backgroundColor: tokens.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (_step > 0) {
                            setState(() => _step--);
                          } else {
                            Navigator.pop(context);
                          }
                        },
                        child: Icon(Icons.arrow_back, size: 22, color: tokens.text),
                      ),
                      Text(
                        '${_step + 1} de $_total',
                        style: TextStyle(
                          fontSize: 13,
                          color: tokens.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pushReplacementNamed(context, '/main'),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Pular',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: tokens.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Segmented progress
                  Row(
                    children: List.generate(_total, (i) => Expanded(
                      child: Container(
                        height: 4,
                        margin: EdgeInsets.only(left: i > 0 ? 5 : 0),
                        decoration: BoxDecoration(
                          color: i <= _step ? tokens.green : tokens.borderSoft,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    )),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'O que você faz?',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: tokens.text,
                        letterSpacing: -0.025,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Escolha uma ou mais áreas. Você pode mudar isso depois.',
                      style: TextStyle(
                        fontSize: 15,
                        color: tokens.textMuted,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Profession chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _professions.map((p) {
                        final sel = p == _selected;
                        return GestureDetector(
                          onTap: () => setState(() => _selected = p),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: sel ? tokens.green : tokens.bgSoft,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: sel ? tokens.green : tokens.border,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (sel) ...[
                                  Icon(Icons.check, size: 14, color: Colors.white),
                                  const SizedBox(width: 6),
                                ],
                                Text(
                                  p,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: sel ? Colors.white : tokens.text,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 28),

                    // Tuco tip card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: tokens.orangeSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TucoSlot(size: 36),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                style: TextStyle(
                                  fontSize: 13,
                                  color: tokens.text,
                                  height: 1.45,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Dica do Tuco: ',
                                    style: TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  const TextSpan(
                                    text: 'Você atende mais de uma área? Sem problema — selecione todas que fizerem sentido.',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
              child: Row(
                children: [
                  BicoButton(
                    variant: BtnVariant.secondary,
                    onPressed: () {
                      if (_step > 0) setState(() => _step--);
                    },
                    child: const Icon(Icons.arrow_back, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: BicoButton(
                      variant: BtnVariant.primary,
                      full: true,
                      onPressed: () {
                        if (_step < _total - 1) {
                          setState(() => _step++);
                        } else {
                          Navigator.pushReplacementNamed(context, '/main');
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_step < _total - 1 ? 'Continuar' : 'Começar'),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, size: 18),
                        ],
                      ),
                    ),
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
