import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: _cream,
      systemNavigationBarColor: _cream,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const SopIslandApp());
}

const _cream = Color(0xFFFFF4D8);
const _paper = Color(0xFFFFFBEE);
const _mint = Color(0xFFAADFC0);
const _deepMint = Color(0xFF4F9E79);
const _sky = Color(0xFFBFE5F5);
const _coral = Color(0xFFF37E67);
const _honey = Color(0xFFFFD76D);
const _brown = Color(0xFF453528);
const _softBrown = Color(0xFF806B58);
const _line = Color(0xFFEEDCB7);

class SopIslandApp extends StatelessWidget {
  const SopIslandApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SOP Island',
      themeMode: ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: _cream,
        colorScheme: ColorScheme.fromSeed(seedColor: _deepMint, brightness: Brightness.light),
        fontFamily: 'sans',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          foregroundColor: _brown,
        ),
      ),
      home: const SopHomePage(),
    );
  }
}

class Sop {
  Sop({
    required this.id,
    required this.title,
    required this.scene,
    required this.steps,
    this.runCount = 0,
    this.lastRunAt,
  });

  final String id;
  String title;
  String scene;
  List<SopStep> steps;
  int runCount;
  DateTime? lastRunAt;

  int get subStepCount => steps.fold(0, (sum, step) => sum + step.items.length);

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'scene': scene,
        'runCount': runCount,
        'lastRunAt': lastRunAt?.toIso8601String(),
        'steps': steps.map((e) => e.toJson()).toList(),
      };

  factory Sop.fromJson(Map<String, dynamic> json) => Sop(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        scene: json['scene'] as String? ?? '',
        runCount: json['runCount'] as int? ?? 0,
        lastRunAt: json['lastRunAt'] == null ? null : DateTime.tryParse(json['lastRunAt']),
        steps: ((json['steps'] as List?) ?? const [])
            .map((e) => SopStep.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

class SopStep {
  SopStep({required this.title, required this.items});

  String title;
  List<String> items;

  Map<String, dynamic> toJson() => {
        'title': title,
        'items': items,
      };

  factory SopStep.fromJson(Map<String, dynamic> json) => SopStep(
        title: json['title'] as String? ?? '',
        items: ((json['items'] as List?) ?? const []).map((e) => '$e').toList(),
      );
}

class SopStore {
  List<Sop>? _cache;

  Future<List<Sop>> load() async {
    _cache ??= _seedSops();
    return _cache!.map((sop) => Sop.fromJson(sop.toJson())).toList();
  }

  Future<void> save(List<Sop> sops) async {
    _cache = sops.map((sop) => Sop.fromJson(sop.toJson())).toList();
  }
}

List<Sop> _seedSops() => [
      Sop(
        id: 'seed-morning',
        title: '门店开店检查',
        scene: '每日营业前',
        runCount: 3,
        lastRunAt: DateTime.now().subtract(const Duration(hours: 22)),
        steps: [
          SopStep(title: '环境准备', items: ['打开照明和空调', '检查入口地面', '确认背景音乐音量']),
          SopStep(title: '设备检查', items: ['启动收银设备', '检查打印纸余量', '完成网络测试']),
          SopStep(title: '人员确认', items: ['同步今日重点', '确认岗位分工']),
        ],
      ),
      Sop(
        id: 'seed-onboard',
        title: '新人入职接待',
        scene: '员工首日到岗',
        runCount: 1,
        lastRunAt: DateTime.now().subtract(const Duration(days: 5)),
        steps: [
          SopStep(title: '资料确认', items: ['核对身份证件', '确认合同签署', '录入紧急联系人']),
          SopStep(title: '工作准备', items: ['发放工牌', '配置账号', '介绍办公区域']),
        ],
      ),
    ];

enum _Mode { list, detail, edit, run }

class SopHomePage extends StatefulWidget {
  const SopHomePage({super.key});

  @override
  State<SopHomePage> createState() => _SopHomePageState();
}

class _SopHomePageState extends State<SopHomePage> {
  final _store = SopStore();
  var _mode = _Mode.list;
  var _loading = true;
  List<Sop> _sops = [];
  Sop? _active;
  int _runIndex = 0;
  final Map<int, Set<int>> _checked = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sops = await _store.load();
    if (!mounted) return;
    setState(() {
      _sops = sops;
      _loading = false;
    });
    await _store.save(sops);
  }

  Future<void> _persist() => _store.save(_sops);

  void _open(Sop sop) => setState(() {
        _active = sop;
        _mode = _Mode.detail;
      });

  void _newSop() => setState(() {
        _active = Sop(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          title: '',
          scene: '',
          steps: [SopStep(title: '第一步', items: ['确认事项'])],
        );
        _mode = _Mode.edit;
      });

  void _edit(Sop sop) => setState(() {
        _active = _clone(sop);
        _mode = _Mode.edit;
      });

  Future<void> _saveEdit(Sop sop) async {
    final existing = _sops.indexWhere((e) => e.id == sop.id);
    setState(() {
      if (existing >= 0) {
        _sops[existing] = sop;
      } else {
        _sops.insert(0, sop);
      }
      _active = sop;
      _mode = _Mode.detail;
    });
    await _persist();
  }

  Future<void> _delete(Sop sop) async {
    setState(() {
      _sops.removeWhere((e) => e.id == sop.id);
      _active = null;
      _mode = _Mode.list;
    });
    await _persist();
  }

  void _startRun(Sop sop) => setState(() {
        _active = sop;
        _runIndex = 0;
        _checked.clear();
        _mode = _Mode.run;
      });

  Future<void> _finishRun() async {
    final sop = _active;
    if (sop == null) return;
    setState(() {
      sop.runCount += 1;
      sop.lastRunAt = DateTime.now();
      _mode = _Mode.detail;
    });
    await _persist();
    if (!mounted) return;
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '完成庆祝',
      barrierColor: _brown.withValues(alpha: 0.22),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (context, animation, secondaryAnimation) => _CelebrationDialog(
        sopTitle: sop.title,
        runCount: sop.runCount,
      ),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: curved, child: child),
        );
      },
    );
    if (!mounted) return;
    setState(() => _mode = _Mode.list);
  }

  Sop _clone(Sop sop) => Sop.fromJson(sop.toJson());

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const _IslandBackdrop(),
        SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: _deepMint))
              : AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: switch (_mode) {
                    _Mode.list => _ListScreen(
                        key: const ValueKey('list'),
                        sops: _sops,
                        onOpen: _open,
                        onRun: _startRun,
                        onNew: _newSop,
                      ),
                    _Mode.detail => _DetailScreen(
                        key: ValueKey('detail-${_active?.id}'),
                        sop: _active!,
                        onBack: () => setState(() => _mode = _Mode.list),
                        onRun: () => _startRun(_active!),
                        onEdit: () => _edit(_active!),
                        onDelete: () => _confirmDelete(_active!),
                      ),
                    _Mode.edit => _EditScreen(
                        key: ValueKey('edit-${_active?.id}'),
                        sop: _active!,
                        onCancel: () => setState(() => _mode = _active!.title.isEmpty ? _Mode.list : _Mode.detail),
                        onSave: _saveEdit,
                      ),
                    _Mode.run => _RunScreen(
                        key: ValueKey('run-${_active?.id}'),
                        sop: _active!,
                        index: _runIndex,
                        checked: _checked,
                        onBack: () => setState(() => _mode = _Mode.detail),
                        onPrev: () => setState(() => _runIndex = (_runIndex - 1).clamp(0, _active!.steps.length - 1)),
                        onNext: () {
                          if (_runIndex == _active!.steps.length - 1) {
                            _finishRun();
                          } else {
                            setState(() => _runIndex++);
                          }
                        },
                        onToggle: (itemIndex, value) => setState(() {
                          final set = _checked.putIfAbsent(_runIndex, () => <int>{});
                          value ? set.add(itemIndex) : set.remove(itemIndex);
                        }),
                        onJump: (target) => setState(() => _runIndex = target),
                      ),
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(Sop sop) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _paper,
        title: const Text('删除 SOP？', style: TextStyle(color: _brown, fontWeight: FontWeight.w900)),
        content: Text('“${sop.title}” 删除后不可恢复。', style: const TextStyle(color: _softBrown)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _coral),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (yes == true) await _delete(sop);
  }
}

