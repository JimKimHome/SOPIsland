import 'package:flutter/material.dart';

import '../models/ai_config.dart';
import '../theme/app_theme.dart';

class AiConfigScreen extends StatefulWidget {
  const AiConfigScreen({
    super.key,
    required this.initialConfig,
    required this.onSave,
  });

  final AiConfig initialConfig;
  final Future<void> Function(AiConfig config) onSave;

  @override
  State<AiConfigScreen> createState() => _AiConfigScreenState();
}

class _AiConfigScreenState extends State<AiConfigScreen> {
  late String _providerId;
  late final TextEditingController _baseUrl;
  late final TextEditingController _model;
  late final TextEditingController _apiKey;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _providerId = widget.initialConfig.providerId;
    _baseUrl = TextEditingController(text: widget.initialConfig.baseUrl);
    _model = TextEditingController(text: widget.initialConfig.model);
    _apiKey = TextEditingController(text: widget.initialConfig.apiKey);
  }

  @override
  void dispose() {
    _baseUrl.dispose();
    _model.dispose();
    _apiKey.dispose();
    super.dispose();
  }

  void _selectProvider(String id) {
    final preset = aiProviderPresets.firstWhere((preset) => preset.id == id);
    setState(() {
      _providerId = id;
      if (id != 'custom') {
        _baseUrl.text = preset.baseUrl;
        _model.text = preset.model;
      }
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await widget.onSave(
      AiConfig(
        providerId: _providerId,
        baseUrl: _baseUrl.text.trim(),
        model: _model.text.trim(),
        apiKey: _apiKey.text.trim(),
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text(
          'AI 配置',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          const Text(
            '选择模型服务',
            style: TextStyle(
              color: AppColors.brown,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: aiProviderPresets.map((preset) {
              final selected = preset.id == _providerId;
              return ChoiceChip(
                label: Text(preset.name),
                selected: selected,
                selectedColor: AppColors.coral.withValues(alpha: 0.14),
                onSelected: (_) => _selectProvider(preset.id),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          _Field(controller: _baseUrl, label: 'Base URL'),
          const SizedBox(height: 12),
          _Field(controller: _model, label: '模型名'),
          const SizedBox(height: 12),
          _Field(controller: _apiKey, label: 'API Key', obscure: true),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line),
            ),
            child: const Text(
              '当前使用 OpenAI-compatible /v1/chat/completions 格式。OpenAI、DeepSeek、MiniMax 或兼容代理都可以通过 Base URL 和模型名接入。',
              style: TextStyle(color: AppColors.softBrown, height: 1.45),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? '保存中...' : '保存配置'),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.obscure = false,
  });

  final TextEditingController controller;
  final String label;
  final bool obscure;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: inputDecoration(label),
    );
  }
}
