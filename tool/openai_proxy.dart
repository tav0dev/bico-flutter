import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final apiKey = Platform.environment['OPENAI_API_KEY'];
  if (apiKey == null || apiKey.trim().isEmpty) {
    stderr.writeln('OPENAI_API_KEY nao configurada.');
    exitCode = 1;
    return;
  }

  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8787);
  stdout.writeln('Bico AI proxy em http://localhost:8787');

  await for (final request in server) {
    _cors(request.response);

    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.noContent;
      await request.response.close();
      continue;
    }

    if (request.method != 'POST') {
      await _json(request.response, HttpStatus.methodNotAllowed, {
        'message': 'Use POST.',
      });
      continue;
    }

    try {
      final raw = await utf8.decoder.bind(request).join();
      final payload = jsonDecode(raw) as Map<String, dynamic>;
      final action = payload['action']?.toString();

      if (action == 'generate_image') {
        final result = await _generateImage(apiKey, payload);
        await _json(request.response, HttpStatus.ok, result);
      } else {
        final result = await _generatePost(apiKey, payload);
        await _json(request.response, HttpStatus.ok, result);
      }
    } catch (error) {
      await _json(request.response, HttpStatus.internalServerError, {
        'message': error.toString(),
      });
    }
  }
}

Future<Map<String, dynamic>> _generatePost(
  String apiKey,
  Map<String, dynamic> payload,
) async {
  final client = HttpClient();
  try {
    final request = await client.postUrl(
      Uri.parse('https://api.openai.com/v1/responses'),
    );
    request.headers
      ..set(HttpHeaders.authorizationHeader, 'Bearer $apiKey')
      ..set(HttpHeaders.contentTypeHeader, 'application/json');

    request.write(
      jsonEncode({
        'model': Platform.environment['OPENAI_TEXT_MODEL'] ?? 'gpt-5-mini',
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

    final response = await request.close();
    final body = await utf8.decoder.bind(response).join();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_errorMessage(body, response.statusCode));
    }

    final decoded = jsonDecode(body) as Map<String, dynamic>;
    final text = _extractOutputText(decoded);
    return jsonDecode(text) as Map<String, dynamic>;
  } finally {
    client.close(force: true);
  }
}

Future<Map<String, dynamic>> _generateImage(
  String apiKey,
  Map<String, dynamic> payload,
) async {
  final prompt = payload['prompt']?.toString().trim();
  if (prompt == null || prompt.isEmpty) {
    throw Exception('Prompt vazio.');
  }

  final client = HttpClient();
  try {
    final request = await client.postUrl(
      Uri.parse('https://api.openai.com/v1/images/generations'),
    );
    request.headers
      ..set(HttpHeaders.authorizationHeader, 'Bearer $apiKey')
      ..set(HttpHeaders.contentTypeHeader, 'application/json');

    request.write(
      jsonEncode({
        'model': Platform.environment['OPENAI_IMAGE_MODEL'] ?? 'gpt-image-1',
        'prompt': prompt,
        'size': '1024x1024',
      }),
    );

    final response = await request.close();
    final body = await utf8.decoder.bind(response).join();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_errorMessage(body, response.statusCode));
    }

    final decoded = jsonDecode(body) as Map<String, dynamic>;
    final data = decoded['data'];
    if (data is! List || data.isEmpty) {
      throw Exception('Resposta de imagem sem dados.');
    }
    return {'b64_json': data.first['b64_json']};
  } finally {
    client.close(force: true);
  }
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

String _errorMessage(String body, int statusCode) {
  try {
    final decoded = jsonDecode(body);
    final message = decoded['error']?['message'] ?? decoded['message'];
    if (message != null) return message.toString();
  } catch (_) {}
  return 'Erro $statusCode ao chamar IA.';
}

Future<void> _json(
  HttpResponse response,
  int statusCode,
  Map<String, dynamic> body,
) async {
  response.statusCode = statusCode;
  response.headers.contentType = ContentType.json;
  response.write(jsonEncode(body));
  await response.close();
}

void _cors(HttpResponse response) {
  response.headers
    ..set('Access-Control-Allow-Origin', '*')
    ..set('Access-Control-Allow-Methods', 'POST, OPTIONS')
    ..set('Access-Control-Allow-Headers', 'Content-Type');
}

const _schema = {
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
