import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/servico.dart';

class MarketingAiResult {
  final String caption;
  final List<String> hashtags;
  final String imagePrompt;
  final List<String> visualTips;

  const MarketingAiResult({
    required this.caption,
    required this.hashtags,
    required this.imagePrompt,
    required this.visualTips,
  });

  factory MarketingAiResult.fromJson(Map<String, dynamic> json) {
    return MarketingAiResult(
      caption: (json['caption'] ?? '').toString().trim(),
      hashtags: _stringList(json['hashtags']),
      imagePrompt: (json['image_prompt'] ?? '').toString().trim(),
      visualTips: _stringList(json['visual_tips']),
    );
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
}

class OpenAIMarketingService {
  static const _openAiApiKey = String.fromEnvironment('OPENAI_API_KEY');
  static const _aiEndpoint = String.fromEnvironment('BICO_AI_ENDPOINT');
  static const _textModel = String.fromEnvironment(
    'OPENAI_TEXT_MODEL',
    defaultValue: 'gpt-5-mini',
  );
  static const _imageModel = String.fromEnvironment(
    'OPENAI_IMAGE_MODEL',
    defaultValue: 'gpt-image-1',
  );

  bool get isConfigured =>
      _aiEndpoint.trim().isNotEmpty || _openAiApiKey.trim().isNotEmpty;

  bool get isDirectBrowserMode =>
      _aiEndpoint.trim().isEmpty && _openAiApiKey.trim().isNotEmpty;

  Future<MarketingAiResult> generatePost({
    required Map<String, dynamic>? prestador,
    required Servico? servico,
    required String goal,
    required String tone,
    required String audience,
    required List<String> channels,
  }) async {
    final payload = _payload(
      action: 'generate_post',
      prestador: prestador,
      servico: servico,
      goal: goal,
      tone: tone,
      audience: audience,
      channels: channels,
    );

    if (_aiEndpoint.trim().isNotEmpty) {
      return _fromProxy(payload);
    }

    if (_openAiApiKey.trim().isEmpty) {
      return _localFallback(payload);
    }

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/responses'),
      headers: {
        'Authorization': 'Bearer $_openAiApiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': _textModel,
        'input': [
          {
            'role': 'system',
            'content': [
              {
                'type': 'input_text',
                'text':
                    'Voce e um estrategista de marketing para prestadores de servico no Brasil. Escreva em portugues brasileiro, simples, direto e vendavel. Nao invente promessas, resultados ou dados. Responda apenas JSON valido.',
              },
            ],
          },
          {
            'role': 'user',
            'content': [
              {'type': 'input_text', 'text': _promptFromPayload(payload)},
            ],
          },
        ],
        'text': {
          'format': {
            'type': 'json_schema',
            'name': 'marketing_post',
            'strict': true,
            'schema': _schema,
          },
        },
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_errorMessage(response));
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final text = _extractOutputText(body);
    return MarketingAiResult.fromJson(jsonDecode(text) as Map<String, dynamic>);
  }