class _ListScreen extends StatelessWidget {
  const _ListScreen({super.key, required this.sops, required this.onOpen, required this.onRun, required this.onNew});

  final List<Sop> sops;
  final ValueChanged<Sop> onOpen;
  final ValueChanged<Sop> onRun;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'SOP Island',
                          style: TextStyle(color: _brown, fontSize: 32, fontWeight: FontWeight.w900),
                        ),
                      ),
                      _RoundIconButton(icon: Icons.add_rounded, color: _coral, onTap: onNew),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('把重复工作做成清晰路线', style: TextStyle(color: _softBrown, fontSize: 15)),
                  const SizedBox(height: 18),
                  _HeroPanel(total: sops.length, runs: sops.fold(0, (sum, e) => sum + e.runCount)),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
            sliver: SliverList.separated(
              itemCount: sops.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (context, index) => _SopCard(sop: sops[index], onOpen: () => onOpen(sops[index]), onRun: () => onRun(sops[index])),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.total, required this.runs});

  final int total;
  final int runs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _softBox(_sky),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('今日工作小岛', style: TextStyle(color: _brown, fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text('$total 个 SOP 已就绪，累计完成 $runs 次', style: const TextStyle(color: _softBrown, height: 1.35)),
              ],
            ),
          ),
          const _IslandMark(size: 82),
        ],
      ),
    );
  }
}

