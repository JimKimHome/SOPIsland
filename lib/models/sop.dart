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

enum SopReminderRepeat {
  none,
  daily,
  weekly,
  monthly;

  String get label => switch (this) {
    SopReminderRepeat.none => '不循环',
    SopReminderRepeat.daily => '每天',
    SopReminderRepeat.weekly => '每周',
    SopReminderRepeat.monthly => '每月',
  };

  String? get rruleFreq => switch (this) {
    SopReminderRepeat.none => null,
    SopReminderRepeat.daily => 'DAILY',
    SopReminderRepeat.weekly => 'WEEKLY',
    SopReminderRepeat.monthly => 'MONTHLY',
  };

  static SopReminderRepeat fromName(String? name) {
    for (final repeat in values) {
      if (repeat.name == name) return repeat;
    }
    return SopReminderRepeat.none;
  }
}

class SopReminder {
  SopReminder({
    required this.startsAt,
    this.repeat = SopReminderRepeat.none,
    this.endsAt,
    this.alertMinutes = 10,
  });

  DateTime startsAt;
  SopReminderRepeat repeat;
  DateTime? endsAt;
  int alertMinutes;

  bool get repeats => repeat != SopReminderRepeat.none;

  Map<String, dynamic> toJson() => {
    'startsAt': startsAt.toIso8601String(),
    'repeat': repeat.name,
    'endsAt': endsAt?.toIso8601String(),
    'alertMinutes': alertMinutes,
  };

  factory SopReminder.fromJson(Map<String, dynamic> json) => SopReminder(
    startsAt:
        DateTime.tryParse(json['startsAt'] as String? ?? '') ?? DateTime.now(),
    repeat: SopReminderRepeat.fromName(json['repeat'] as String?),
    endsAt: json['endsAt'] == null
        ? null
        : DateTime.tryParse(json['endsAt'] as String),
    alertMinutes: json['alertMinutes'] as int? ?? 10,
  );
}

