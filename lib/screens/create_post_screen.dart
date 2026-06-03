import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/servico.dart';
import '../providers/bico_provider.dart';
import '../providers/servicos_provider.dart';
import '../services/openai_marketing_service.dart';
import '../widgets/ai_sparkle.dart';
import '../widgets/top_bar.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _ai = OpenAIMarketingService();
  final _audienceController = TextEditingController();

  Servico? _selectedService;
  String _goal = 'Abrir horarios na agenda';
  String _tone = 'Simples e profissional';
  String _caption =
      'Escolha um servico e clique em Gerar com IA para criar uma divulgacao mais forte.';
  String _imagePrompt =
      'Post quadrado profissional para divulgar um prestador de servicos local.';
  List<String> _hashtags = const ['#servicos', '#agendaaberta', '#bico'];
  List<String> _visualTips = const [
    'Use uma foto clara do servico ou do resultado.',
    'Deixe a chamada principal bem curta.',
    'Mostre como a pessoa pode agendar.',
  ];
  final _channelActive = [true, true, false, false];
  Uint8List? _generatedImage;
  bool _generatingText = false;
  bool _generatingImage = false;
  bool _boosting = false;
  bool _didInitializeService = false;

  static const _goals = [
    'Abrir horarios na agenda',
    'Vender pacote promocional',
    'Divulgar novo servico',
    'Trazer clientes de volta',
    'Pedir indicacoes',
  ];

  static const _tones = [
    'Simples e profissional',
    'Amigavel e proximo',
    'Promocional direto',
    'Premium e cuidadoso',
  ];

  static const _channels = [
    'Instagram',
    'WhatsApp Status',
    'Facebook',
    'Email',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ServicosProvider>().loadServicos();
    });
  }

  @override
  void dispose() {
    _audienceController.dispose();
    super.dispose();
  }

  Future<void> _generateText() async {
    final notifier = context.read<BicoNotifier>();
    final channels = _selectedChannels();

    setState(() => _generatingText = true);
    try {
      final result = await _ai.generatePost(
        prestador: notifier.prestador,
        servico: _selectedService,
        goal: _goal,
        tone: _tone,
        audience: _audienceController.text,
        channels: channels,
      );

      if (!mounted) return;
      setState(() {
        _caption = result.caption;
        _hashtags = result.hashtags.isEmpty ? _hashtags : result.hashtags;
        _imagePrompt = result.imagePrompt.isEmpty
            ? _imagePrompt
            : result.imagePrompt;
        _visualTips = result.visualTips.isEmpty
            ? _visualTips
            : result.visualTips;
      });

      if (!_ai.isConfigured) {
        _toast('IA ainda nao configurada. Usei uma sugestao local.');
      } else if (_ai.isDirectBrowserMode) {
        _toast(
          'Modo dev: a chamada direta no navegador nao e segura para producao.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      _toast('Nao consegui gerar com IA: $e');
    } finally {
      if (mounted) setState(() => _generatingText = false);
    }
  }

  Future<void> _generateImage() async {
    setState(() => _generatingImage = true);
    try {
      final bytes = await _ai.generateImage(_imagePrompt);
      if (!mounted) return;
      if (bytes == null) {
        _toast(
          'Configure a IA para gerar a imagem. O prompt visual ja esta pronto.',
        );
      } else {
        setState(() => _generatedImage = bytes);
      }
    } catch (e) {
      if (!mounted) return;
      _toast('Nao consegui melhorar a imagem: $e');
    } finally {
      if (mounted) setState(() => _generatingImage = false);
    }
  }

  Future<void> _boostPost() async {
    setState(() => _boosting = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _boosting = false);
    _toast('Turbinar post: fluxo de impulsionamento em breve.');
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<BicoNotifier>().tokens;
    final notifier = context.watch<BicoNotifier>();
    final services = context
        .watch<ServicosProvider>()
        .servicos
        .where((service) => service.ativo && service.id.isNotEmpty)
        .toList();
    final seenServiceIds = <String>{};
    services.removeWhere((service) => !seenServiceIds.add(service.id));

    if (_selectedService != null &&
        !services.any((service) => service.id == _selectedService!.id)) {
      _selectedService = null;
    }
    if (!_didInitializeService && services.isNotEmpty) {
      _selectedService = services.first;
      _didInitializeService = true;
    }

    return Scaffold(
      backgroundColor: tokens.bg,
      body: SafeArea(
        child: Column(
          children: [
            BicoTopBar(
              title: 'Divulgar',
              subtitle: 'Crie texto e imagem com base no seu servico',
              leading: IconButton(
                tooltip: 'Fechar',
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close, size: 22, color: tokens.text),
              ),
              trailing: TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _postText()));
                  _toast('Texto copiado.');
                },
                icon: Icon(Icons.copy, size: 16, color: tokens.green),
                label: Text('Copiar', style: TextStyle(color: tokens.green)),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
                children: [
                  if (!_ai.isConfigured) _setupNotice(tokens),
                  _imagePreview(tokens),
                  const SizedBox(height: 14),
                  _briefing(tokens, services, notifier.prestador),
                  const SizedBox(height: 14),
                  _aiActions(tokens),
                  const SizedBox(height: 14),
                  _captionBox(tokens),
                  const SizedBox(height: 14),
                  _hashtagsBox(tokens),
                  const SizedBox(height: 14),
                  _visualTipsBox(tokens),
                  const SizedBox(height: 14),
                  _channelsBox(tokens),
                  const SizedBox(height: 14),
                  _boostBox(tokens),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _setupNotice(dynamic tokens) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: tokens.orangeSoft,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: tokens.orangeSoft),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.key_outlined, size: 18, color: tokens.orange),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'IA pronta, mas sem chave segura configurada. Use BICO_AI_ENDPOINT em producao ou OPENAI_API_KEY apenas em teste local.',
                style: TextStyle(
                  color: tokens.text,
                  fontSize: 12.5,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePreview(dynamic tokens) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: tokens.bgSoft,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: tokens.border),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _generatedImage == null
                  ? CustomPaint(
                      painter: _StripePainter(
                        color1: tokens.bgSoft,
                        color2: tokens.borderSoft,
                      ),
                      size: Size.infinite,
                    )
                  : Image.memory(
                      _generatedImage!,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
            ),
            if (_generatedImage == null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome_outlined,
                        size: 36,
                        color: tokens.textFaint,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Imagem sugerida por IA',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: tokens.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _imagePrompt,
                        textAlign: TextAlign.center,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: tokens.textFaint),
                      ),
                    ],
                  ),
                ),
              ),
            Positioned(
              right: 12,
              bottom: 12,
              child: GestureDetector(
                onTap: _generatingImage ? null : _generateImage,
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xD90F172A),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: _generatingImage
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.image_outlined,
                              size: 15,
                              color: Colors.white,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Melhorar imagem',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _briefing(
    dynamic tokens,
    List<Servico> services,
    Map<String, dynamic>? prestador,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.bgSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AISparkle(size: 14),
              const SizedBox(width: 8),
              Text(
                'Briefing da divulgacao',
                style: TextStyle(
                  color: tokens.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _miniInfo(
            tokens,
            'Prestador',
            prestador?['nome_completo'] ?? prestador?['categoria'] ?? 'Perfil',
          ),
          const SizedBox(height: 10),
          _dropdown<String?>(
            tokens: tokens,
            label: 'Servico',
            value: _selectedService?.id,
            items: [null, ...services.map((service) => service.id)],
            labelFor: (serviceId) =>
                serviceId == null
                    ? 'Divulgacao geral'
                    : _serviceById(services, serviceId)?.nome ?? 'Servico',
            onChanged: (value) => setState(
              () => _selectedService = _serviceById(services, value),
            ),
          ),
          const SizedBox(height: 10),
          _dropdown<String>(
            tokens: tokens,
            label: 'Objetivo',
            value: _goal,
            items: _goals,
            labelFor: (goal) => goal,
            onChanged: (value) => setState(() => _goal = value ?? _goal),
          ),
          const SizedBox(height: 10),
          _dropdown<String>(
            tokens: tokens,
            label: 'Tom',
            value: _tone,
            items: _tones,
            labelFor: (tone) => tone,
            onChanged: (value) => setState(() => _tone = value ?? _tone),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _audienceController,
            style: TextStyle(color: tokens.text, fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Publico ou detalhe opcional',
              hintText: 'Ex: maes ocupadas, clientes antigos, zona sul...',
              labelStyle: TextStyle(color: tokens.textMuted),
              hintStyle: TextStyle(color: tokens.textFaint),
              filled: true,
              fillColor: tokens.bg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: tokens.borderSoft),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: tokens.borderSoft),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: tokens.green),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _aiActions(dynamic tokens) {
    return Row(
      children: [
        Expanded(
          child: _actionButton(
            tokens: tokens,
            label: 'Gerar com IA',
            icon: Icons.auto_awesome,
            loading: _generatingText,
            color: tokens.orange,
            onTap: _generateText,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _actionButton(
            tokens: tokens,
            label: 'Melhorar imagem',
            icon: Icons.image_outlined,
            loading: _generatingImage,
            color: tokens.green,
            onTap: _generateImage,
          ),
        ),
      ],
    );
  }

  Widget _captionBox(dynamic tokens) {
    return _panel(
      tokens,
      title: 'Legenda',
      trailing: '${_caption.length}/2200',
      child: Text(
        _caption,
        style: TextStyle(fontSize: 14, color: tokens.text, height: 1.45),
      ),
    );
  }

  Widget _hashtagsBox(dynamic tokens) {
    return _panel(
      tokens,
      title: 'Hashtags',
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: _hashtags
            .map(
              (tag) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: tokens.purpleSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  tag.startsWith('#') ? tag : '#$tag',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: tokens.purple,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _visualTipsBox(dynamic tokens) {
    return _panel(
      tokens,
      title: 'Imagem',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _imagePrompt,
            style: TextStyle(color: tokens.text, fontSize: 13.5, height: 1.35),
          ),
          const SizedBox(height: 10),
          ..._visualTips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check, size: 15, color: tokens.green),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      tip,
                      style: TextStyle(color: tokens.textMuted, fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _channelsBox(dynamic tokens) {
    return _panel(
      tokens,
      title: 'Copiar para',
      child: Row(
        children: List.generate(_channels.length, (index) {
          final active = _channelActive[index];
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: index < _channels.length - 1 ? 8 : 0,
              ),
              child: GestureDetector(
                onTap: () => setState(() => _channelActive[index] = !active),
                child: Container(
                  height: 44,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: active ? tokens.greenSoft : tokens.bgSoft,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: active ? tokens.green : tokens.borderSoft,
                    ),
                  ),
                  child: Text(
                    _channels[index],
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: active ? tokens.green : tokens.textMuted,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _boostBox(dynamic tokens) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.greenSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.green.withAlpha(90)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: tokens.green,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.rocket_launch_outlined,
              color: Colors.white,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Turbinar post',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: tokens.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Use depois para impulsionar a divulgacao nos canais conectados.',
                  style: TextStyle(
                    fontSize: 12,
                    color: tokens.textMuted,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _smallButton(
            tokens: tokens,
            label: 'Turbinar',
            loading: _boosting,
            onTap: _boostPost,
          ),
        ],
      ),
    );
  }

  Servico? _serviceById(List<Servico> services, String? id) {
    if (id == null) return null;
    for (final service in services) {
      if (service.id == id) return service;
    }
    return null;
  }

  Widget _panel(
    dynamic tokens, {
    required String title,
    String? trailing,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.bgSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: tokens.text,
                ),
              ),
              const Spacer(),
              if (trailing != null)
                Text(
                  trailing,
                  style: TextStyle(fontSize: 12, color: tokens.textFaint),
                ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _dropdown<T>({
    required dynamic tokens,
    required String label,
    required T value,
    required List<T> items,
    required String Function(T item) labelFor,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: tokens.textMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: tokens.bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: tokens.borderSoft),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              dropdownColor: tokens.bg,
              style: TextStyle(color: tokens.text, fontSize: 14),
              items: items
                  .map(
                    (item) => DropdownMenuItem<T>(
                      value: item,
                      child: Text(labelFor(item)),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _miniInfo(dynamic tokens, String label, dynamic value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            color: tokens.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        Expanded(
          child: Text(
            (value ?? 'Nao informado').toString(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: tokens.text, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required dynamic tokens,
    required String label,
    required IconData icon,
    required bool loading,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 17),
                  const SizedBox(width: 7),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _smallButton({
    required dynamic tokens,
    required String label,
    required bool loading,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: tokens.green,
          borderRadius: BorderRadius.circular(8),
        ),
        child: loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }

  List<String> _selectedChannels() {
    final selected = <String>[];
    for (var i = 0; i < _channels.length; i++) {
      if (_channelActive[i]) selected.add(_channels[i]);
    }
    return selected.isEmpty ? ['Instagram'] : selected;
  }

  String _postText() {
    return [
      _caption,
      if (_hashtags.isNotEmpty)
        _hashtags.map((tag) => tag.startsWith('#') ? tag : '#$tag').join(' '),
    ].join('\n\n');
  }

  void _toast(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
    for (
      double x = -size.height;
      x < size.width + size.height;
      x += stripeWidth * 2
    ) {
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