class _SopCard extends StatelessWidget {
  const _SopCard({required this.sop, required this.onOpen, required this.onRun});

  final Sop sop;
  final VoidCallback onOpen;
  final VoidCallback onRun;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: _softBox(_paper),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(color: _mint, shape: BoxShape.circle),
                  child: const Icon(Icons.route_rounded, color: _brown),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(sop.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _brown, fontSize: 18, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 3),
                      Text(sop.scene, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _softBrown)),
                    ],
                  ),
                ),
                _RoundIconButton(icon: Icons.play_arrow_rounded, color: _honey, onTap: onRun),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _Chip(icon: Icons.check_circle_outline_rounded, label: '${sop.runCount} 次完成'),
                const SizedBox(width: 8),
                _Chip(icon: Icons.schedule_rounded, label: _formatTime(sop.lastRunAt)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailScreen extends StatelessWidget {
  const _DetailScreen({super.key, required this.sop, required this.onBack, required this.onRun, required this.onEdit, required this.onDelete});

  final Sop sop;
  final VoidCallback onBack;
  final VoidCallback onRun;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: onBack),
        actions: [
          IconButton(icon: const Icon(Icons.edit_rounded), onPressed: onEdit),
          IconButton(icon: const Icon(Icons.delete_outline_rounded), onPressed: onDelete),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Text(sop.title, style: const TextStyle(color: _brown, fontSize: 30, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(sop.scene, style: const TextStyle(color: _softBrown, fontSize: 16)),
          const SizedBox(height: 18),
          _StatsRow(sop: sop),
          const SizedBox(height: 18),
          ...List.generate(sop.steps.length, (i) => _StepPreview(index: i, step: sop.steps[i])),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: _PrimaryButton(icon: Icons.play_arrow_rounded, label: '开始运行', onTap: onRun),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.sop});

  final Sop sop;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatBox(label: '步骤', value: '${sop.steps.length}')),
        const SizedBox(width: 10),
        Expanded(child: _StatBox(label: '检查项', value: '${sop.subStepCount}')),
        const SizedBox(width: 10),
        Expanded(child: _StatBox(label: '完成', value: '${sop.runCount}')),
      ],
    );
  }
}

class _StepPreview extends StatelessWidget {
  const _StepPreview({required this.index, required this.step});

  final int index;
  final SopStep step;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: _softBox(_paper),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${index + 1}. ${step.title}', style: const TextStyle(color: _brown, fontSize: 17, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          ...step.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(children: [
                  const Icon(Icons.check_box_outline_blank_rounded, size: 18, color: _deepMint),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item, style: const TextStyle(color: _softBrown))),
                ]),
              )),
        ],
      ),
    );
  }
}

class _EditScreen extends StatefulWidget {
  const _EditScreen({super.key, required this.sop, required this.onCancel, required this.onSave});

  final Sop sop;
  final VoidCallback onCancel;
  final ValueChanged<Sop> onSave;

  @override
  State<_EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<_EditScreen> {
  late final TextEditingController _title;
  late final TextEditingController _scene;
  late final Sop _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.sop;
    _title = TextEditingController(text: _draft.title);
    _scene = TextEditingController(text: _draft.scene);
  }

