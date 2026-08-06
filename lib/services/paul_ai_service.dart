import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import '../config/ai_config.dart';
import '../models/plant_model.dart';

class ChatMessage {
  final String role;
  final String text;
  ChatMessage({required this.role, required this.text});
}

class DiagnosisResult {
  final String condition;
  final String severity;
  final String description;
  final List<String> treatmentSteps;
  final List<String> preventionTips;

  DiagnosisResult({
    required this.condition,
    required this.severity,
    required this.description,
    required this.treatmentSteps,
    required this.preventionTips,
  });
}

class PaulAIService {
  final List<ChatMessage> _memory = [];
  List<Plant> _plants = [];
  Plant? _focusedPlant;

  void setPlantsContext(List<Plant> plants) => _plants = plants;
  void setFocusedPlant(Plant plant) => _focusedPlant = plant;
  void clearMemory() => _memory.clear();

  List<ChatMessage> get memory => List.unmodifiable(_memory);

  String _buildSystemPrompt() {
    final buffer = StringBuffer();
    buffer.writeln(
      'You are Paul, a warm, knowledgeable plant care assistant inside the GrowLog app. '
      'You speak like a friendly expert — concise, encouraging, and practical. '
      'Use occasional emojis. Keep responses under 150 words unless asked for detail.',
    );

    if (_plants.isNotEmpty) {
      buffer.writeln('\nThe user\'s garden:');
      for (final p in _plants.where((p) => !p.isDead)) {
        buffer.write('- ${p.name}');
        if (p.species != null) buffer.write(' (${p.species})');
        if (p.notes != null && p.notes!.isNotEmpty) {
          buffer.write(' — Notes: ${p.notes}');
        }
        buffer.writeln();
      }
    }

    if (_focusedPlant != null) {
      final p = _focusedPlant!;
      buffer.writeln(
        '\nThe user is currently viewing ${p.name}. '
        'Water every ${p.waterFrequencyDays} days. '
        'Fertilize every ${p.fertilizeFrequencyDays} days. '
        'Mist every ${p.mistFrequencyDays} days.',
      );
    }

    buffer.writeln(
      '\nIf asked about a specific plant, reference it by name. '
      'If the user seems worried, be reassuring. '
      'Never make up scientific studies — rely on general horticultural knowledge.',
    );

    return buffer.toString();
  }

  /// Send a text message. Returns Paul's response.
  Future<String> sendMessage(String userMessage) async {
    _memory.add(ChatMessage(role: 'user', text: userMessage));

    // Try Gemini first
    try {
      final response = await _askGemini(userMessage);
      _memory.add(ChatMessage(role: 'model', text: response));
      return response;
    } catch (e) {
      // Vision not supported on fallbacks — handled separately
    }

    // Fallback chain
    final fallbacks = [
      _askGroq,
      _askCerebras,
      _askOpenRouter,
    ];

    for (final fallback in fallbacks) {
      try {
        final response = await fallback(userMessage);
        _memory.add(ChatMessage(role: 'model', text: response));
        return response;
      } catch (e) {
        continue;
      }
    }

    const errorMsg =
        'Sorry, all AI services are resting right now. 🌙 Try again in a minute!';
    _memory.add(ChatMessage(role: 'model', text: errorMsg));
    return errorMsg;
  }

  /// Analyze a plant photo using Gemini Vision.
  Future<DiagnosisResult> diagnosePlant(Uint8List imageBytes) async {
    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: AIConfig.geminiApiKey,
    );

    final prompt = '''
You are Paul, a plant health expert. Analyze this plant photo carefully.
Identify visible diseases, pests, nutrient deficiencies, or environmental stress.

Respond in this EXACT format:

DIAGNOSIS: [condition name]
SEVERITY: [Low / Medium / High / Critical]
DESCRIPTION: [2-3 sentences]
TREATMENT:
1. [step]
2. [step]
3. [step]
PREVENTION:
1. [tip]
2. [tip]
''';

