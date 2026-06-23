import 'package:flutter/foundation.dart';

import 'models/ai_config.dart';
import 'models/sop.dart';
import 'models/sop_backup.dart';

enum BackupImportMode { merge, replace }

class BackupImportResult {
  const BackupImportResult({
    required this.importedCount,
    required this.totalCount,
  });

  final int importedCount;
  final int totalCount;
}

class AppController extends ChangeNotifier {
  final _store = SopStore();
  final _aiConfigStore = AiConfigStore();
  List<Sop> sops = [];
  AiConfig aiConfig = AiConfig.defaults();
  bool loading = true;

  Future<void> load() async {
    loading = true;
    notifyListeners();
    final results = await Future.wait([_store.load(), _aiConfigStore.load()]);
    sops = results[0] as List<Sop>;
    aiConfig = results[1] as AiConfig;
    loading = false;
    notifyListeners();
  }

  Future<void> save() async {
    await _store.save(sops);
    notifyListeners();
  }

  Future<void> saveAiConfig(AiConfig config) async {
    aiConfig = config;
    await _aiConfigStore.save(config);
    notifyListeners();
  }

  Future<void> addSop(Sop sop) async {
    sops.insert(0, sop);
    await save();
  }

  String buildBackupJson() {
    return SopBackup(
      exportedAt: DateTime.now(),
      sops: sops.map((sop) => Sop.fromJson(sop.toJson())).toList(),
    ).toJsonString();
  }

  Future<BackupImportResult> importBackupJson(
    String raw, {
    required BackupImportMode mode,
  }) async {
    final backup = SopBackup.fromJsonString(raw);
    final imported = backup.sops;
    if (mode == BackupImportMode.replace) {
      sops = imported;
    } else {
      final importedIds = imported.map((sop) => sop.id).toSet();
      sops = [
        ...imported,
        ...sops.where((sop) => !importedIds.contains(sop.id)),
      ];
    }
    await save();
    return BackupImportResult(
      importedCount: imported.length,
      totalCount: sops.length,
    );
  }

  /// 今日建议：优先推荐今天未执行或很久未执行的 SOP
  List<Sop> todaySuggestions({int limit = 3}) {
    if (sops.isEmpty) return [];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int score(Sop sop) {
      if (sop.lastRunAt == null) return 0;
      final day = DateTime(
        sop.lastRunAt!.year,
        sop.lastRunAt!.month,
        sop.lastRunAt!.day,
      );
      if (day == today) return 1000;
      return sop.lastRunAt!.millisecondsSinceEpoch;
    }

    final sorted = List<Sop>.from(sops)
      ..sort((a, b) => score(a).compareTo(score(b)));
    return sorted.take(limit).toList();
  }

  int get totalRuns => sops.fold(0, (sum, s) => sum + s.runCount);

  Sop? get mostUsed {
    if (sops.isEmpty) return null;
    return sops.reduce((a, b) => a.runCount >= b.runCount ? a : b);
  }
}