  @override
  void dispose() {
    _title.dispose();
    _scene.dispose();
    super.dispose();
  }

  void _save() {
    _draft.title = _title.text.trim().isEmpty ? '未命名 SOP' : _title.text.trim();
    _draft.scene = _scene.text.trim().isEmpty ? '未设置场景' : _scene.text.trim();
    _draft.steps = _draft.steps.where((s) => s.title.trim().isNotEmpty || s.items.any((e) => e.trim().isNotEmpty)).toList();
    for (final step in _draft.steps) {
      step.title = step.title.trim().isEmpty ? '未命名步骤' : step.title.trim();
      step.items = step.items.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      if (step.items.isEmpty) step.items = ['确认完成'];
    }
    if (_draft.steps.isEmpty) _draft.steps = [SopStep(title: '第一步', items: ['确认完成'])];
    widget.onSave(_draft);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: widget.onCancel),
        title: const Text('编辑 SOP', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [IconButton(icon: const Icon(Icons.check_rounded), onPressed: _save)],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          _TextBox(controller: _title, label: 'SOP 名称'),
          const SizedBox(height: 12),
          _TextBox(controller: _scene, label: '适用场景'),
          const SizedBox(height: 18),
          ...List.generate(_draft.steps.length, (stepIndex) => _EditableStep(
                step: _draft.steps[stepIndex],
                index: stepIndex,
                onChanged: () => setState(() {}),
                onDelete: () => setState(() => _draft.steps.removeAt(stepIndex)),
              )),
          const SizedBox(height: 8),
          _SecondaryButton(
            icon: Icons.add_rounded,
            label: '添加步骤',
            onTap: () => setState(() => _draft.steps.add(SopStep(title: '新步骤', items: ['新检查项']))),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: _PrimaryButton(icon: Icons.save_rounded, label: '保存 SOP', onTap: _save),
      ),
    );
  }
}

class _EditableStep extends StatelessWidget {
  const _EditableStep({required this.step, required this.index, required this.onChanged, required this.onDelete});

