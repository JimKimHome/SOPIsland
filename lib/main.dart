import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_controller.dart';
import 'app_shell.dart';
import 'models/ai_config.dart';
import 'models/sop.dart';
import 'services/ai_sop_service.dart';
import 'services/calendar_service.dart';
import 'theme/app_theme.dart' show AppColors, buildAppTheme;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = FlutterError.presentError;
  ErrorWidget.builder = (details) => const _AppErrorFallback();
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

const _cream = AppColors.cream;
const _paper = AppColors.paper;
const _mint = AppColors.mint;
const _deepMint = AppColors.deepMint;
const _sky = AppColors.sky;
const _coral = AppColors.coral;
const _honey = AppColors.honey;
const _brown = AppColors.brown;
const _softBrown = AppColors.softBrown;
const _line = AppColors.line;
const _headerBg = AppColors.headerBg;
const _cardBorder = AppColors.cardBorder;

class SopIslandApp extends StatelessWidget {
  const SopIslandApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OrSOP',
      themeMode: ThemeMode.light,
      theme: buildAppTheme(),
      home: AppShell(
        mySopBuilder:
            (
              controller,
              pendingRunSopId,
              pendingRunProgressId,
              onPendingRunHandled,
              onGenerateWithAi,
              onOpenAiConfig,
            ) => SopHomePage(
              controller: controller,
              onGenerateWithAi: onGenerateWithAi,
              onOpenAiConfig: onOpenAiConfig,
              pendingRunSopId: pendingRunSopId,
              pendingRunProgressId: pendingRunProgressId,
              onPendingRunHandled: onPendingRunHandled,
            ),
      ),
    );
  }
}

