import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_controller.dart';
import 'app_shell.dart';
import 'models/sop.dart';
import 'theme/app_theme.dart' show AppColors, AssetBlendCard;

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
const _headerBg = Color(0xFFF5EED8);
const _cardBorder = Color(0xFFD8C7A8);
const _mySopHero = 'assets/images/my_sop/hero_my_sop.png';
const _runStepHero = 'assets/images/run/hero_run_step.png';
const _runCompleteImage = 'assets/images/run/state_complete.png';
const _sopThumbPersonal = 'assets/images/plaza/category_personal.png';
const _sopThumbTeam = 'assets/images/plaza/category_team.png';
const _sopThumbFactory = 'assets/images/plaza/category_factory.png';

String _sopThumbFor(int variant) => switch (variant % 3) {
      1 => _sopThumbTeam,
      2 => _sopThumbFactory,
      _ => _sopThumbPersonal,
    };

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
      home: AppShell(
        mySopBuilder: (controller, pendingRunSopId, onPendingRunHandled) => SopHomePage(
          controller: controller,
          pendingRunSopId: pendingRunSopId,
          onPendingRunHandled: onPendingRunHandled,
        ),
      ),
    );
  }
}

enum _Mode { list, detail, edit, run }

class SopHomePage extends StatefulWidget {
  const SopHomePage({
    super.key,
    required this.controller,
    this.pendingRunSopId,
    this.onPendingRunHandled,
  });

  final AppController controller;
  final String? pendingRunSopId;
  final VoidCallback? onPendingRunHandled;

  @override
  State<SopHomePage> createState() => _SopHomePageState();
}

class _SopHomePageState extends State<SopHomePage> {
  var _mode = _Mode.list;
  Sop? _active;
  int _runIndex = 0;
  final Map<int, Set<int>> _checked = {};

  List<Sop> get _sops => widget.controller.sops;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _handlePendingRun());
  }

  @override
  void didUpdateWidget(SopHomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _handlePendingRun();
  }

  void _handlePendingRun() {
    final id = widget.pendingRunSopId;
    if (id == null || widget.controller.loading) return;
    Sop? sop;
    for (final s in _sops) {
      if (s.id == id) {
        sop = s;
        break;
      }
    }
    if (sop != null) {
      _startRun(sop);
      widget.onPendingRunHandled?.call();
    }
  }

  Future<void> _persist() => widget.controller.save();

  void _open(Sop sop) => setState(() {
        _active = sop;
        _mode = _Mode.detail;
      });

  void _newSop() => setState(() {
        _active = Sop(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          title: '',
          scene: '',
          description: '',
          illustration: _sops.length % 3,
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
    if (widget.controller.loading) {
      return const Center(child: CircularProgressIndicator(color: _deepMint));
    }
    return AnimatedSwitcher(
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
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 8, right: 4),
        child: _NewSopFab(onTap: onNew),
      ),
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: _ListHeader()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 88),
            sliver: SliverList.separated(
              itemCount: sops.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _SopCard(
                sop: sops[index],
                onOpen: () => onOpen(sops[index]),
                onRun: () => onRun(sops[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListHeader extends StatelessWidget {
  const _ListHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
      child: Stack(
        children: [
          const AssetBlendCard(
            image: _mySopHero,
            title: '我的 SOP',
            subtitle: '整理自己的流程库，随时挑一条开始执行。',
            tint: AppColors.mint,
            height: 132,
            titleSize: 24,
          ),
          Positioned(
            top: 14,
            right: 14,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: _paper.withValues(alpha: 0.86), shape: BoxShape.circle, border: Border.all(color: _line)),
              child: const Icon(Icons.search_rounded, color: _softBrown, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}

const _cardArtSize = 86.0;

class _SopCard extends StatelessWidget {
  const _SopCard({required this.sop, required this.onOpen, required this.onRun});

  final Sop sop;
  final VoidCallback onOpen;
  final VoidCallback onRun;

  @override
  Widget build(BuildContext context) {
    final desc = sop.description.trim().isEmpty ? sop.scene : sop.description;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onOpen,
        child: Ink(
          decoration: _cardDecoration(_paper),
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SopAssetThumb(image: _sopThumbFor(sop.illustration), size: _cardArtSize),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: _cardArtSize,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              sop.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: _brown, fontSize: 16, fontWeight: FontWeight.w900, height: 1.15),
                            ),
                          ),
                          if (sop.fromPlaza) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _sky.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('广场', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: _brown)),
                            ),
                          ],
                          const SizedBox(width: 6),
                          _StepBadge(count: sop.steps.length),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Expanded(
                        child: Text(
                          desc,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: _softBrown, fontSize: 11.5, height: 1.25, fontWeight: FontWeight.w500),
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _MetaLine(icon: Icons.pets_rounded, iconColor: _deepMint, label: '执行 ${sop.runCount} 次', compact: true),
                                const SizedBox(height: 1),
                                _MetaLine(icon: Icons.schedule_rounded, iconColor: const Color(0xFF6BAED6), label: '上次 ${_formatLastRun(sop.lastRunAt)}', compact: true),
                              ],
                            ),
                          ),
                          _RunButton(onTap: onRun, compact: true),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepBadge extends StatelessWidget {
  const _StepBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF2D4A6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _line, width: 1),
      ),
      child: Text('步骤 $count', style: const TextStyle(color: _brown, fontSize: 10.5, fontWeight: FontWeight.w800, height: 1.1)),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.icon, required this.iconColor, required this.label, this.compact = false});

  final IconData icon;
  final Color iconColor;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: compact ? 13 : 16, color: iconColor),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: _softBrown, fontSize: compact ? 11 : 13, fontWeight: FontWeight.w600, height: 1.1),
          ),
        ),
      ],
    );
  }
}

