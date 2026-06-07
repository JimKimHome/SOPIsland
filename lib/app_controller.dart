import 'package:flutter/foundation.dart';

import '../models/sop.dart';

class AppController extends ChangeNotifier {
  final _store = SopStore();
  List<Sop> sops = [];
  bool loading = true;

  Future<void> load() async {
    loading = true;
    notifyListeners();
    sops = await _store.load();
    loading = false;
    notifyListeners();
  }

  Future<void> save() async {
    await _store.save(sops);
    notifyListeners();
  }

  Future<Sop> addFromTemplate(SopTemplate template) async {
    final sop = template.toSop();
    sops.insert(0, sop);
    await save();
    return sop;
  }

  bool hasTemplate(String templateId) => sops.any((s) => s.plazaTemplateId == templateId);

  /// 今日建议：优先推荐今天未执行或很久未执行的 SOP
  List<Sop> todaySuggestions({int limit = 3}) {
    if (sops.isEmpty) return [];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int score(Sop sop) {
      if (sop.lastRunAt == null) return 0;
      final day = DateTime(sop.lastRunAt!.year, sop.lastRunAt!.month, sop.lastRunAt!.day);
      if (day == today) return 1000;
      return sop.lastRunAt!.millisecondsSinceEpoch;
    }

    final sorted = List<Sop>.from(sops)..sort((a, b) => score(a).compareTo(score(b)));
    return sorted.take(limit).toList();
  }

  int get totalRuns => sops.fold(0, (sum, s) => sum + s.runCount);

  Sop? get mostUsed {
    if (sops.isEmpty) return null;
    return sops.reduce((a, b) => a.runCount >= b.runCount ? a : b);
  }
}