class _AppErrorFallback extends StatelessWidget {
  const _AppErrorFallback();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _cream,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _paper,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _line),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline_rounded, color: _softBrown, size: 28),
              SizedBox(height: 10),
              Text(
                '这个页面暂时无法显示',
                style: TextStyle(
                  color: _brown,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 6),
              Text(
                '请返回上一页后再试一次。',
                textAlign: TextAlign.center,
                style: TextStyle(color: _softBrown),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _Mode { list, detail, edit, run }

enum _RunStartChoice { createNew, continueExisting }

class SopHomePage extends StatefulWidget {
  const SopHomePage({
    super.key,
    required this.controller,
    required this.onGenerateWithAi,
    required this.onOpenAiConfig,
    this.pendingRunSopId,
    this.pendingRunProgressId,
    this.onPendingRunHandled,
  });

  final AppController controller;
  final VoidCallback onGenerateWithAi;
  final VoidCallback onOpenAiConfig;
  final String? pendingRunSopId;
  final String? pendingRunProgressId;
  final VoidCallback? onPendingRunHandled;

  @override
  State<SopHomePage> createState() => _SopHomePageState();
}

class _SopHomePageState extends State<SopHomePage> {
  var _mode = _Mode.list;
  Sop? _active;
  String? _runProgressId;
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
    final progressId = widget.pendingRunProgressId;
    Sop? sop;
    for (final s in _sops) {
      if (s.id == id) {
        sop = s;
        break;
      }
    }
    if (sop != null) {
      if (progressId == null) {
        _requestRun(sop, preferContinue: sop.runProgresses.isNotEmpty);
      } else {
        final index = sop.runProgresses.indexWhere(
          (progress) => progress.id == progressId,
        );
        if (index >= 0) {
          _startRun(sop, progress: sop.runProgresses[index]);
        } else {
          _requestRun(sop, preferContinue: sop.runProgresses.isNotEmpty);
        }
      }
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
      steps: [
        SopStep(title: '第一步', items: ['确认事项']),
      ],
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

  Future<void> _requestRun(Sop sop, {bool preferContinue = false}) async {
    final progresses = _sortedRunProgresses(sop);
    if (progresses.isEmpty) {
      _startNewRun(sop);
      return;
    }
    final choice = preferContinue
        ? _RunStartChoice.continueExisting
        : await _askRunStartChoice(sop, progresses.first);
    if (!mounted || choice == null) return;
    if (choice == _RunStartChoice.continueExisting) {
      _startRun(sop, progress: progresses.first);
    } else {
      _startNewRun(sop);
    }
  }

  List<SopRunProgress> _sortedRunProgresses(Sop sop) {
    return List<SopRunProgress>.from(sop.runProgresses)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<_RunStartChoice?> _askRunStartChoice(
    Sop sop,
    SopRunProgress latestProgress,
  ) {
    final count = sop.runProgresses.length;
    return showDialog<_RunStartChoice>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _paper,
        title: const Text(
          '已有进行中的 SOP',
          style: TextStyle(color: _brown, fontWeight: FontWeight.w900),
        ),
        content: Text(
          '“${sop.title}”已有$count 个进行中的实例。你要新建实例，还是在进行中的 SOP 上继续？\n\n最近暂存：${_formatLastRun(latestProgress.updatedAt)}',
          style: const TextStyle(color: _softBrown, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, _RunStartChoice.continueExisting),
            child: const Text('在进行中的 SOP 上继续'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _coral),
            onPressed: () => Navigator.pop(context, _RunStartChoice.createNew),
            child: const Text('新建实例'),
          ),
        ],
      ),
    );
  }

  void _startNewRun(Sop sop) {
    _startRun(
      sop,
      progress: SopRunProgress(
        currentStepIndex: 0,
        checkedItems: <int, Set<int>>{},
      ),
      persistNewProgress: false,
    );
  }

  Future<String?> _askRunInstanceName(Sop sop, {String? initialName}) {
    final nextNumber = sop.runProgresses.length + 1;
    final fallback = '实例 $nextNumber';
    final controller = TextEditingController(
      text: initialName?.trim().isNotEmpty == true ? initialName!.trim() : '',
    );
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _paper,
        title: const Text(
          '命名暂存实例',
          style: TextStyle(color: _brown, fontWeight: FontWeight.w900),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: _inputDecoration(
            '实例名称',
          ).copyWith(hintText: '默认：$fallback'),
          onSubmitted: (value) =>
              Navigator.pop(context, value.trim().isEmpty ? fallback : value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _coral),
            onPressed: () {
              final value = controller.text.trim();
              Navigator.pop(context, value.isEmpty ? fallback : value);
            },
            child: const Text('暂存'),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }

  void _startRun(
    Sop sop, {
    SopRunProgress? progress,
    bool persistNewProgress = true,
  }) {
    if (sop.steps.isEmpty) {
      sop.steps = [
        SopStep(title: '确认事项', items: ['确认完成']),
      ];
    }
    final runningProgress =
        progress ??
        SopRunProgress(currentStepIndex: 0, checkedItems: <int, Set<int>>{});
    final existing = sop.runProgresses.indexWhere(
      (item) => item.id == runningProgress.id,
    );
    if (persistNewProgress && existing < 0) {
      sop.runProgresses.add(runningProgress);
      _persist();
    }
    setState(() {
      _active = sop;
      _runProgressId = runningProgress.id;
      final maxIndex = sop.steps.isEmpty ? 0 : sop.steps.length - 1;
      _runIndex = runningProgress.currentStepIndex.clamp(0, maxIndex).toInt();
      _checked.clear();
      for (final entry in runningProgress.checkedItems.entries) {
        if (entry.key < 0 || entry.key >= sop.steps.length) continue;
        final itemCount = sop.steps[entry.key].items.length;
        final validItems = entry.value
            .where((itemIndex) => itemIndex >= 0 && itemIndex < itemCount)
            .toSet();
        if (validItems.isNotEmpty) _checked[entry.key] = validItems;
      }
      _mode = _Mode.run;
    });
  }

  Future<void> _saveRunProgress({bool exit = false}) async {
    final sop = _active;
    if (sop == null) return;
    final checkedItems = _checked.map(
      (key, value) => MapEntry(key, Set<int>.from(value)),
    );
    final existing = sop.runProgresses.indexWhere(
      (p) => p.id == _runProgressId,
    );
    final previous = existing >= 0 ? sop.runProgresses[existing] : null;
    final name = await _askRunInstanceName(sop, initialName: previous?.name);
    if (!mounted || name == null) return;
    final progress = SopRunProgress(
      id: _runProgressId,
      name: name,
      currentStepIndex: _runIndex,
      checkedItems: checkedItems,
      createdAt: previous?.createdAt,
    );
    if (existing >= 0) {
      sop.runProgresses[existing] = progress;
    } else {
      sop.runProgresses.add(progress);
    }
    _runProgressId = progress.id;
    await _persist();
    if (!mounted) return;
    if (exit) setState(() => _mode = _Mode.list);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('已暂存，下次可以继续完成。')));
  }

  Future<void> _finishRun() async {
    final sop = _active;
    if (sop == null) return;
    setState(() {
      sop.runCount += 1;
      sop.lastRunAt = DateTime.now();
      if (_runProgressId != null) {
        sop.runProgresses.removeWhere(
          (progress) => progress.id == _runProgressId,
        );
      }
      _runProgressId = null;
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
      pageBuilder: (context, animation, secondaryAnimation) =>
          _CelebrationDialog(sopTitle: sop.title, runCount: sop.runCount),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );
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
          onRun: _requestRun,
          onNew: _newSop,
          onGenerateWithAi: widget.onGenerateWithAi,
          onOpenAiConfig: widget.onOpenAiConfig,
        ),
        _Mode.detail => _DetailScreen(
          key: ValueKey('detail-${_active?.id}'),
          sop: _active!,
          onBack: () => setState(() => _mode = _Mode.list),
          onRun: () => _requestRun(_active!),
          onEdit: () => _edit(_active!),
          onTogglePin: () => _togglePin(_active!),
          onSetReminder: () => _setReminder(_active!),
          onDelete: () => _confirmDelete(_active!),
        ),
        _Mode.edit => _EditScreen(
          key: ValueKey('edit-${_active?.id}'),
          sop: _active!,
          aiConfig: widget.controller.aiConfig,
          onOpenAiConfig: widget.onOpenAiConfig,
          onCancel: () => setState(
            () => _mode = _active!.title.isEmpty ? _Mode.list : _Mode.detail,
          ),
          onSave: _saveEdit,
        ),
        _Mode.run => _RunScreen(
          key: ValueKey('run-${_active?.id}'),
          sop: _active!,
          index: _runIndex,
          checked: _checked,
          onBack: () => setState(() => _mode = _Mode.detail),
          onSaveProgress: () => _saveRunProgress(exit: true),
          onPrev: () => setState(
            () =>
                _runIndex = (_runIndex - 1).clamp(0, _active!.steps.length - 1),
          ),
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

  Future<void> _togglePin(Sop sop) async {
    setState(() => sop.pinned = !sop.pinned);
    await _persist();
  }

  Future<void> _setReminder(Sop sop) async {
    final reminder = await showModalBottomSheet<SopReminder>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) => _ReminderSheet(initial: sop.reminder),
    );
    if (reminder == null) return;
    setState(() => sop.reminder = reminder);
    await _persist();
    try {
      await CalendarService.createSopReminder(sop);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已打开系统日历，请确认保存提醒。')));
    } on PlatformException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message ?? '无法打开系统日历')));
    }
  }

  Future<void> _confirmDelete(Sop sop) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _paper,
        title: const Text(
          '删除 SOP？',
          style: TextStyle(color: _brown, fontWeight: FontWeight.w900),
        ),
        content: Text(
          '“${sop.title}” 删除后不可恢复。',
          style: const TextStyle(color: _softBrown),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
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

enum _SopListFilter { pinned, recent, all }

class _ListScreen extends StatefulWidget {
  const _ListScreen({
    super.key,
    required this.sops,
    required this.onOpen,
    required this.onRun,
    required this.onNew,
    required this.onGenerateWithAi,
    required this.onOpenAiConfig,
  });

  final List<Sop> sops;
  final ValueChanged<Sop> onOpen;
  final ValueChanged<Sop> onRun;
  final VoidCallback onNew;
  final VoidCallback onGenerateWithAi;
  final VoidCallback onOpenAiConfig;

  @override
  State<_ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<_ListScreen> {
  var _filter = _SopListFilter.all;
  var _query = '';

  List<Sop> get _visibleSops {
    final normalizedQuery = _query.trim().toLowerCase();
    final list = widget.sops.where((sop) {
      if (_filter == _SopListFilter.pinned && !sop.pinned) return false;
      if (normalizedQuery.isEmpty) return true;
      return [
        sop.title,
        sop.scene,
        sop.description,
        ...sop.steps.map((step) => step.title),
        ...sop.steps.expand((step) => step.items),
      ].any((value) => value.toLowerCase().contains(normalizedQuery));
    }).toList();
    if (_filter == _SopListFilter.pinned) {
      list.sort((a, b) => a.title.compareTo(b.title));
      return list;
    }
    if (_filter == _SopListFilter.recent) {
      list.sort((a, b) {
        if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
        final aTime = a.lastRunAt?.millisecondsSinceEpoch ?? 0;
        final bTime = b.lastRunAt?.millisecondsSinceEpoch ?? 0;
        return bTime.compareTo(aTime);
      });
      return list;
    }
    list.sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      return a.title.compareTo(b.title);
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final visibleSops = _visibleSops;
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 8, right: 4),
        child: _NewSopFab(onTap: widget.onNew),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _ListHeader(
              filter: _filter,
              query: _query,
              onFilterChanged: (filter) => setState(() => _filter = filter),
              onQueryChanged: (value) => setState(() => _query = value),
              onGenerateWithAi: widget.onGenerateWithAi,
              onOpenAiConfig: widget.onOpenAiConfig,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 88),
            sliver: visibleSops.isEmpty
                ? SliverToBoxAdapter(
                    child: _EmptyLibraryState(
                      hasQuery: _query.trim().isNotEmpty,
                      onGenerateWithAi: widget.onGenerateWithAi,
                    ),
                  )
                : SliverList.separated(
                    itemCount: visibleSops.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _SopCard(
                      sop: visibleSops[index],
                      onOpen: () => widget.onOpen(visibleSops[index]),
                      onRun: () => widget.onRun(visibleSops[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ListHeader extends StatelessWidget {
  const _ListHeader({
    required this.filter,
    required this.query,
    required this.onFilterChanged,
    required this.onQueryChanged,
    required this.onGenerateWithAi,
    required this.onOpenAiConfig,
  });

  final _SopListFilter filter;
  final String query;
  final ValueChanged<_SopListFilter> onFilterChanged;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onGenerateWithAi;
  final VoidCallback onOpenAiConfig;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '流程库',
                      style: TextStyle(
                        color: _brown,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '整理、编辑和维护你的 SOP 资产。',
                      style: TextStyle(
                        color: _softBrown,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: onOpenAiConfig,
                icon: const Icon(Icons.tune_rounded),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SearchBox(value: query, onChanged: onQueryChanged),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onGenerateWithAi,
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('用 AI 新建流程'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
                foregroundColor: _brown,
                backgroundColor: _paper,
                side: const BorderSide(color: _line),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<_SopListFilter>(
            segments: const [
              ButtonSegment(value: _SopListFilter.all, label: Text('全部')),
              ButtonSegment(value: _SopListFilter.pinned, label: Text('置顶')),
              ButtonSegment(value: _SopListFilter.recent, label: Text('最近')),
            ],
            selected: {filter},
            onSelectionChanged: (selected) => onFilterChanged(selected.first),
          ),
        ],
      ),
    );
  }
}

class _SearchBox extends StatefulWidget {
  const _SearchBox({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<_SearchBox> createState() => _SearchBoxState();
}

class _SearchBoxState extends State<_SearchBox> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _SearchBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.text = widget.value;
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      decoration: _inputDecoration('搜索 SOP').copyWith(
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: widget.value.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => widget.onChanged(''),
              ),
      ),
    );
  }
}

class _EmptyLibraryState extends StatelessWidget {
  const _EmptyLibraryState({
    required this.hasQuery,
    required this.onGenerateWithAi,
  });

  final bool hasQuery;
  final VoidCallback onGenerateWithAi;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _listItemDecoration(),
      child: Column(
        children: [
          const Icon(Icons.folder_open_rounded, color: _softBrown, size: 34),
          const SizedBox(height: 10),
          Text(
            hasQuery ? '没有找到匹配的 SOP' : '流程库还是空的',
            style: const TextStyle(
              color: _brown,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasQuery ? '换个关键词试试，或新建一条流程。' : '先用 AI 生成一条可以编辑的 SOP。',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _softBrown, height: 1.35),
          ),
          const SizedBox(height: 14),
          _PrimaryButton(
            icon: Icons.auto_awesome_rounded,
            label: '用 AI 新建流程',
            onTap: onGenerateWithAi,
          ),
        ],
      ),
    );
  }
}

class _SopCard extends StatelessWidget {
  const _SopCard({
    required this.sop,
    required this.onOpen,
    required this.onRun,
  });

  final Sop sop;
  final VoidCallback onOpen;
  final VoidCallback onRun;

  @override
  Widget build(BuildContext context) {
    final desc = sop.description.trim().isEmpty ? sop.scene : sop.description;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onOpen,
        child: Ink(
          decoration: _listItemDecoration(),
          padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _TaskCircle(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            sop.pinned ? '置顶 · ${sop.title}' : sop.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _brown,
                              fontSize: 16.5,
                              fontWeight: FontWeight.w700,
                              height: 1.15,
                            ),
                          ),
                        ),
                        if (sop.pinned) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _headerBg,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              '置顶',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: _brown,
                              ),
                            ),
                          ),
                        ],
                        if (sop.fromPlaza) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _headerBg,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              '模板',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: _brown,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(width: 6),
                        _StepBadge(count: sop.steps.length),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      desc,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _softBrown,
                        fontSize: 13,
                        height: 1.32,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              _MetaLine(
                                label: '执行 ${sop.runCount} 次',
                                compact: true,
                              ),
                              _MetaLine(
                                label: '上次 ${_formatLastRun(sop.lastRunAt)}',
                                compact: true,
                              ),
                              if (sop.runProgresses.isNotEmpty)
                                _MetaLine(
                                  label: '暂存 ${_formatRunProgress(sop)}',
                                  compact: true,
                                ),
                              if (sop.reminder != null)
                                _MetaLine(
                                  label: _formatReminder(sop.reminder!),
                                  compact: true,
                                ),
                            ],
                          ),
                        ),
                        _RunButton(onTap: onRun, compact: true),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskCircle extends StatelessWidget {
  const _TaskCircle({this.checked = false, this.size = 24});

  final bool checked;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.only(top: 1),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: checked ? _coral : Colors.transparent,
        border: Border.all(color: checked ? _coral : _line, width: 1.7),
      ),
      child: checked
          ? const Icon(Icons.check_rounded, color: Colors.white, size: 15)
          : null,
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
        color: _headerBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _line),
      ),
      child: Text(
        '步骤 $count',
        style: const TextStyle(
          color: _brown,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          height: 1.1,
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.label, this.compact = false});

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: _softBrown,
        fontSize: compact ? 11.5 : 13,
        fontWeight: FontWeight.w500,
        height: 1.1,
      ),
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
      color: compact ? _headerBg : _coral,
      borderRadius: BorderRadius.circular(compact ? 999 : 14),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(compact ? 12 : 14),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 14,
            vertical: compact ? 5 : 8,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.play_arrow_rounded,
                color: compact ? _coral : Colors.white,
                size: compact ? 16 : 18,
              ),
              const SizedBox(width: 3),
              Text(
                '运行',
                style: TextStyle(
                  color: compact ? _coral : Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: compact ? 12 : 14,
                  height: 1,
                ),
              ),
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
      elevation: 0,
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
              const Text(
                '新建',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailScreen extends StatelessWidget {
  const _DetailScreen({
    super.key,
    required this.sop,
    required this.onBack,
    required this.onRun,
    required this.onEdit,
    required this.onTogglePin,
    required this.onSetReminder,
    required this.onDelete,
  });

  final Sop sop;
  final VoidCallback onBack;
  final VoidCallback onRun;
  final VoidCallback onEdit;
  final VoidCallback onTogglePin;
  final VoidCallback onSetReminder;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: onBack,
        ),
        actions: [
          IconButton(
            icon: Icon(sop.pinned ? Icons.push_pin : Icons.push_pin_outlined),
            onPressed: onTogglePin,
          ),
          IconButton(icon: const Icon(Icons.edit_rounded), onPressed: onEdit),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: onDelete,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Text(
            sop.title,
            style: const TextStyle(
              color: _brown,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              height: 1.08,
            ),
          ),
          const SizedBox(height: 8),
          if (sop.description.trim().isNotEmpty)
            Text(
              sop.description,
              style: const TextStyle(
                color: _softBrown,
                fontSize: 16,
                height: 1.4,
              ),
            )
          else
            Text(
              sop.scene,
              style: const TextStyle(color: _softBrown, fontSize: 16),
            ),
          const SizedBox(height: 20),
          _StatsRow(sop: sop),
          const SizedBox(height: 22),
          _ReminderPanel(sop: sop, onSetReminder: onSetReminder),
          const SizedBox(height: 14),
          ...List.generate(
            sop.steps.length,
            (i) => _StepPreview(index: i, step: sop.steps[i]),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: _PrimaryButton(
          icon: Icons.play_arrow_rounded,
          label: '开始运行',
          onTap: onRun,
        ),
      ),
    );
  }
}