  final SopStep step;
  final int index;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: _softBox(_paper),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: step.title,
                  onChanged: (v) => step.title = v,
                  style: const TextStyle(color: _brown, fontWeight: FontWeight.w800),
                  decoration: _inputDecoration('步骤 ${index + 1}'),
                ),
              ),
              IconButton(icon: const Icon(Icons.delete_outline_rounded, color: _coral), onPressed: onDelete),
            ],
          ),
          const SizedBox(height: 10),
          ...List.generate(step.items.length, (itemIndex) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.check_box_outline_blank_rounded, color: _deepMint),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        initialValue: step.items[itemIndex],
                        onChanged: (v) => step.items[itemIndex] = v,
                        decoration: _inputDecoration('子步骤'),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: _softBrown),
                      onPressed: () {
                        step.items.removeAt(itemIndex);
                        onChanged();
                      },
                    ),
                  ],
                ),
              )),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                step.items.add('新检查项');
                onChanged();
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('添加子步骤'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RunScreen extends StatelessWidget {
  const _RunScreen({
    super.key,
    required this.sop,
    required this.index,
    required this.checked,
    required this.onBack,
    required this.onPrev,
    required this.onNext,
    required this.onToggle,
    required this.onJump,
  });

  final Sop sop;
  final int index;
  final Map<int, Set<int>> checked;
  final VoidCallback onBack;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final void Function(int itemIndex, bool value) onToggle;
  final ValueChanged<int> onJump;

  @override
  Widget build(BuildContext context) {
    final step = sop.steps[index];
    final done = checked[index] ?? {};
    final progress = (index + 1) / sop.steps.length;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: onBack),
        title: Text('${index + 1}/${sop.steps.length}', style: const TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(icon: const Icon(Icons.map_rounded), onPressed: () => _showOverview(context)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          LinearProgressIndicator(value: progress, color: _deepMint, backgroundColor: _paper, minHeight: 10, borderRadius: BorderRadius.circular(8)),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: _softBox(_mint),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sop.title, style: const TextStyle(color: _brown, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                Text(step.title, style: const TextStyle(color: _brown, fontSize: 28, fontWeight: FontWeight.w900, height: 1.15)),
                const SizedBox(height: 18),
                ...List.generate(step.items.length, (i) {
                  final isDone = done.contains(i);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(color: _paper.withValues(alpha: 0.92), borderRadius: BorderRadius.circular(18)),
                    child: CheckboxListTile(
                      value: isDone,
                      activeColor: _deepMint,
                      checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      title: Text(step.items[i], style: TextStyle(color: _brown, fontWeight: isDone ? FontWeight.w800 : FontWeight.w600)),
                      onChanged: (v) => onToggle(i, v ?? false),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Row(
          children: [
            Expanded(child: _SecondaryButton(icon: Icons.chevron_left_rounded, label: '上一步', onTap: index == 0 ? null : onPrev)),
            const SizedBox(width: 12),
            Expanded(child: _PrimaryButton(icon: index == sop.steps.length - 1 ? Icons.flag_rounded : Icons.chevron_right_rounded, label: index == sop.steps.length - 1 ? '完成' : '下一步', onTap: onNext)),
          ],
        ),
      ),
    );
  }

  void _showOverview(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _paper,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('总览', style: TextStyle(color: _brown, fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: sop.steps.length,
                itemBuilder: (context, i) => ListTile(
                  leading: CircleAvatar(backgroundColor: i == index ? _coral : _mint, foregroundColor: _brown, child: Text('${i + 1}')),
                  title: Text(sop.steps[i].title, style: const TextStyle(color: _brown, fontWeight: FontWeight.w800)),
                  subtitle: Text('${checked[i]?.length ?? 0}/${sop.steps[i].items.length} 已勾选'),
                  onTap: () {
                    Navigator.pop(context);
                    onJump(i);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IslandBackdrop extends StatelessWidget {
  const _IslandBackdrop();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(
        painter: _BackdropPainter(),
      ),
    );
  }
}

class _BackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    paint.color = _sky.withValues(alpha: 0.38);
    canvas.drawCircle(Offset(size.width * 0.86, size.height * 0.08), 72, paint);
    paint.color = _mint.withValues(alpha: 0.32);
    canvas.drawCircle(Offset(size.width * 0.05, size.height * 0.22), 54, paint);
    paint.color = _honey.withValues(alpha: 0.32);
    canvas.drawOval(Rect.fromLTWH(size.width * 0.10, size.height * 0.88, size.width * 0.78, 96), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _IslandMark extends StatelessWidget {
  const _IslandMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _IslandMarkPainter()),
    );
  }
}

class _IslandMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    paint.color = _honey;
    canvas.drawOval(Rect.fromLTWH(size.width * .08, size.height * .62, size.width * .84, size.height * .25), paint);
    paint.color = _mint;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * .18, size.height * .40, size.width * .64, size.height * .28), const Radius.circular(18)), paint);
    paint.color = _coral;
    canvas.drawCircle(Offset(size.width * .64, size.height * .34), size.width * .16, paint);
    paint.color = _brown;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * .48, size.height * .28, 6, size.height * .43), const Radius.circular(4)), paint);
    paint.color = _paper;
    final path = Path()
      ..moveTo(size.width * .30, size.height * .53)
      ..lineTo(size.width * .43, size.height * .64)
      ..lineTo(size.width * .70, size.height * .44)
      ..lineTo(size.width * .74, size.height * .50)
      ..lineTo(size.width * .43, size.height * .72)
      ..lineTo(size.width * .26, size.height * .58)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CelebrationDialog extends StatefulWidget {
  const _CelebrationDialog({required this.sopTitle, required this.runCount});

  final String sopTitle;
  final int runCount;

  @override
  State<_CelebrationDialog> createState() => _CelebrationDialogState();
}

