/// The three request formats that cover every supported provider.
enum ApiFormat { anthropic, gemini, openai }

class AiProvider {
  final String id;
  final String name;
  final ApiFormat format;
  final String baseUrl;
  final String keyUrl;

  /// Neutral pricing hint shown next to the provider. Never a promise.
  final String hint;

  const AiProvider({
    required this.id,
    required this.name,
    required this.format,
    required this.baseUrl,
    required this.keyUrl,
    required this.hint,
  });
}

const List<AiProvider> aiProviders = [
  AiProvider(
    id: 'anthropic',
    name: 'Anthropic (Claude)',
    format: ApiFormat.anthropic,
    baseUrl: 'https://api.anthropic.com',
    keyUrl: 'https://console.anthropic.com/settings/keys',
    hint: 'Pay as you go',
  ),
  AiProvider(
    id: 'openai',
    name: 'OpenAI',
    format: ApiFormat.openai,
    baseUrl: 'https://api.openai.com/v1',
    keyUrl: 'https://platform.openai.com/api-keys',
    hint: 'Pay as you go',
  ),
  AiProvider(
    id: 'gemini',
    name: 'Google Gemini',
    format: ApiFormat.gemini,
    baseUrl: 'https://generativelanguage.googleapis.com',
    keyUrl: 'https://aistudio.google.com/apikey',
    hint: 'Free tier available',
  ),
  AiProvider(
    id: 'xai',
    name: 'xAI (Grok)',
    format: ApiFormat.openai,
    baseUrl: 'https://api.x.ai/v1',
    keyUrl: 'https://console.x.ai',
    hint: 'Check pricing',
  ),
  AiProvider(
    id: 'mistral',
    name: 'Mistral',
    format: ApiFormat.openai,
    baseUrl: 'https://api.mistral.ai/v1',
    keyUrl: 'https://console.mistral.ai/api-keys',
    hint: 'Check pricing',
  ),
  AiProvider(
    id: 'groq',
    name: 'Groq',
    format: ApiFormat.openai,
    baseUrl: 'https://api.groq.com/openai/v1',
    keyUrl: 'https://console.groq.com/keys',
    hint: 'Free tier available',
  ),
  AiProvider(
    id: 'openrouter',
    name: 'OpenRouter',
    format: ApiFormat.openai,
    baseUrl: 'https://openrouter.ai/api/v1',
    keyUrl: 'https://openrouter.ai/keys',
    hint: 'Some free models',
  ),
  AiProvider(
    id: 'cerebras',
    name: 'Cerebras',
    format: ApiFormat.openai,
    baseUrl: 'https://api.cerebras.ai/v1',
    keyUrl: 'https://cloud.cerebras.ai',
    hint: 'Free tier available',
  ),
];

AiProvider? providerById(String? id) {
  for (final p in aiProviders) {
    if (p.id == id) return p;
  }
  return null;
}
