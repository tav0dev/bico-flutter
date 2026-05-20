import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bicco_provider.dart';
import '../widgets/top_bar.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/bicco_card.dart';
import '../widgets/pill.dart';
import '../widgets/toggle.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final _services = [
    (name: 'Treino personalizado', dur: '1h', price: 120, active: true, tag: 'Mais vendido'),
    (name: 'Avaliação física', dur: '45min', price: 90, active: true, tag: ''),
    (name: 'Plano mensal (8 sessões)', dur: '8 sessões', price: 750, active: true, tag: 'Pacote'),
    (name: 'Treino dupla', dur: '1h', price: 180, active: true, tag: ''),
    (name: 'Consultoria online', dur: '30min', price: 60, active: false, tag: ''),
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<BicoNotifier>().tokens;
    final activeCount = _services.where((s) => s.active).length;

    return Scaffold(
      backgroundColor: tokens.bg,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: BicoTopBar(
              title: 'Serviços',
              large: true,
              trailing: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: tokens.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 20),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '$activeCount serviços ativos',
                style: TextStyle(fontSize: 14, color: tokens.textMuted),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              children: [
                ...List.generate(_services.length, (i) {
                  final s = _services[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: BicoCard(
                      padding: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: s.active ? tokens.greenSoft : tokens.borderSoft,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                s.tag == 'Pacote' ? Icons.description_outlined : Icons.access_time,
                                size: 20,
                                color: s.active ? tokens.green : tokens.textMuted,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 8,
                                    children: [
                                      Text(
                                        s.name,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: tokens.text,
                                          letterSpacing: -0.005,
                                        ),
                                      ),
                                      if (s.tag.isNotEmpty)
                                        BicoPill(
                                          text: s.tag,
                                          color: s.tag == 'Pacote' ? 'purple' : 'orange',
                                          size: 'sm',
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Icon(Icons.access_time, size: 12, color: tokens.textMuted),
                                      const SizedBox(width: 4),
                                      Text(
                                        s.dur,
                                        style: TextStyle(fontSize: 13, color: tokens.textMuted),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'R\$ ${s.price}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: tokens.text,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            BicoToggle(on: s.active),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                // Add new button (dashed)
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: tokens.border, style: BorderStyle.solid),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, size: 16, color: tokens.textMuted),
                        const SizedBox(width: 8),
                        Text(
                          'Cadastrar novo serviço',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: tokens.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: BicoBottomNav(active: NavTab.home),
          ),
        ],
      ),
    );
  }
}