class _CelebrationDialogState extends State<_CelebrationDialog> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1700))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: double.infinity,
              height: 360,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => CustomPaint(
                  painter: _ConfettiPainter(progress: _controller.value),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
              decoration: _softBox(_paper),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 108,
                    height: 108,
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        final pulse = 1 + math.sin(_controller.value * math.pi * 2) * 0.06;
                        return Transform.scale(
                          scale: pulse,
                          child: Container(
                            decoration: const BoxDecoration(color: _honey, shape: BoxShape.circle),
                            child: const Icon(Icons.celebration_rounded, color: _brown, size: 58),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text('SOP 已完成', style: TextStyle(color: _brown, fontSize: 28, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Text(
                    widget.sopTitle,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _softBrown, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(color: _mint, borderRadius: BorderRadius.circular(999)),
                    child: Text(
                      '这是第 ${widget.runCount} 次完成该 SOP',
                      style: const TextStyle(color: _brown, fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _PrimaryButton(
                    icon: Icons.check_rounded,
                    label: '完成',
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.progress});

  final double progress;

  static const _colors = [_coral, _honey, _mint, _sky, Color(0xFFE9A7CF), Color(0xFF8CC7A8)];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height * 0.36);

    for (var i = 0; i < 46; i++) {
      final seed = i * 37.0;
      final angle = (seed % 360) * math.pi / 180;
      final wave = (progress + (i % 9) / 9) % 1;
      final radius = 26 + wave * (size.shortestSide * 0.58);
      final fall = wave * size.height * 0.34;
      final drift = math.sin((progress * 2 + i) * math.pi) * 18;
      final x = center.dx + math.cos(angle) * radius + drift;
      final y = center.dy + math.sin(angle) * radius * 0.72 + fall;
      final alpha = (1 - wave).clamp(0.18, 1.0);
      paint.color = _colors[i % _colors.length].withValues(alpha: alpha);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle + progress * math.pi * 3);
      if (i % 3 == 0) {
        canvas.drawCircle(Offset.zero, 4.5, paint);
      } else if (i % 3 == 1) {
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-4, -9, 8, 18), const Radius.circular(3)), paint);
      } else {
        final path = Path()
          ..moveTo(0, -8)
          ..lineTo(7, 6)
          ..lineTo(-7, 6)
          ..close();
        canvas.drawPath(path, paint);
      }
      canvas.restore();
    }

    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 7; i++) {
      final side = i.isEven ? -1 : 1;
      final baseX = center.dx + side * (70 + i * 6);
      final baseY = center.dy + 12 + i * 3;
      final wave = (progress + i * 0.12) % 1;
      paint.color = _colors[(i + 2) % _colors.length].withValues(alpha: 0.85);
      final path = Path()..moveTo(baseX, baseY);
      for (var s = 0; s < 5; s++) {
        path.quadraticBezierTo(
          baseX + side * (14 + s * 10),
          baseY - 22 + math.sin((wave + s * .2) * math.pi * 2) * 10,
          baseX + side * (24 + s * 18),
          baseY - 5 + s * 7,
        );
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => oldDelegate.progress != progress;
}

class _TextBox extends StatelessWidget {
  const _TextBox({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: _brown, fontWeight: FontWeight.w800),
      decoration: _inputDecoration(label),
    );
  }
}

InputDecoration _inputDecoration(String label) => InputDecoration(
      labelText: label,
      filled: true,
      fillColor: _paper,
      labelStyle: const TextStyle(color: _softBrown),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: _line)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: _deepMint, width: 2)),
    );

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: _coral,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: _brown,
        side: const BorderSide(color: _line),
        backgroundColor: _paper,
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.color, required this.onTap});

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(18), boxShadow: const [BoxShadow(color: Color(0x22000000), offset: Offset(0, 4), blurRadius: 0)]),
        child: Icon(icon, color: _brown),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(color: _cream, borderRadius: BorderRadius.circular(999), border: Border.all(color: _line)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: _deepMint),
            const SizedBox(width: 5),
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _softBrown, fontSize: 12, fontWeight: FontWeight.w700))),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _softBox(_paper),
      child: Column(
        children: [
          Text(value, style: const TextStyle(color: _brown, fontSize: 24, fontWeight: FontWeight.w900)),
          Text(label, style: const TextStyle(color: _softBrown, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

BoxDecoration _softBox(Color color) => BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: Colors.white.withValues(alpha: 0.75), width: 2),
      boxShadow: const [
        BoxShadow(color: Color(0x22000000), offset: Offset(0, 6), blurRadius: 0),
      ],
    );

String _formatTime(DateTime? time) {
  if (time == null) return '未执行';
  final now = DateTime.now();
  final diff = now.difference(time);
  if (diff.inMinutes < 60) return '${diff.inMinutes} 分钟前';
  if (diff.inHours < 24) return '${diff.inHours} 小时前';
  if (diff.inDays < 7) return '${diff.inDays} 天前';
  return '${time.month}/${time.day}';
}