class SopRunProgress {
  SopRunProgress({
    String? id,
    this.name = '',
    required this.currentStepIndex,
    required this.checkedItems,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? createdAt ?? DateTime.now();

  String id;
  String name;
  int currentStepIndex;
  Map<int, Set<int>> checkedItems;
  DateTime createdAt;
  DateTime updatedAt;

  int get checkedCount =>
      checkedItems.values.fold(0, (sum, items) => sum + items.length);

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'currentStepIndex': currentStepIndex,
    'checkedItems': checkedItems.map(
      (key, value) => MapEntry('$key', value.toList()..sort()),
    ),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory SopRunProgress.fromJson(Map<String, dynamic> json) {
    final rawChecked = Map<String, dynamic>.from(
      (json['checkedItems'] as Map?) ?? const {},
    );
    final updatedAt = DateTime.tryParse(json['updatedAt'] as String? ?? '');
    final createdAt =
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? updatedAt;
    return SopRunProgress(
      id: json['id'] as String?,
      name: json['name'] as String? ?? '',
      currentStepIndex: json['currentStepIndex'] as int? ?? 0,
      checkedItems: rawChecked.map(
        (key, value) => MapEntry(
          int.tryParse(key) ?? 0,
          ((value as List?) ?? const [])
              .map((item) => item is int ? item : (int.tryParse('$item') ?? 0))
              .toSet(),
        ),
      ),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
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
    this.pinned = false,
    this.lastReview = '',
    this.lastReviewAt,
    this.reminder,
    SopRunProgress? runProgress,
    List<SopRunProgress>? runProgresses,
  }) : runProgresses = runProgresses ?? _progressListFromNullable(runProgress);

  final String id;
  String title;
  String scene;
  String description;
  int illustration;
  List<SopStep> steps;
  int runCount;
  DateTime? lastRunAt;
  String? plazaTemplateId;
  bool pinned;
  String lastReview;
  DateTime? lastReviewAt;
  SopReminder? reminder;
  List<SopRunProgress> runProgresses;

  bool get fromPlaza => plazaTemplateId != null;

  int get subStepCount => steps.fold(0, (sum, step) => sum + step.items.length);

  SopRunProgress? get runProgress {
    if (runProgresses.isEmpty) return null;
    final sorted = List<SopRunProgress>.from(runProgresses)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sorted.first;
  }

  set runProgress(SopRunProgress? progress) {
    runProgresses = progress == null ? [] : [progress];
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'scene': scene,
    'description': description,
    'illustration': illustration,
    'runCount': runCount,
    'lastRunAt': lastRunAt?.toIso8601String(),
    'plazaTemplateId': plazaTemplateId,
    'pinned': pinned,
    'lastReview': lastReview,
    'lastReviewAt': lastReviewAt?.toIso8601String(),
    'reminder': reminder?.toJson(),
    'runProgress': runProgress?.toJson(),
    'runProgresses': runProgresses.map((e) => e.toJson()).toList(),
    'steps': steps.map((e) => e.toJson()).toList(),
  };

  factory Sop.fromJson(Map<String, dynamic> json) {
    final rawProgresses = (json['runProgresses'] as List?)
        ?.map(
          (e) => SopRunProgress.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
    final legacyProgress = json['runProgress'] == null
        ? null
        : SopRunProgress.fromJson(
            Map<String, dynamic>.from(json['runProgress'] as Map),
          );
    return Sop(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      scene: json['scene'] as String? ?? '',
      description: json['description'] as String? ?? '',
      illustration: json['illustration'] as int? ?? 0,
      runCount: json['runCount'] as int? ?? 0,
      lastRunAt: json['lastRunAt'] == null
          ? null
          : DateTime.tryParse(json['lastRunAt'] as String),
      plazaTemplateId: json['plazaTemplateId'] as String?,
      pinned: json['pinned'] as bool? ?? false,
      lastReview: json['lastReview'] as String? ?? '',
      lastReviewAt: json['lastReviewAt'] == null
          ? null
          : DateTime.tryParse(json['lastReviewAt'] as String),
      reminder: json['reminder'] == null
          ? null
          : SopReminder.fromJson(
              Map<String, dynamic>.from(json['reminder'] as Map),
            ),
      runProgresses: rawProgresses ?? _progressListFromNullable(legacyProgress),
      steps: ((json['steps'] as List?) ?? const [])
          .map((e) => SopStep.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

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
    bool? pinned,
    String? lastReview,
    DateTime? lastReviewAt,
    SopReminder? reminder,
    SopRunProgress? runProgress,
    List<SopRunProgress>? runProgresses,
  }) => Sop(
    id: id ?? this.id,
    title: title ?? this.title,
    scene: scene ?? this.scene,
    description: description ?? this.description,
    illustration: illustration ?? this.illustration,
    steps:
        steps ??
        this.steps
            .map(
              (s) => SopStep(title: s.title, items: List<String>.from(s.items)),
            )
            .toList(),
    runCount: runCount ?? this.runCount,
    lastRunAt: lastRunAt ?? this.lastRunAt,
    plazaTemplateId: plazaTemplateId ?? this.plazaTemplateId,
    pinned: pinned ?? this.pinned,
    lastReview: lastReview ?? this.lastReview,
    lastReviewAt: lastReviewAt ?? this.lastReviewAt,
    reminder: reminder ?? this.reminder,
    runProgress: runProgress,
    runProgresses:
        runProgresses ??
        (runProgress == null
            ? this.runProgresses
            : _progressListFromNullable(runProgress)),
  );
}

List<SopRunProgress> _progressListFromNullable(SopRunProgress? progress) =>
    progress == null ? <SopRunProgress>[] : <SopRunProgress>[progress];

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
    steps: steps
        .map((s) => SopStep(title: s.title, items: List<String>.from(s.items)))
        .toList(),
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
    final raw = prefs.getString(_prefsKey);

    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        final sops = list
            .map((e) => Sop.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        await prefs.setInt('${_prefsKey}_version', _dataVersion);
        return sops;
      } catch (_) {
        // Fall back to seed data only when stored data is unreadable.
      }
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
  DateTime todayAt(int h, int m) =>
      DateTime(now.year, now.month, now.day, h, m);
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
