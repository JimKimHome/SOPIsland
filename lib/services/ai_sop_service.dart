import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/ai_config.dart';
import '../models/sop.dart';

class AiSopException implements Exception {
  AiSopException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AiSopService {
  Future<Sop> generateSop({
    required AiConfig config,
    required String userNeed,
  }) async {
    if (!config.isConfigured) {
      throw AiSopException('请先完成 AI 模型配置。');
    }
    final uri = Uri.parse('${_trimBaseUrl(config.baseUrl)}/chat/completions');
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 20);
    try {
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.headers.set(
        HttpHeaders.authorizationHeader,
        'Bearer ${config.apiKey.trim()}',
      );
      request.add(
        utf8.encode(
          jsonEncode({
            'model': config.model.trim(),
            'temperature': 0.2,
            'messages': [
              {'role': 'system', 'content': _systemPrompt},
              {'role': 'user', 'content': userNeed.trim()},
            ],
          }),
        ),
      );
      final response = await request.close().timeout(
        const Duration(seconds: 60),
      );
      final body = await utf8.decodeStream(response);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AiSopException('模型请求失败：HTTP ${response.statusCode}\n$body');
      }
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final choices = decoded['choices'] as List?;
      final message = choices == null || choices.isEmpty
          ? null
          : (choices.first as Map)['message'] as Map?;
      final content = message?['content'] as String?;
      if (content == null || content.trim().isEmpty) {
        throw AiSopException('模型没有返回可用内容。');
      }
      return _sopFromContent(content);
    } on TimeoutException {
      throw AiSopException('模型响应超时，请检查网络或更换模型。');
    } on SocketException {
      throw AiSopException('无法连接到模型服务，请检查网络和 Base URL。');
    } on FormatException {
      throw AiSopException('模型返回格式不是有效 JSON，请重试。');
    } finally {
      client.close(force: true);
    }
  }

  Future<Sop> improveSop({
    required AiConfig config,
    required Sop sop,
    required String review,
  }) async {
    if (!config.isConfigured) {
      throw AiSopException('请先完成 AI 模型配置。');
    }
    final payload = jsonEncode({
      'currentSop': sop.toJson(),
      'review': review.trim(),
    });
    final improved = await _requestSop(
      config: config,
      systemPrompt: _improvePrompt,
      userContent: payload,
    );
    return improved.copyWith(
      id: sop.id,
      illustration: sop.illustration,
      runCount: sop.runCount,
      lastRunAt: sop.lastRunAt,
      plazaTemplateId: sop.plazaTemplateId,
      pinned: sop.pinned,
      lastReview: sop.lastReview,
      lastReviewAt: sop.lastReviewAt,
      reminder: sop.reminder,
    );
  }

  Future<Sop> _requestSop({
    required AiConfig config,
    required String systemPrompt,
    required String userContent,
  }) async {
    final uri = Uri.parse('${_trimBaseUrl(config.baseUrl)}/chat/completions');
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 20);
    try {
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.headers.set(
        HttpHeaders.authorizationHeader,
        'Bearer ${config.apiKey.trim()}',
      );
      request.add(
        utf8.encode(
          jsonEncode({
            'model': config.model.trim(),
            'temperature': 0.2,
            'messages': [
              {'role': 'system', 'content': systemPrompt},
              {'role': 'user', 'content': userContent.trim()},
            ],
          }),
        ),
      );
      final response = await request.close().timeout(
        const Duration(seconds: 60),
      );
      final body = await utf8.decodeStream(response);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AiSopException('模型请求失败：HTTP ${response.statusCode}\n$body');
      }
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final choices = decoded['choices'] as List?;
      final message = choices == null || choices.isEmpty
          ? null
          : (choices.first as Map)['message'] as Map?;
      final content = message?['content'] as String?;
      if (content == null || content.trim().isEmpty) {
        throw AiSopException('模型没有返回可用内容。');
      }
      return _sopFromContent(content);
    } on TimeoutException {
      throw AiSopException('模型响应超时，请检查网络或更换模型。');
    } on SocketException {
      throw AiSopException('无法连接到模型服务，请检查网络和 Base URL。');
    } on FormatException {
      throw AiSopException('模型返回格式不是有效 JSON，请重试。');
    } finally {
      client.close(force: true);
    }
  }

  Sop _sopFromContent(String content) {
    final jsonText = _extractJson(content);
    final map = Map<String, dynamic>.from(jsonDecode(jsonText) as Map);
    final title = (map['title'] as String? ?? '').trim();
    final scene = (map['scene'] as String? ?? '').trim();
    final description = (map['description'] as String? ?? '').trim();
    final rawSteps = map['steps'] as List?;
    if (title.isEmpty || rawSteps == null || rawSteps.isEmpty) {
      throw AiSopException('模型返回的 SOP 缺少标题或步骤。');
    }
    final steps = rawSteps.map((raw) {
      final step = Map<String, dynamic>.from(raw as Map);
      final stepTitle = (step['title'] as String? ?? '').trim();
      final items = ((step['items'] as List?) ?? const [])
          .map((item) => '$item'.trim())
          .where((item) => item.isNotEmpty)
          .toList();
      return SopStep(
        title: stepTitle.isEmpty ? '未命名步骤' : stepTitle,
        items: items.isEmpty ? ['确认完成'] : items,
      );
    }).toList();
    return Sop(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      scene: scene.isEmpty ? 'AI 生成' : scene,
      description: description,
      steps: steps,
    );
  }

  String _extractJson(String content) {
    final trimmed = content.trim();
    final start = trimmed.indexOf('{');
    final end = trimmed.lastIndexOf('}');
    if (start < 0 || end <= start) {
      throw AiSopException('模型没有返回 JSON。');
    }
    return trimmed.substring(start, end + 1);
  }

  String _trimBaseUrl(String value) {
    var base = value.trim();
    while (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    return base;
  }
}

