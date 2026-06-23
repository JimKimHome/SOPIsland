import 'package:flutter/material.dart';

import '../models/ai_config.dart';
import '../models/sop.dart';
import '../services/ai_sop_service.dart';
import '../theme/app_theme.dart';

class AiGenerateScreen extends StatefulWidget {
  const AiGenerateScreen({
    super.key,
    required this.initialConfig,
    required this.onOpenConfig,
  });

  final AiConfig initialConfig;
  final Future<AiConfig> Function() onOpenConfig;

  @override
  State<AiGenerateScreen> createState() => _AiGenerateScreenState();
}

class _AiGenerateScreenState extends State<AiGenerateScreen> {
  final _need = TextEditingController();
  final _service = AiSopService();
  late AiConfig _config;
  Sop? _draft;
  String? _error;
  var _generating = false;

  @override
  void initState() {
    super.initState();
    _config = widget.initialConfig;
  }

  @override
  void dispose() {
    _need.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    if (_need.text.trim().isEmpty) {
      setState(() => _error = '先描述你想标准化的工作。');
      return;
    }
    setState(() {
      _generating = true;
      _error = null;
      _draft = null;
    });
    try {
      final sop = await _service.generateSop(
        config: _config,
        userNeed: _need.text,
      );
      if (!mounted) return;
      setState(() => _draft = sop);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final configured = _config.isConfigured;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text(
          'AI 生成 SOP',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            onPressed: _openConfig,
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          if (!configured) ...[
            _Notice(
              text: '还没有完成模型配置。先填写 API Key、Base URL 和模型名。',
              action: '去配置',
              onTap: _openConfig,
            ),
            const SizedBox(height: 14),
          ],
          TextField(
            controller: _need,
            minLines: 5,
            maxLines: 8,
            decoration: inputDecoration('描述你的需求').copyWith(
              hintText: '例如：帮我生成一个每周内容发布前的检查 SOP，需要包含素材、文案、平台设置和发布后复盘。',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: configured && !_generating ? _generate : null,
            icon: const Icon(Icons.auto_awesome_rounded),
            label: Text(_generating ? '生成中...' : '生成 SOP'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            _Notice(text: _error!, action: null, onTap: null),
          ],
          if (_draft != null) ...[
            const SizedBox(height: 22),
            _Preview(sop: _draft!),
          ],
        ],
      ),
      bottomNavigationBar: _draft == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(_draft),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('保存到我的 SOP'),
                ),
              ),
            ),
    );
  }

  Future<void> _openConfig() async {
    final config = await widget.onOpenConfig();
    if (!mounted) return;
    setState(() => _config = config);
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.sop});

  final Sop sop;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(AppColors.paper),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sop.title,
            style: const TextStyle(
              color: AppColors.brown,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            sop.description.isEmpty ? sop.scene : sop.description,
            style: const TextStyle(color: AppColors.softBrown, height: 1.4),
          ),
          const SizedBox(height: 16),
          ...sop.steps.map(
            (step) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: const TextStyle(
                      color: AppColors.brown,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...step.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            margin: const EdgeInsets.only(top: 1),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.line,
                                width: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item,
                              style: const TextStyle(
                                color: AppColors.softBrown,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.text,
    required this.action,
    required this.onTap,
  });

  final String text;
  final String? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppColors.softBrown, height: 1.35),
            ),
          ),
          if (action != null)
            TextButton(onPressed: onTap, child: Text(action!)),
        ],
      ),
    );
  }
}
