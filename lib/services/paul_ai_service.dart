import '../models/plant_model.dart';
import 'ai/ai_client.dart';
import 'ai/ai_settings.dart';

class ChatMessage {
  final String role;
  final String text;
  ChatMessage({required this.role, required this.text});
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
      'You speak like a knowledgeable plant expert: concise, practical and honest about uncertainty. '
      'Never use emojis. Write plain, calm sentences. Keep responses under 150 words unless asked for detail.',
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
}