  Future<Uint8List?> generateImage(String prompt) async {
    if (_aiEndpoint.trim().isNotEmpty) {
      final response = await http.post(
        Uri.parse(_aiEndpoint),
        headers: _proxyHeaders(),
        body: jsonEncode({'action': 'generate_image', 'prompt': prompt}),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(_errorMessage(response));
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final b64 = body['b64_json']?.toString();
      return b64 == null || b64.isEmpty ? null : base64Decode(b64);
    }

    if (_openAiApiKey.trim().isEmpty) return null;

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/images/generations'),
      headers: {
        'Authorization': 'Bearer $_openAiApiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': _imageModel,
        'prompt': prompt,
        'size': '1024x1024',
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_errorMessage(response));
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'];
    if (data is! List || data.isEmpty) return null;
    final b64 = data.first['b64_json']?.toString();
    return b64 == null || b64.isEmpty ? null : base64Decode(b64);
  }

  Map<String, dynamic> _payload({
    required String action,
    required Map<String, dynamic>? prestador,
    required Servico? servico,
    required String goal,
    required String tone,
    required String audience,
    required List<String> channels,
  }) {
    return {
      'action': action,
      'goal': goal,
      'tone': tone,
      'audience': audience.trim().isEmpty ? 'clientes locais' : audience.trim(),
      'channels': channels,
      'provider': {
        'name': prestador?['nome_completo'],
        'category': prestador?['categoria'],
        'city': prestador?['cidade'],
        'state': prestador?['estado'],
        'bio': prestador?['bio'],
      },
      'service': servico == null
          ? null
          : {
              'name': servico.nome,
              'description': servico.descricao,
              'duration_minutes': servico.duracaoMinutos,
              'price_cents': servico.precoCentavos,
            },
    };
  }

  Future<MarketingAiResult> _fromProxy(Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse(_aiEndpoint),
      headers: _proxyHeaders(),
      body: jsonEncode(payload),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_errorMessage(response));
    }
    return MarketingAiResult.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Map<String, String> _proxyHeaders() {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    return {
      'Content-Type': 'application/json',
      if (token != null && token.trim().isNotEmpty)
        'Authorization': 'Bearer $token',
    };
  }

  MarketingAiResult _localFallback(Map<String, dynamic> payload) {
    final provider = payload['provider'] as Map<String, dynamic>;
    final service = payload['service'] as Map<String, dynamic>?;
    final name = service?['name'] ?? provider['category'] ?? 'seu atendimento';
    final city = provider['city'] == null ? '' : ' em ${provider['city']}';
    final goal = payload['goal'];
    final duration = service?['duration_minutes'];
    final durationText = duration == null ? '' : '\nDuracao: $duration min';

    return MarketingAiResult(
      caption:
          'Agenda aberta para $name$city.\n\n$goal\n$durationText\n\nMe chame para tirar duvidas e reservar seu horario.',
      hashtags: ['#servicos', '#agendaaberta', '#atendimento', '#bico'],
      imagePrompt:
          'Post quadrado profissional para divulgar $name$city, visual limpo, claro, com foco em confianca e agenda aberta.',
      visualTips: const [
        'Use uma foto clara do servico ou do resultado.',
        'Coloque pouco texto na imagem.',
        'Mostre cidade, beneficio e chamada para agendar.',
      ],
    );
  }

  String _promptFromPayload(Map<String, dynamic> payload) {
    return '''
Crie uma divulgacao para um prestador de servicos.

Dados:
${const JsonEncoder.withIndent('  ').convert(payload)}

Retorne:
- caption: legenda pronta, natural, com chamada para agendar.
- hashtags: 5 a 8 hashtags curtas, sem acentos se possivel.
- image_prompt: prompt detalhado para gerar uma imagem/post quadrado profissional.
- visual_tips: 3 dicas curtas para melhorar a imagem atual.
''';
  }

  String _extractOutputText(Map<String, dynamic> body) {
    final direct = body['output_text']?.toString();
    if (direct != null && direct.trim().isNotEmpty) return direct;

    final output = body['output'];
    if (output is List) {
      for (final item in output) {
        if (item is! Map<String, dynamic>) continue;
        final content = item['content'];
        if (content is! List) continue;
        for (final part in content) {
          if (part is! Map<String, dynamic>) continue;
          final text = part['text']?.toString();
          if (text != null && text.trim().isNotEmpty) return text;
        }
      }
    }

    throw Exception('A IA respondeu sem texto utilizavel.');
  }

  String _errorMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      final message = body['error']?['message'] ?? body['message'];
      if (message != null) return message.toString();
    } catch (_) {}
    return 'Erro ${response.statusCode} ao chamar IA.';
  }

  static const _schema = {
    'type': 'object',
    'additionalProperties': false,
    'properties': {
      'caption': {'type': 'string'},
      'hashtags': {
        'type': 'array',
        'items': {'type': 'string'},
      },
      'image_prompt': {'type': 'string'},
      'visual_tips': {
        'type': 'array',
        'items': {'type': 'string'},
      },
    },
    'required': ['caption', 'hashtags', 'image_prompt', 'visual_tips'],
  };
}
