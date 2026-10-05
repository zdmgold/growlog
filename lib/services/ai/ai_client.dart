import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'ai_providers.dart';

class AiException implements Exception {
  final String message;
  final int? status;
  const AiException(this.message, {this.status});

  bool get isAuth => status == 401 || status == 403;

  @override
  String toString() => message;
}

class AiMessage {
  /// 'user' or 'assistant'.
  final String role;
  final String text;
  const AiMessage(this.role, this.text);
}

/// A model the provider offers, with an optional hint about image input.
class AiModel {
  final String id;
  final DateTime? created;
  final bool? imageInput;
  const AiModel(this.id, {this.created, this.imageInput});
}

const _timeout = Duration(seconds: 60);

/// Talks to one provider with one key. Never logs or returns the key.
class AiClient {
  final AiProvider provider;
  final String apiKey;
  final String model;

  const AiClient({
    required this.provider,
    required this.apiKey,
    required this.model,
  });

  Future<String> complete({
    String? system,
    required List<AiMessage> messages,
    Uint8List? image,
    String imageMime = 'image/jpeg',
    int maxTokens = 1000,
  }) async {
    switch (provider.format) {
      case ApiFormat.anthropic:
        return _anthropic(system, messages, image, imageMime, maxTokens);
      case ApiFormat.gemini:
        return _gemini(system, messages, image, imageMime, maxTokens);
      case ApiFormat.openai:
        return _openai(system, messages, image, imageMime);
    }
  }

  // ---- Anthropic ----------------------------------------------------------

  Future<String> _anthropic(
    String? system,
    List<AiMessage> messages,
    Uint8List? image,
    String mime,
    int maxTokens,
  ) async {
    final msgs = <Map<String, dynamic>>[];
    for (var i = 0; i < messages.length; i++) {
      final m = messages[i];
      final isLastUser = i == messages.length - 1 && m.role == 'user';
      if (isLastUser && image != null) {
        msgs.add({
          'role': 'user',
          'content': [
            {
              'type': 'image',
              'source': {
                'type': 'base64',
                'media_type': mime,
                'data': base64Encode(image),
              },
            },
            {'type': 'text', 'text': m.text},
          ],
        });
      } else {
        msgs.add({'role': m.role, 'content': m.text});
      }
    }
    final body = {
      'model': model,
      'max_tokens': maxTokens,
      if (system != null && system.isNotEmpty) 'system': system,
      'messages': msgs,
    };
    final json = await _post(
      Uri.parse('${provider.baseUrl}/v1/messages'),
      {
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      },
      body,
    );
    final content = json['content'];
    if (content is List) {
      final text = content
          .whereType<Map>()
          .where((b) => b['type'] == 'text')
          .map((b) => b['text']?.toString() ?? '')
          .join('\n')
          .trim();
      if (text.isNotEmpty) return text;
    }
    throw const AiException('The AI returned an empty answer.');
  }

  // ---- Gemini -------------------------------------------------------------

  Future<String> _gemini(
    String? system,
    List<AiMessage> messages,
    Uint8List? image,
    String mime,
    int maxTokens,
  ) async {
    final contents = <Map<String, dynamic>>[];
    for (var i = 0; i < messages.length; i++) {
      final m = messages[i];
      final isLastUser = i == messages.length - 1 && m.role == 'user';
      final parts = <Map<String, dynamic>>[
        {'text': m.text},
        if (isLastUser && image != null)
          {
            'inlineData': {'mimeType': mime, 'data': base64Encode(image)},
          },
      ];
      contents.add({
        'role': m.role == 'assistant' ? 'model' : 'user',
        'parts': parts,
      });
    }
    final body = {
      if (system != null && system.isNotEmpty)
        'systemInstruction': {
          'parts': [
            {'text': system},
          ],
        },
      'contents': contents,
      'generationConfig': {'maxOutputTokens': maxTokens},
    };
    final json = await _post(
      Uri.parse('${provider.baseUrl}/v1beta/models/$model:generateContent'),
      {'x-goog-api-key': apiKey, 'content-type': 'application/json'},
      body,
    );
    final candidates = json['candidates'];
    if (candidates is List && candidates.isNotEmpty) {
      final parts = (candidates.first as Map)['content']?['parts'];
      if (parts is List) {
        final text = parts
            .whereType<Map>()
            .map((p) => p['text']?.toString() ?? '')
            .join('')
            .trim();
        if (text.isNotEmpty) return text;
      }
    }
    throw const AiException('The AI returned an empty answer.');
  }

  // ---- OpenAI-style (OpenAI, xAI, Mistral, Groq, OpenRouter, Cerebras) -----