class _ReminderPanel extends StatelessWidget {
  const _ReminderPanel({required this.sop, required this.onSetReminder});

  final Sop sop;
  final VoidCallback onSetReminder;

  @override
  Widget build(BuildContext context) {
    final reminder = sop.reminder;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: _listItemDecoration(),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _sky.withValues(alpha: 0.45),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_available_rounded,
              color: _brown,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '日历提醒',
                  style: TextStyle(
                    color: _brown,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  reminder == null ? '未设置提醒' : _formatReminder(reminder),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _softBrown, fontSize: 12.5),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onSetReminder,
            icon: const Icon(Icons.add_alert_rounded, size: 18),
            label: Text(reminder == null ? '设置' : '修改'),
          ),
        ],
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
        Expanded(
          child: _StatBox(label: '步骤', value: '${sop.steps.length}'),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatBox(label: '检查项', value: '${sop.subStepCount}'),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatBox(label: '完成', value: '${sop.runCount}'),
        ),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _coral.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: _coral,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  step.title,
                  style: const TextStyle(
                    color: _brown,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...step.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 18,
                    color: _softBrown,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(color: _softBrown),
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

class _ReminderSheet extends StatefulWidget {
  const _ReminderSheet({this.initial});

  final SopReminder? initial;

  @override
  State<_ReminderSheet> createState() => _ReminderSheetState();
}

class _ReminderSheetState extends State<_ReminderSheet> {
  late DateTime _date;
  late TimeOfDay _time;
  late SopReminderRepeat _repeat;
  late bool _hasEnd;
  DateTime? _endDate;
  var _alertMinutes = 10;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    final fallback = DateTime.now().add(const Duration(days: 1));
    final start =
        initial?.startsAt ??
        DateTime(fallback.year, fallback.month, fallback.day, 9);
    _date = DateTime(start.year, start.month, start.day);
    _time = TimeOfDay(hour: start.hour, minute: start.minute);
    _repeat = initial?.repeat ?? SopReminderRepeat.none;
    _endDate = initial?.endsAt;
    _hasEnd = _endDate != null;
    _alertMinutes = initial?.alertMinutes ?? 10;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          18,
          20,
          20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '设置日历提醒',
                    style: TextStyle(
                      color: _brown,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _PickerRow(
              icon: Icons.calendar_month_rounded,
              label: '日期',
              value: _formatDate(_date),
              onTap: _pickDate,
            ),
            const SizedBox(height: 8),
            _PickerRow(
              icon: Icons.schedule_rounded,
              label: '时间',
              value:
                  '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
              onTap: _pickTime,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _alertMinutes,
              decoration: _inputDecoration('提前提醒'),
              items: const [
                DropdownMenuItem(value: 0, child: Text('准时提醒')),
                DropdownMenuItem(value: 5, child: Text('提前 5 分钟')),
                DropdownMenuItem(value: 10, child: Text('提前 10 分钟')),
                DropdownMenuItem(value: 30, child: Text('提前 30 分钟')),
                DropdownMenuItem(value: 60, child: Text('提前 1 小时')),
              ],
              onChanged: (value) => setState(() => _alertMinutes = value ?? 10),
            ),
            const SizedBox(height: 12),
            SegmentedButton<SopReminderRepeat>(
              segments: const [
                ButtonSegment(value: SopReminderRepeat.none, label: Text('一次')),
                ButtonSegment(
                  value: SopReminderRepeat.daily,
                  label: Text('每天'),
                ),
                ButtonSegment(
                  value: SopReminderRepeat.weekly,
                  label: Text('每周'),
                ),
                ButtonSegment(
                  value: SopReminderRepeat.monthly,
                  label: Text('每月'),
                ),
              ],
              selected: {_repeat},
              onSelectionChanged: (selected) => setState(() {
                _repeat = selected.first;
                if (_repeat == SopReminderRepeat.none) {
                  _hasEnd = false;
                  _endDate = null;
                }
              }),
            ),
            if (_repeat != SopReminderRepeat.none) ...[
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _hasEnd,
                title: const Text(
                  '设置循环截止日',
                  style: TextStyle(color: _brown, fontWeight: FontWeight.w800),
                ),
                activeThumbColor: _deepMint,
                onChanged: (value) => setState(() {
                  _hasEnd = value;
                  _endDate = value
                      ? (_endDate ?? _date.add(const Duration(days: 30)))
                      : null;
                }),
              ),
              if (_hasEnd)
                _PickerRow(
                  icon: Icons.event_busy_rounded,
                  label: '截止',
                  value: _formatDate(_endDate ?? _date),
                  onTap: _pickEndDate,
                ),
            ],
            const SizedBox(height: 16),
            _PrimaryButton(
              icon: Icons.event_available_rounded,
              label: '加入手机日历',
              onTap: _save,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _date.add(const Duration(days: 30)),
      firstDate: _date,
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  void _save() {
    final startsAt = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );
    Navigator.of(context).pop(
      SopReminder(
        startsAt: startsAt,
        repeat: _repeat,
        endsAt: _hasEnd ? _endDate : null,
        alertMinutes: _alertMinutes,
      ),
    );
  }
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 11, 10, 11),
          decoration: _listItemDecoration(),
          child: Row(
            children: [
              Icon(icon, color: _softBrown, size: 20),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  color: _softBrown,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                value,
                style: const TextStyle(
                  color: _brown,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.chevron_right_rounded, color: _softBrown),
            ],
          ),
        ),
      ),
    );
  }
}

