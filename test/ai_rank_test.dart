import 'package:flutter_test/flutter_test.dart';
import 'package:growlog/services/ai/ai_client.dart';
import 'package:growlog/services/ai/ai_providers.dart';
import 'package:growlog/services/ai/ai_settings.dart';

List<AiModel> models(List<String> ids) => ids.map(AiModel.new).toList();

void main() {
  test('every provider has a unique id and an https base URL', () {
    final ids = aiProviders.map((p) => p.id).toSet();
    expect(ids.length, aiProviders.length);
    for (final p in aiProviders) {
      expect(p.baseUrl.startsWith('https://'), isTrue, reason: p.id);
      expect(p.keyUrl.startsWith('https://'), isTrue, reason: p.id);
    }
  });

  test('providerById finds a provider and returns null otherwise', () {
    expect(providerById('gemini')?.name, 'Google Gemini');
    expect(providerById('nope'), isNull);
    expect(providerById(null), isNull);
  });

  test('groq prefers a vision model and drops audio models', () {
    final p = providerById('groq')!;
    final ranked = rankModels(p, models([
      'llama-3.3-70b-versatile',
      'whisper-large-v3',
      'meta-llama/llama-4-scout-17b-16e-instruct',
      'qwen/qwen3.8-27b',
    ]));
    expect(ranked.first, 'qwen/qwen3.8-27b');
    expect(ranked, contains('meta-llama/llama-4-scout-17b-16e-instruct'));
    expect(ranked, isNot(contains('whisper-large-v3')));
  });

  test('cerebras prefers its documented multimodal models', () {
    final p = providerById('cerebras')!;
    final ranked = rankModels(p, models([
      'llama3.1-8b',
      'gpt-oss-120b',
      'qwen-3.8-27b',
      'gemma-4-31b',
    ]));
    expect(ranked.take(2).toSet(), {'qwen-3.8-27b', 'gemma-4-31b'});
  });

  test('mistral ranks pixtral and medium above embeddings', () {
    final p = providerById('mistral')!;
    final ranked = rankModels(p, models([
      'mistral-embed',
      'mistral-small-latest',
      'pixtral-large-latest',
      'mistral-medium-latest',
    ]));
    expect(ranked.first, 'pixtral-large-latest');
    expect(ranked, isNot(contains('mistral-embed')));
  });

  test('openrouter puts models with image input first', () {
    final p = providerById('openrouter')!;
    final ranked = rankModels(p, [
      const AiModel('text/only:free', imageInput: false),
      const AiModel('vision/model:free', imageInput: true),
      const AiModel('vision/paid', imageInput: true),
    ]);
    expect(ranked.first, 'vision/model:free');
    expect(ranked.last, 'text/only:free');
  });

  test('at most four candidates are returned', () {
    final p = providerById('openai')!;
    final ranked = rankModels(
      p,
      models(['gpt-a', 'gpt-b', 'gpt-c', 'gpt-d', 'gpt-e', 'gpt-f']),
    );
    expect(ranked.length, 4);
  });

  test('AiException flags auth failures', () {
    expect(const AiException('x', status: 401).isAuth, isTrue);
    expect(const AiException('x', status: 429).isAuth, isFalse);
  });
}
