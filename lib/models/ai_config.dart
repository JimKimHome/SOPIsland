import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class AiProviderPreset {
  const AiProviderPreset({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.model,
  });

  final String id;
  final String name;
  final String baseUrl;
  final String model;
}

const aiProviderPresets = [
  AiProviderPreset(
    id: 'openai',
    name: 'OpenAI',
    baseUrl: 'https://api.openai.com/v1',
    model: 'gpt-4o-mini',
  ),
  AiProviderPreset(
    id: 'deepseek',
    name: 'DeepSeek',
    baseUrl: 'https://api.deepseek.com/v1',
    model: 'deepseek-chat',
  ),
  AiProviderPreset(
    id: 'minimax',
    name: 'MiniMax',
    baseUrl: 'https://api.minimax.io/v1',
    model: 'abab6.5s-chat',
  ),
  AiProviderPreset(id: 'custom', name: '自定义', baseUrl: '', model: ''),
];

class AiConfig {
  AiConfig({
    required this.providerId,
    required this.baseUrl,
    required this.model,
    required this.apiKey,
  });

  String providerId;
  String baseUrl;
  String model;
  String apiKey;

  bool get isConfigured =>
      baseUrl.trim().isNotEmpty &&
      model.trim().isNotEmpty &&
      apiKey.trim().isNotEmpty;

  AiProviderPreset get preset => aiProviderPresets.firstWhere(
    (preset) => preset.id == providerId,
    orElse: () => aiProviderPresets.last,
  );

  Map<String, dynamic> toJson() => {
    'providerId': providerId,
    'baseUrl': baseUrl,
    'model': model,
    'apiKey': apiKey,
  };

  factory AiConfig.defaults() {
    final preset = aiProviderPresets[0];
    return AiConfig(
      providerId: preset.id,
      baseUrl: preset.baseUrl,
      model: preset.model,
      apiKey: '',
    );
  }

  factory AiConfig.fromJson(Map<String, dynamic> json) => AiConfig(
    providerId: json['providerId'] as String? ?? 'openai',
    baseUrl: json['baseUrl'] as String? ?? aiProviderPresets[0].baseUrl,
    model: json['model'] as String? ?? aiProviderPresets[0].model,
    apiKey: json['apiKey'] as String? ?? '',
  );
}

class AiConfigStore {
  static const _prefsKey = 'sop_island_ai_config_v1';

  Future<AiConfig> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return AiConfig.defaults();
    return AiConfig.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
  }

  Future<void> save(AiConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(config.toJson()));
  }
}
