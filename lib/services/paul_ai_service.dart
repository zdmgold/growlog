import 'dart:typed_data';
import '../models/plant_model.dart';
import 'ai/ai_client.dart';
import 'ai/ai_settings.dart';

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
    final client = AiSettings.instance.client;
    if (client == null) {
      return 'Add your API key to chat with me. Tap the key card on the home screen.';
    }
    _memory.add(ChatMessage(role: 'user', text: userMessage));
    try {
      final reply = await client.complete(
        system: _buildSystemPrompt(),
        messages: [
          for (final m in _memory)
            AiMessage(m.role == 'user' ? 'user' : 'assistant', m.text),
        ],
      );
      _memory.add(ChatMessage(role: 'model', text: reply));
      return reply;
    } on AiException catch (e) {
      _memory.removeLast();
      return 'I could not answer: ${e.message}';
    }
  }

  /// Analyze a plant photo with the user's chosen AI provider.
  /// Throws [AiException] with a plain-language message on failure.
  Future<DiagnosisResult> diagnosePlant(Uint8List imageBytes) async {
    final settings = AiSettings.instance;
    final client = settings.client;
    if (client == null) {
      throw const AiException('Add your API key first to scan plants.');
    }
    if (!settings.supportsVision) {
      throw const AiException(
        'The connected AI model cannot read photos. Connect a different provider or model.',
      );
    }

    const prompt = '''
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

    final text = await client.complete(
      messages: const [AiMessage('user', prompt)],
      image: imageBytes,
      maxTokens: 900,
    );
    return _parseDiagnosis(text);
  }

  DiagnosisResult _parseDiagnosis(String raw) {
    String condition = 'Unknown condition';
    String severity = 'Low';
    String description = 'Unable to parse diagnosis details.';
    final treatmentSteps = <String>[];
    final preventionTips = <String>[];

    final lines = raw
        .replaceAll('**', '')
        .replaceAll('#', '')
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty);

    String? currentSection;
    for (final line in lines) {
      final up = line.toUpperCase();
      if (up.startsWith('DIAGNOSIS:')) {
        condition = line.substring('DIAGNOSIS:'.length).trim();
      } else if (up.startsWith('SEVERITY:')) {
        severity = line.substring('SEVERITY:'.length).trim();
      } else if (up.startsWith('DESCRIPTION:')) {
        description = line.substring('DESCRIPTION:'.length).trim();
      } else if (up.startsWith('TREATMENT')) {
        currentSection = 'treatment';
      } else if (up.startsWith('PREVENTION')) {
        currentSection = 'prevention';
      } else if (RegExp(r'^(-|\u2022|\d+[.)])\s*').hasMatch(line)) {
        final clean = line.replaceFirst(RegExp(r'^(-|\u2022|\d+[.)])\s*'), '').trim();
        if (clean.isEmpty) continue;
        if (currentSection == 'treatment') treatmentSteps.add(clean);
        if (currentSection == 'prevention') preventionTips.add(clean);
      }
    }

    return DiagnosisResult(
      condition: condition,
      severity: severity,
      description: description,
      treatmentSteps: treatmentSteps.isEmpty
          ? ['Consult a local nursery for hands-on advice.']
          : treatmentSteps,
      preventionTips: preventionTips.isEmpty
          ? ['Monitor your plant regularly.']
          : preventionTips,
    );
  }
}