const _systemPrompt = '''
你是 OrSOP 的流程设计助手。根据用户需求，生成一份可以直接在移动端执行的 SOP。

只输出 JSON，不要 Markdown，不要代码块，不要解释。

JSON 格式必须严格为：
{
  "title": "简短 SOP 名称",
  "scene": "适用场景",
  "description": "一句话说明流程目标",
  "steps": [
    {
      "title": "阶段名称",
      "items": ["可勾选动作", "可勾选动作"]
    }
  ]
}

规则：
- 使用简体中文。
- 生成 3 到 6 个步骤。
- 每个步骤生成 2 到 5 个检查项。
- 检查项必须是可执行动作，用动词开头。
- 不要写空泛原则，不要写长段落。
- 不要包含 Markdown、编号符号或额外字段。
''';

const _improvePrompt = '''
你是 OrSOP 的流程优化助手。你会收到一个现有 SOP JSON 和用户运行后的复盘意见。

请根据复盘意见优化 SOP，并输出完整的新 SOP JSON。只输出 JSON，不要 Markdown，不要代码块，不要解释。

JSON 格式必须严格为：
{
  "title": "简短 SOP 名称",
  "scene": "适用场景",
  "description": "一句话说明流程目标",
  "steps": [
    {
      "title": "阶段名称",
      "items": ["可勾选动作", "可勾选动作"]
    }
  ]
}

规则：
- 使用简体中文。
- 优先解决用户复盘意见中指出的卡点、遗漏、冗余、顺序问题。
- 尽量保留原 SOP 的核心目标和可用步骤。
- 可以合并、拆分、重排、补充或删除步骤。
- 生成 3 到 7 个步骤。
- 每个步骤生成 2 到 6 个检查项。
- 检查项必须是可执行动作，用动词开头。
- 不要写空泛原则，不要写长段落。
- 不要包含 Markdown、编号符号或额外字段。
''';