class _RunButton extends StatelessWidget {
  const _RunButton({required this.onTap, this.compact = false});

  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFC8EBD4),
      borderRadius: BorderRadius.circular(compact ? 12 : 14),
      elevation: compact ? 1 : 0,
      shadowColor: const Color(0x33000000),
      child: InkWell(
        borderRadius: BorderRadius.circular(compact ? 12 : 14),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14, vertical: compact ? 5 : 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: compact ? 18 : 22,
                height: compact ? 18 : 22,
                decoration: const BoxDecoration(color: _deepMint, shape: BoxShape.circle),
                child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: compact ? 13 : 16),
              ),
              const SizedBox(width: 4),
              Text('运行', style: TextStyle(color: _brown, fontWeight: FontWeight.w900, fontSize: compact ? 12 : 14, height: 1)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewSopFab extends StatelessWidget {
  const _NewSopFab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      shadowColor: _coral.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(999),
      color: _coral,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 6),
              const Text('新建', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
              const SizedBox(width: 4),
              Icon(Icons.eco_rounded, size: 16, color: Colors.white.withValues(alpha: 0.85)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SopAssetThumb extends StatelessWidget {
  const _SopAssetThumb({required this.image, this.size = _cardArtSize});

  final String image;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line, width: 1.2),
        boxShadow: const [BoxShadow(color: Color(0x10000000), offset: Offset(0, 2), blurRadius: 0)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.asset(image, fit: BoxFit.cover),
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
          if (sop.description.trim().isNotEmpty)
            Text(sop.description, style: const TextStyle(color: _softBrown, fontSize: 16, height: 1.4))
          else
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
  late final TextEditingController _description;
  late final Sop _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.sop;
    _title = TextEditingController(text: _draft.title);
    _scene = TextEditingController(text: _draft.scene);
    _description = TextEditingController(text: _draft.description);
  }

  @override
  void dispose() {
    _title.dispose();
    _scene.dispose();
    _description.dispose();
    super.dispose();
  }

  void _save() {
    _draft.title = _title.text.trim().isEmpty ? '未命名 SOP' : _title.text.trim();
    _draft.scene = _scene.text.trim().isEmpty ? '未设置场景' : _scene.text.trim();
    _draft.description = _description.text.trim();
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
          const SizedBox(height: 12),
          _TextBox(controller: _description, label: '描述说明'),
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
          AssetBlendCard(
            image: _runStepHero,
            title: step.title,
            subtitle: '${sop.title} · 第 ${index + 1} 步 / 共 ${sop.steps.length} 步',
            tint: AppColors.mint,
            height: 142,
            titleSize: 21,
            subtitleWidth: 230,
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: _softBox(_mint),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
    paint.color = _cream;
    canvas.drawRect(Offset.zero & size, paint);

    for (var i = 0; i < 8; i++) {
      final x = size.width * (0.08 + (i * 0.11) % 0.84);
      final y = size.height * (0.06 + (i * 0.13) % 0.82);
      _drawStar(canvas, Offset(x, y), 5 + (i % 3), _honey.withValues(alpha: 0.55));
      if (i.isEven) _drawLeaf(canvas, Offset(x + 18, y + 12), _deepMint.withValues(alpha: 0.35));
    }

    paint.color = _sky.withValues(alpha: 0.28);
    canvas.drawCircle(Offset(size.width * 0.86, size.height * 0.08), 72, paint);
    paint.color = _mint.withValues(alpha: 0.32);
    canvas.drawCircle(Offset(size.width * 0.05, size.height * 0.22), 54, paint);
    paint.color = _honey.withValues(alpha: 0.32);
    canvas.drawOval(Rect.fromLTWH(size.width * 0.10, size.height * 0.88, size.width * 0.78, 96), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

void _drawStar(Canvas canvas, Offset center, double radius, Color color) {
  final paint = Paint()..color = color..style = PaintingStyle.fill;
  final path = Path();
  for (var i = 0; i < 4; i++) {
    final angle = i * math.pi / 2;
    path.moveTo(center.dx, center.dy);
    path.lineTo(center.dx + math.cos(angle) * radius, center.dy + math.sin(angle) * radius);
    path.lineTo(center.dx + math.cos(angle + 0.35) * radius * 0.35, center.dy + math.sin(angle + 0.35) * radius * 0.35);
    path.close();
  }
  canvas.drawPath(path, paint);
}

void _drawLeaf(Canvas canvas, Offset center, Color color) {
  final paint = Paint()..color = color;
  canvas.drawOval(Rect.fromCenter(center: center, width: 10, height: 6), paint);
}

class _IllustrationPainter extends CustomPainter {
  _IllustrationPainter({required this.variant});

  final int variant;

  @override
  void paint(Canvas canvas, Size size) {
    switch (variant) {
      case 1:
        _paintBoard(canvas, size);
      case 2:
        _paintLighthouse(canvas, size);
      default:
        _paintCottage(canvas, size);
    }
  }

  void _paintCottage(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    paint.color = const Color(0xFFBFE5F5);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    paint.color = _mint;
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.62, size.width, size.height * 0.38), paint);
    paint.color = const Color(0xFF8B5E3C);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.28, size.height * 0.38, size.width * 0.44, size.height * 0.34), paint);
    paint.color = _coral;
    final roof = Path()
      ..moveTo(size.width * 0.22, size.height * 0.40)
      ..lineTo(size.width * 0.50, size.height * 0.18)
      ..lineTo(size.width * 0.78, size.height * 0.40)
      ..close();
    canvas.drawPath(roof, paint);
    paint.color = _sky;
    canvas.drawRect(Rect.fromLTWH(size.width * 0.42, size.height * 0.50, size.width * 0.16, size.height * 0.14), paint);
  }

  void _paintBoard(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    paint.color = _cream;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    paint.color = const Color(0xFF9B6B43);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.18, size.height * 0.12, size.width * 0.64, size.height * 0.76), const Radius.circular(6)), paint);
    paint.color = _paper;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.24, size.height * 0.18, size.width * 0.52, size.height * 0.46), const Radius.circular(4)), paint);
    paint.color = _sky;
    canvas.drawRect(Rect.fromLTWH(size.width * 0.30, size.height * 0.24, size.width * 0.40, size.height * 0.18), paint);
    paint.color = _mint;
    canvas.drawCircle(Offset(size.width * 0.72, size.height * 0.72), size.width * 0.08, paint);
  }

  void _paintLighthouse(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    paint.color = _sky;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height * 0.55), paint);
    paint.color = const Color(0xFF7EC0E8);
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.55, size.width, size.height * 0.45), paint);
    paint.color = _paper;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.58, size.height * 0.48, size.width * 0.28, size.height * 0.34), const Radius.circular(6)), paint);
    paint.color = _coral;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.22, size.height * 0.22, size.width * 0.18, size.height * 0.58), const Radius.circular(4)), paint);
    paint.color = _honey;
    canvas.drawRect(Rect.fromLTWH(size.width * 0.20, size.height * 0.16, size.width * 0.22, size.height * 0.10), paint);
  }

  @override
  bool shouldRepaint(covariant _IllustrationPainter oldDelegate) => oldDelegate.variant != variant;
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
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: Image.asset(
                              _runCompleteImage,
                              fit: BoxFit.cover,
                            ),
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

BoxDecoration _cardDecoration(Color color) => BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _cardBorder, width: 1.2),
      boxShadow: const [
        BoxShadow(color: Color(0x14000000), offset: Offset(0, 3), blurRadius: 6),
      ],
    );

String _formatLastRun(DateTime? time) {
  if (time == null) return '未执行';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(time.year, time.month, time.day);
  final hm = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  if (day == today) return '今天 $hm';
  if (day == today.subtract(const Duration(days: 1))) return '昨天 $hm';
  if (now.difference(time).inDays < 7) return '${now.difference(time).inDays} 天前';
  return '${time.month}/${time.day} $hm';
}