    final content = Content.multi([
      TextPart(prompt),
      DataPart('image/jpeg', imageBytes),
    ]);

    final response = await model.generateContent([content]);
    final text = response.text ?? 'No response from vision model.';

    return _parseDiagnosis(text);
  }

  // ─── Gemini (Primary) ───
  Future<String> _askGemini(String message) async {
    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: AIConfig.geminiApiKey,
      systemInstruction: Content.text(_buildSystemPrompt()),
    );

    final history = _memory
        .where((m) => m.role != 'error')
        .map((m) => Content(m.role, [TextPart(m.text)]))
        .toList();

    final chat = model.startChat(history: history);
    final response = await chat.sendMessage(Content.text(message));
    return response.text ?? 'Hmm, I\'m not sure about that. 🤔';
  }

  // ─── Groq (Fallback 1) ───
  Future<String> _askGroq(String message) async {
    return _askOpenAICompatible(
      baseUrl: AIConfig.groqBaseUrl,
      apiKey: AIConfig.groqApiKey,
      model: AIConfig.groqModel,
      message: message,
    );
  }

  // ─── Cerebras (Fallback 2) ───
  Future<String> _askCerebras(String message) async {
    return _askOpenAICompatible(
      baseUrl: AIConfig.cerebrasBaseUrl,
      apiKey: AIConfig.cerebrasApiKey,
      model: AIConfig.cerebrasModel,
      message: message,
    );
  }

  // ─── OpenRouter (Fallback 3) ───
  Future<String> _askOpenRouter(String message) async {
    return _askOpenAICompatible(
      baseUrl: AIConfig.openRouterBaseUrl,
      apiKey: AIConfig.openRouterApiKey,
      model: AIConfig.openRouterModel,
      message: message,
      extraHeaders: {
        'HTTP-Referer': 'https://github.com/zdmgold/growlog',
        'X-Title': 'GrowLog',
      },
    );
  }

  Future<String> _askOpenAICompatible({
    required String baseUrl,
    required String apiKey,
    required String model,
    required String message,
    Map<String, String>? extraHeaders,
  }) async {
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': _buildSystemPrompt()},
      ..._memory.map((m) => {'role': m.role, 'content': m.text}),
    ];

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
        ...?extraHeaders,
      },
      body: jsonEncode({
        'model': model,
        'messages': messages,
        'temperature': 0.7,
        'max_tokens': 512,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['choices'] as List).first['message']['content'] as String;
  }

  DiagnosisResult _parseDiagnosis(String raw) {
    String condition = 'Unknown condition';
    String severity = 'Low';
    String description = 'Unable to parse diagnosis details.';
    final treatmentSteps = <String>[];
    final preventionTips = <String>[];

    final lines = raw.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty);

    String? currentSection;
    for (final line in lines) {
      if (line.startsWith('DIAGNOSIS:')) {
        condition = line.substring('DIAGNOSIS:'.length).trim();
      } else if (line.startsWith('SEVERITY:')) {
        severity = line.substring('SEVERITY:'.length).trim();
      } else if (line.startsWith('DESCRIPTION:')) {
        description = line.substring('DESCRIPTION:'.length).trim();
      } else if (line == 'TREATMENT:') {
        currentSection = 'treatment';
      } else if (line == 'PREVENTION:') {
        currentSection = 'prevention';
      } else if (line.startsWith('- ') || line.startsWith('1.') || line.startsWith('2.') || line.startsWith('3.')) {
        final clean = line.replaceFirst(RegExp(r'^[-\d.\s]+'), '').trim();
        if (currentSection == 'treatment') treatmentSteps.add(clean);
        if (currentSection == 'prevention') preventionTips.add(clean);
      }
    }

    return DiagnosisResult(
      condition: condition,
      severity: severity,
      description: description,
      treatmentSteps: treatmentSteps.isEmpty ? ['Consult a local nursery for hands-on advice.'] : treatmentSteps,
      preventionTips: preventionTips.isEmpty ? ['Monitor your plant regularly.'] : preventionTips,
    );
  }
}