class _SopImprovementSheet extends StatelessWidget {
  const _SopImprovementSheet({
    required this.original,
    required this.improved,
    required this.review,
  });

  final Sop original;
  final Sop improved;
  final String review;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.86,
      minChildSize: 0.55,
      maxChildSize: 0.94,
      builder: (context, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'AI 优化建议',
                    style: TextStyle(
                      color: _brown,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: _listItemDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '你的复盘意见',
                        style: TextStyle(
                          color: _brown,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        review,
                        style: const TextStyle(color: _softBrown, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _ImprovementSummary(original: original, improved: improved),
                const SizedBox(height: 12),
                _MiniSopPreview(sop: improved),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: _SecondaryButton(
                      icon: Icons.close_rounded,
                      label: '暂不接受',
                      onTap: () => Navigator.of(context).pop(false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PrimaryButton(
                      icon: Icons.check_rounded,
                      label: '接受调整',
                      onTap: () => Navigator.of(context).pop(true),
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

class _ImprovementSummary extends StatelessWidget {
  const _ImprovementSummary({required this.original, required this.improved});

  final Sop original;
  final Sop improved;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatBox(label: '原步骤', value: '${original.steps.length}'),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatBox(label: '新步骤', value: '${improved.steps.length}'),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatBox(label: '检查项', value: '${improved.subStepCount}'),
        ),
      ],
    );
  }
}

class _MiniSopPreview extends StatelessWidget {
  const _MiniSopPreview({required this.sop});

  final Sop sop;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(_paper),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sop.title,
            style: const TextStyle(
              color: _brown,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            sop.description.trim().isEmpty ? sop.scene : sop.description,
            style: const TextStyle(color: _softBrown, height: 1.4),
          ),
          const SizedBox(height: 14),
          ...List.generate(
            sop.steps.length,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${index + 1}. ${sop.steps[index].title}',
                    style: const TextStyle(
                      color: _brown,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...sop.steps[index].items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _TaskCircle(size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item,
                              style: const TextStyle(color: _softBrown),
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

class _EditScreen extends StatefulWidget {
  const _EditScreen({
    super.key,
    required this.sop,
    required this.aiConfig,
    required this.onOpenAiConfig,
    required this.onCancel,
    required this.onSave,
  });

  final Sop sop;
  final AiConfig aiConfig;
  final VoidCallback onOpenAiConfig;
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
  final _aiService = AiSopService();
  var _optimizing = false;

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
    _syncDraftFromFields();
    widget.onSave(_draft);
  }

  void _syncDraftFromFields() {
    _draft.title = _title.text.trim().isEmpty ? '未命名 SOP' : _title.text.trim();
    _draft.scene = _scene.text.trim().isEmpty ? '未设置场景' : _scene.text.trim();
    _draft.description = _description.text.trim();
    _draft.steps = _draft.steps
        .where(
          (s) =>
              s.title.trim().isNotEmpty ||
              s.items.any((e) => e.trim().isNotEmpty),
        )
        .toList();
    for (final step in _draft.steps) {
      step.title = step.title.trim().isEmpty ? '未命名步骤' : step.title.trim();
      step.items = step.items
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (step.items.isEmpty) step.items = ['确认完成'];
    }
    if (_draft.steps.isEmpty) {
      _draft.steps = [
        SopStep(title: '第一步', items: ['确认完成']),
      ];
    }
  }

  Future<void> _optimizeWithAi() async {
    final review = await _askOptimizationNeed();
    if (review == null) return;
    final trimmed = review.trim();
    if (trimmed.isEmpty) return;
    _syncDraftFromFields();
    _draft.lastReview = trimmed;
    _draft.lastReviewAt = DateTime.now();
    if (!widget.aiConfig.isConfigured) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('请先完成 AI 模型配置。'),
          action: SnackBarAction(
            label: '去配置',
            onPressed: widget.onOpenAiConfig,
          ),
        ),
      );
      return;
    }
    setState(() => _optimizing = true);
    try {
      final improved = await _aiService.improveSop(
        config: widget.aiConfig,
        sop: _draft,
        review: trimmed,
      );
      if (!mounted) return;
      final accepted = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: _paper,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        builder: (context) => _SopImprovementSheet(
          original: _draft,
          improved: improved,
          review: trimmed,
        ),
      );
      if (accepted != true) return;
      setState(() => _applyImprovedDraft(improved));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已应用 AI 调整，保存后生效。')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('AI 优化失败：$error')));
    } finally {
      if (mounted) setState(() => _optimizing = false);
    }
  }

  Future<String?> _askOptimizationNeed() {
    final controller = TextEditingController(text: _draft.lastReview);
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          18,
          20,
          20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '让 AI 优化 SOP',
              style: TextStyle(
                color: _brown,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '写下你想调整的地方，AI 会生成一版新 SOP，接受后应用到当前编辑草稿。',
              style: TextStyle(color: _softBrown, height: 1.35),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              minLines: 3,
              maxLines: 6,
              decoration: _inputDecoration(
                '修改意见',
              ).copyWith(hintText: '例如：第三步太细，可以合并；发布后要增加检查链接。'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SecondaryButton(
                    icon: Icons.close_rounded,
                    label: '取消',
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _PrimaryButton(
                    icon: Icons.auto_awesome_rounded,
                    label: '生成调整',
                    onTap: () => Navigator.of(context).pop(controller.text),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).whenComplete(controller.dispose);
  }

  void _applyImprovedDraft(Sop improved) {
    _draft.title = improved.title;
    _draft.scene = improved.scene;
    _draft.description = improved.description;
    _draft.steps = improved.steps
        .map((step) => SopStep(title: step.title, items: List.of(step.items)))
        .toList();
    _title.text = _draft.title;
    _scene.text = _draft.scene;
    _description.text = _draft.description;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: widget.onCancel,
        ),
        title: const Text(
          '编辑 SOP',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.check_rounded), onPressed: _save),
        ],
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
          _SecondaryButton(
            icon: Icons.auto_awesome_rounded,
            label: _optimizing ? 'AI 优化中...' : 'AI 优化 SOP',
            onTap: _optimizing ? null : _optimizeWithAi,
          ),
          const SizedBox(height: 18),
          ...List.generate(
            _draft.steps.length,
            (stepIndex) => _EditableStep(
              key: ObjectKey(_draft.steps[stepIndex]),
              step: _draft.steps[stepIndex],
              index: stepIndex,
              onChanged: () => setState(() {}),
              onDelete: () => setState(() => _draft.steps.removeAt(stepIndex)),
            ),
          ),
          const SizedBox(height: 8),
          _SecondaryButton(
            icon: Icons.add_rounded,
            label: '添加步骤',
            onTap: () => setState(
              () => _draft.steps.add(SopStep(title: '新步骤', items: ['新检查项'])),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: _PrimaryButton(
          icon: Icons.save_rounded,
          label: '保存 SOP',
          onTap: _save,
        ),
      ),
    );
  }
}

class _EditableStep extends StatefulWidget {
  const _EditableStep({
    super.key,
    required this.step,
    required this.index,
    required this.onChanged,
    required this.onDelete,
  });

  final SopStep step;
  final int index;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  @override
  State<_EditableStep> createState() => _EditableStepState();
}

class _EditableStepState extends State<_EditableStep> {
  final List<_SubStepDraft> _items = [];

  @override
  void initState() {
    super.initState();
    _resetItems();
  }

  @override
  void didUpdateWidget(covariant _EditableStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.step, widget.step)) {
      _resetItems();
    }
  }

  @override
  void dispose() {
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _resetItems() {
    for (final item in _items) {
      item.dispose();
    }
    _items
      ..clear()
      ..addAll(widget.step.items.map(_SubStepDraft.new));
  }

  void _syncItems() {
    widget.step.items = _items.map((item) => item.controller.text).toList();
    widget.onChanged();
  }

  void _addItem() {
    setState(() => _items.add(_SubStepDraft('')));
    _syncItems();
  }

  void _removeItem(_SubStepDraft item) {
    setState(() {
      _items.remove(item);
      item.dispose();
    });
    _syncItems();
  }

  void _reorderItems(int oldIndex, int newIndex) {
    setState(() {
      final item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
    });
    _syncItems();
  }

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
                  initialValue: widget.step.title,
                  onChanged: (v) => widget.step.title = v,
                  style: const TextStyle(
                    color: _brown,
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: _inputDecoration('步骤 ${widget.index + 1}'),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: _coral),
                onPressed: widget.onDelete,
              ),
            ],
          ),
          const SizedBox(height: 10),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorderItem: _reorderItems,
            itemCount: _items.length,
            itemBuilder: (context, itemIndex) {
              final item = _items[itemIndex];
              return Padding(
                key: ValueKey(item.id),
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ReorderableDelayedDragStartListener(
                      index: itemIndex,
                      child: const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Icon(
                          Icons.drag_indicator_rounded,
                          color: _softBrown,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Icon(
                        Icons.check_box_outline_blank_rounded,
                        color: _deepMint,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: item.controller,
                        onChanged: (_) => _syncItems(),
                        minLines: 1,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        decoration: _inputDecoration('子步骤'),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: _softBrown),
                      onPressed: () => _removeItem(item),
                    ),
                  ],
                ),
              );
            },
          ),
          if (_items.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '还没有子步骤',
                style: TextStyle(color: _softBrown.withValues(alpha: 0.78)),
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _addItem,
              icon: const Icon(Icons.add_rounded),
              label: const Text('添加子步骤'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubStepDraft {
  _SubStepDraft(String text)
    : id = _nextId++,
      controller = TextEditingController(text: text);

  static int _nextId = 0;

  final int id;
  final TextEditingController controller;

  void dispose() => controller.dispose();
}

class _RunScreen extends StatelessWidget {
  const _RunScreen({
    super.key,
    required this.sop,
    required this.index,
    required this.checked,
    required this.onBack,
    required this.onSaveProgress,
    required this.onPrev,
    required this.onNext,
    required this.onToggle,
    required this.onJump,
  });

  final Sop sop;
  final int index;
  final Map<int, Set<int>> checked;
  final VoidCallback onBack;
  final VoidCallback onSaveProgress;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final void Function(int itemIndex, bool value) onToggle;
  final ValueChanged<int> onJump;

  @override
  Widget build(BuildContext context) {
    final steps = sop.steps.isEmpty
        ? [
            SopStep(title: '确认事项', items: ['确认完成']),
          ]
        : sop.steps;
    final safeIndex = index.clamp(0, steps.length - 1).toInt();
    final step = steps[safeIndex];
    final done = checked[safeIndex] ?? {};
    final progress = (safeIndex + 1) / steps.length;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: onBack,
        ),
        title: Text(
          '${safeIndex + 1}/${steps.length}',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_rounded),
            onPressed: () => _showOverview(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              color: _coral,
              backgroundColor: _line,
              minHeight: 7,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            decoration: _cardDecoration(_paper),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _headerBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '第 ${safeIndex + 1} 步 / 共 ${steps.length} 步',
                        style: const TextStyle(
                          color: _softBrown,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${done.length}/${step.items.length}',
                      style: const TextStyle(
                        color: _coral,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  step.title,
                  style: const TextStyle(
                    color: _brown,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  sop.title,
                  style: const TextStyle(
                    color: _softBrown,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: _softBox(_paper),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...List.generate(step.items.length, (i) {
                  final isDone = done.contains(i);
                  return Container(
                    margin: EdgeInsets.only(
                      bottom: i == step.items.length - 1 ? 0 : 8,
                    ),
                    decoration: BoxDecoration(
                      color: isDone ? _mint : _headerBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDone
                            ? _deepMint.withValues(alpha: 0.25)
                            : _line,
                      ),
                    ),
                    child: CheckboxListTile(
                      value: isDone,
                      activeColor: _deepMint,
                      checkboxShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      title: Text(
                        step.items[i],
                        style: TextStyle(
                          color: _brown,
                          fontWeight: isDone
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                      onChanged: (v) => onToggle(i, v ?? false),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SecondaryButton(
                icon: Icons.save_rounded,
                label: '暂存并退出',
                onTap: onSaveProgress,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _SecondaryButton(
                      icon: Icons.chevron_left_rounded,
                      label: '上一步',
                      onTap: safeIndex == 0 ? null : onPrev,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PrimaryButton(
                      icon: safeIndex == steps.length - 1
                          ? Icons.flag_rounded
                          : Icons.chevron_right_rounded,
                      label: safeIndex == steps.length - 1 ? '完成' : '下一步',
                      onTap: onNext,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOverview(BuildContext context) {
    final steps = sop.steps.isEmpty
        ? [
            SopStep(title: '确认事项', items: ['确认完成']),
          ]
        : sop.steps;
    final safeIndex = index.clamp(0, steps.length - 1).toInt();
    showModalBottomSheet(
      context: context,
      backgroundColor: _paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '总览',
              style: TextStyle(
                color: _brown,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: steps.length,
                itemBuilder: (context, i) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: i == safeIndex ? _coral : _headerBg,
                    foregroundColor: i == safeIndex ? Colors.white : _brown,
                    child: Text('${i + 1}'),
                  ),
                  title: Text(
                    steps[i].title,
                    style: const TextStyle(
                      color: _brown,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: Text(
                    '${checked[i]?.length ?? 0}/${steps[i].items.length} 已勾选',
                  ),
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

class _CelebrationDialog extends StatefulWidget {
  const _CelebrationDialog({required this.sopTitle, required this.runCount});

  final String sopTitle;
  final int runCount;

  @override
  State<_CelebrationDialog> createState() => _CelebrationDialogState();
}

class _CelebrationDialogState extends State<_CelebrationDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat();
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
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      final pulse =
                          1 + math.sin(_controller.value * math.pi * 2) * 0.06;
                      return Transform.scale(
                        scale: pulse,
                        child: const _TaskCircle(checked: true, size: 76),
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'SOP 已完成',
                    style: TextStyle(
                      color: _brown,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.sopTitle,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _softBrown,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _mint,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '这是第 ${widget.runCount} 次完成该 SOP',
                      style: const TextStyle(
                        color: _brown,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
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

  static const _colors = [
    _coral,
    _honey,
    _mint,
    _sky,
    Color(0xFFE9A7CF),
    Color(0xFF8CC7A8),
  ];

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
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-4, -9, 8, 18),
            const Radius.circular(3),
          ),
          paint,
        );
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
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
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
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(18),
    borderSide: const BorderSide(color: _line),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(18),
    borderSide: const BorderSide(color: _deepMint, width: 2),
  ),
);

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

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
  const _SecondaryButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

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
          Text(
            value,
            style: const TextStyle(
              color: _brown,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: _softBrown,
              fontWeight: FontWeight.w700,
            ),
          ),
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

BoxDecoration _listItemDecoration() => BoxDecoration(
  color: _paper,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: _line),
);

String _formatLastRun(DateTime? time) {
  if (time == null) return '未执行';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(time.year, time.month, time.day);
  final hm =
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  if (day == today) return '今天 $hm';
  if (day == today.subtract(const Duration(days: 1))) return '昨天 $hm';
  if (now.difference(time).inDays < 7) {
    return '${now.difference(time).inDays} 天前';
  }
  return '${time.month}/${time.day} $hm';
}

String _formatReminder(SopReminder reminder) {
  final start = _formatDateTime(reminder.startsAt);
  final repeat = reminder.repeat == SopReminderRepeat.none
      ? ''
      : ' · ${reminder.repeat.label}';
  final end = reminder.endsAt == null
      ? ''
      : ' · 至 ${_formatDate(reminder.endsAt!)}';
  return '$start$repeat$end';
}

String _formatRunProgress(Sop sop) {
  final progress = sop.runProgress;
  if (progress == null) return '无';
  final prefix = sop.runProgresses.length == 1
      ? ''
      : '${sop.runProgresses.length} 个进行中 · ';
  return '$prefix${progress.checkedCount}/${sop.subStepCount} 项 · ${_formatLastRun(progress.updatedAt)}';
}

String _formatDateTime(DateTime time) {
  final hm =
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  return '${_formatDate(time)} $hm';
}

String _formatDate(DateTime time) => '${time.year}/${time.month}/${time.day}';
