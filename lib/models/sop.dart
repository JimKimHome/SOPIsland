import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SopStep {
  SopStep({required this.title, required this.items});

  String title;
  List<String> items;

  Map<String, dynamic> toJson() => {'title': title, 'items': items};

  factory SopStep.fromJson(Map<String, dynamic> json) => SopStep(
        title: json['title'] as String? ?? '',
        items: ((json['items'] as List?) ?? const []).map((e) => '$e').toList(),
      );
}

class Sop {
  Sop({
    required this.id,
    required this.title,
    required this.scene,
    required this.steps,
    this.description = '',
    this.illustration = 0,
    this.runCount = 0,
    this.lastRunAt,
    this.plazaTemplateId,
  });

  final String id;
  String title;
  String scene;
  String description;
  int illustration;
  List<SopStep> steps;
  int runCount;
  DateTime? lastRunAt;
  String? plazaTemplateId;

  bool get fromPlaza => plazaTemplateId != null;

  int get subStepCount => steps.fold(0, (sum, step) => sum + step.items.length);

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'scene': scene,
        'description': description,
        'illustration': illustration,
        'runCount': runCount,
        'lastRunAt': lastRunAt?.toIso8601String(),
        'plazaTemplateId': plazaTemplateId,
        'steps': steps.map((e) => e.toJson()).toList(),
      };

  factory Sop.fromJson(Map<String, dynamic> json) => Sop(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        scene: json['scene'] as String? ?? '',
        description: json['description'] as String? ?? '',
        illustration: json['illustration'] as int? ?? 0,
        runCount: json['runCount'] as int? ?? 0,
        lastRunAt: json['lastRunAt'] == null ? null : DateTime.tryParse(json['lastRunAt'] as String),
        plazaTemplateId: json['plazaTemplateId'] as String?,
        steps: ((json['steps'] as List?) ?? const [])
            .map((e) => SopStep.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );

  Sop copyWith({
    String? id,
    String? title,
    String? scene,
    String? description,
    int? illustration,
    List<SopStep>? steps,
    int? runCount,
    DateTime? lastRunAt,
    String? plazaTemplateId,
  }) =>
      Sop(
        id: id ?? this.id,
        title: title ?? this.title,
        scene: scene ?? this.scene,
        description: description ?? this.description,
        illustration: illustration ?? this.illustration,
        steps: steps ?? this.steps.map((s) => SopStep(title: s.title, items: List<String>.from(s.items))).toList(),
        runCount: runCount ?? this.runCount,
        lastRunAt: lastRunAt ?? this.lastRunAt,
        plazaTemplateId: plazaTemplateId ?? this.plazaTemplateId,
      );
}

class SopTemplate {
  const SopTemplate({
    required this.id,
    required this.title,
    required this.scene,
    required this.description,
    required this.category,
    required this.illustration,
    required this.useCount,
    required this.steps,
  });

  final String id;
  final String title;
  final String scene;
  final String description;
  final String category;
  final int illustration;
  final int useCount;
  final List<SopStep> steps;

  Sop toSop() => Sop(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: title,
        scene: scene,
        description: description,
        illustration: illustration,
        steps: steps.map((s) => SopStep(title: s.title, items: List<String>.from(s.items))).toList(),
        plazaTemplateId: id,
      );
}

class LearnArticle {
  const LearnArticle({
    required this.id,
    required this.title,
    required this.summary,
    required this.body,
    required this.tag,
    this.readMinutes = 3,
  });

  final String id;
  final String title;
  final String summary;
  final String body;
  final String tag;
  final int readMinutes;
}

class EfficiencyPost {
  const EfficiencyPost({
    required this.id,
    required this.title,
    required this.summary,
    required this.body,
    required this.category,
    this.readMinutes = 4,
  });

  final String id;
  final String title;
  final String summary;
  final String body;
  final String category;
  final int readMinutes;
}

class SopStore {
  static const _prefsKey = 'sop_island_sops_v1';
  static const _dataVersion = 3;

  Future<List<Sop>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final version = prefs.getInt('${_prefsKey}_version') ?? 0;
    final raw = prefs.getString(_prefsKey);

    if (raw != null && version == _dataVersion) {
      final list = jsonDecode(raw) as List;
      return list.map((e) => Sop.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    }

    final seeded = _seedSops();
    await save(seeded);
    await prefs.setInt('${_prefsKey}_version', _dataVersion);
    return seeded;
  }

  Future<void> save(List<Sop> sops) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(sops.map((e) => e.toJson()).toList());
    await prefs.setString(_prefsKey, encoded);
    await prefs.setInt('${_prefsKey}_version', _dataVersion);
  }
}

List<Sop> _seedSops() {
  final now = DateTime.now();
  DateTime todayAt(int h, int m) => DateTime(now.year, now.month, now.day, h, m);
  return [
    Sop(
      id: 'seed-morning',
      title: '晨间开工流程',
      scene: '每日营业前',
      description: '适用于每日营业前的标准步骤，从开灯到收银准备。',
      illustration: 0,
      runCount: 12,
      lastRunAt: todayAt(9, 20),
      steps: [
        SopStep(title: '环境准备', items: ['打开照明和空调', '检查入口地面', '确认背景音乐音量']),
        SopStep(title: '设备检查', items: ['启动收银设备', '检查打印纸余量', '完成网络测试']),
        SopStep(title: '人员确认', items: ['同步今日重点', '确认岗位分工']),
      ],
    ),
    Sop(
      id: 'seed-publish',
      title: '内容发布检查',
      scene: '内容上线前',
      description: '适用于图文/视频发布前的统一检查，避免遗漏。',
      illustration: 1,
      runCount: 4,
      lastRunAt: todayAt(18, 10).subtract(const Duration(days: 1)),
      steps: [
        SopStep(title: '素材确认', items: ['核对标题与封面', '检查错别字', '确认发布时间']),
        SopStep(title: '渠道检查', items: ['确认分发平台', '检查标签分类']),
      ],
    ),
    Sop(
      id: 'seed-inspect',
      title: '设备巡检',
      scene: '每周固定时段',
      description: '适用于门店设备例行巡检，记录异常并跟进。',
      illustration: 2,
      runCount: 12,
      lastRunAt: todayAt(9, 20),
      steps: [
        SopStep(title: '外观检查', items: ['检查设备外观', '确认指示灯状态']),
        SopStep(title: '功能测试', items: ['运行自检程序', '记录读数']),
        SopStep(title: '收尾', items: ['填写巡检表', '上报异常']),
      ],
    ),
  ];
}