  Future<String> _openai(
    String? system,
    List<AiMessage> messages,
    Uint8List? image,
    String mime,
  ) async {
    final msgs = <Map<String, dynamic>>[];
    if (system != null && system.isNotEmpty) {
      msgs.add({'role': 'system', 'content': system});
    }
    for (var i = 0; i < messages.length; i++) {
      final m = messages[i];
      final isLastUser = i == messages.length - 1 && m.role == 'user';
      if (isLastUser && image != null) {
        msgs.add({
          'role': 'user',
          'content': [
            {'type': 'text', 'text': m.text},
            {
              'type': 'image_url',
              'image_url': {'url': 'data:$mime;base64,${base64Encode(image)}'},
            },
          ],
        });
      } else {
        msgs.add({'role': m.role, 'content': m.text});
      }
    }
    final json = await _post(
      Uri.parse('${provider.baseUrl}/chat/completions'),
      {
        'Authorization': 'Bearer $apiKey',
        'content-type': 'application/json',
      },
      {'model': model, 'messages': msgs},
    );
    final choices = json['choices'];
    if (choices is List && choices.isNotEmpty) {
      final content = (choices.first as Map)['message']?['content'];
      if (content is String && content.trim().isNotEmpty) return content.trim();
      if (content is List) {
        final text = content
            .whereType<Map>()
            .map((p) => p['text']?.toString() ?? '')
            .join('')
            .trim();
        if (text.isNotEmpty) return text;
      }
    }
    throw const AiException('The AI returned an empty answer.');
  }

  // ---- Shared HTTP ----------------------------------------------------------

  Future<Map<String, dynamic>> _post(
    Uri url,
    Map<String, String> headers,
    Map<String, dynamic> body,
  ) async {
    return AiHttp.send(
      () => http.post(url, headers: headers, body: jsonEncode(body)),
    );
  }

  // ---- Model discovery --------------------------------------------------------

  static Future<List<AiModel>> listModels(AiProvider p, String key) async {
    switch (p.format) {
      case ApiFormat.anthropic:
        final json = await AiHttp.send(
          () => http.get(
            Uri.parse('${p.baseUrl}/v1/models?limit=100'),
            headers: {'x-api-key': key, 'anthropic-version': '2023-06-01'},
          ),
        );
        return _readModels(json['data'], idKey: 'id');
      case ApiFormat.gemini:
        final json = await AiHttp.send(
          () => http.get(
            Uri.parse('${p.baseUrl}/v1beta/models?pageSize=200'),
            headers: {'x-goog-api-key': key},
          ),
        );
        final raw = json['models'];
        final out = <AiModel>[];
        if (raw is List) {
          for (final m in raw.whereType<Map>()) {
            final methods = m['supportedGenerationMethods'];
            final name = m['name']?.toString() ?? '';
            if (methods is List && methods.contains('generateContent')) {
              out.add(AiModel(name.replaceFirst('models/', '')));
            }
          }
        }
        return out;
      case ApiFormat.openai:
        final json = await AiHttp.send(
          () => http.get(
            Uri.parse('${p.baseUrl}/models'),
            headers: {'Authorization': 'Bearer $key'},
          ),
        );
        return _readModels(json['data'], idKey: 'id');
    }
  }

  static List<AiModel> _readModels(dynamic raw, {required String idKey}) {
    final out = <AiModel>[];
    if (raw is! List) return out;
    for (final m in raw.whereType<Map>()) {
      final id = m[idKey]?.toString();
      if (id == null || id.isEmpty) continue;
      DateTime? created;
      final c = m['created'] ?? m['created_at'];
      if (c is int) {
        created = DateTime.fromMillisecondsSinceEpoch(c * 1000, isUtc: true);
      } else if (c is String) {
        created = DateTime.tryParse(c);
      }
      bool? image;
      final modalities = m['architecture'] is Map
          ? (m['architecture'] as Map)['input_modalities']
          : null;
      if (modalities is List) image = modalities.contains('image');
      out.add(AiModel(id, created: created, imageInput: image));
    }
    return out;
  }
}

/// Sends a request and turns any failure into a plain-language [AiException].
class AiHttp {
  static Future<Map<String, dynamic>> send(
    Future<http.Response> Function() request,
  ) async {
    http.Response res;
    try {
      res = await request().timeout(_timeout);
    } on AiException {
      rethrow;
    } catch (_) {
      throw const AiException(
        'Could not reach the AI service. Check your internet connection.',
      );
    }
    Map<String, dynamic> json = {};
    try {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      if (decoded is Map<String, dynamic>) json = decoded;
    } catch (_) {}
    if (res.statusCode >= 200 && res.statusCode < 300) return json;

    final detail = _errorDetail(json);
    switch (res.statusCode) {
      case 401:
      case 403:
        throw AiException('That key was not accepted. $detail'.trim(),
            status: res.statusCode);
      case 429:
        throw AiException(
            'Rate limit or quota reached for this key. $detail'.trim(),
            status: 429);
      default:
        throw AiException(
          detail.isEmpty ? 'The AI service returned an error (${res.statusCode}).' : detail,
          status: res.statusCode,
        );
    }
  }

  static String _errorDetail(Map<String, dynamic> json) {
    final e = json['error'];
    if (e is Map && e['message'] != null) return e['message'].toString();
    if (e is String) return e;
    if (json['message'] != null) return json['message'].toString();
    return '';
  }
}
