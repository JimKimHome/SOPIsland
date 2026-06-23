import 'package:flutter/material.dart';

import 'app_controller.dart';
import 'models/ai_config.dart';
import 'models/sop.dart';
import 'screens/ai_config_screen.dart';
import 'screens/ai_generate_screen.dart';
import 'screens/home_hub.dart';
import 'screens/settings_screen.dart';
import 'services/backup_file_service.dart';
import 'theme/app_theme.dart';

typedef MySopTabBuilder =
    Widget Function(
      AppController controller,
      String? pendingRunSopId,
      String? pendingRunProgressId,
      VoidCallback onPendingRunHandled,
      VoidCallback onGenerateWithAi,
      VoidCallback onOpenAiConfig,
    );

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.mySopBuilder});

  final MySopTabBuilder mySopBuilder;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final AppController _controller;
  var _tabIndex = 0;
  String? _pendingRunSopId;
  String? _pendingRunProgressId;

  @override
  void initState() {
    super.initState();
    _controller = AppController()..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _switchToMySop({String? runSopId, String? runProgressId}) {
    setState(() {
      _tabIndex = 1;
      _pendingRunSopId = runSopId;
      _pendingRunProgressId = runProgressId;
    });
  }

  void _clearPendingRun() {
    if (_pendingRunSopId != null || _pendingRunProgressId != null) {
      setState(() {
        _pendingRunSopId = null;
        _pendingRunProgressId = null;
      });
    }
  }

  Future<void> _openAiConfig() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AiConfigScreen(
          initialConfig: _controller.aiConfig,
          onSave: _controller.saveAiConfig,
        ),
      ),
    );
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsScreen(
          aiConfigured: _controller.aiConfig.isConfigured,
          onOpenApiSettings: _openAiConfig,
          onImportSop: _importBackup,
          onExportSop: _exportBackup,
        ),
      ),
    );
  }

  Future<AiConfig> _openAiConfigAndReturn() async {
    await _openAiConfig();
    return _controller.aiConfig;
  }

  Future<void> _openAiGenerate() async {
    final sop = await Navigator.of(context).push<Sop>(
      MaterialPageRoute<Sop>(
        builder: (_) => AiGenerateScreen(
          initialConfig: _controller.aiConfig,
          onOpenConfig: _openAiConfigAndReturn,
        ),
      ),
    );
    if (sop == null) return;
    await _controller.addSop(sop);
    _switchToMySop();
  }

  Future<void> _exportBackup() async {
    final fileName = _backupFileName();
    try {
      final saved = await BackupFileService.saveBackup(
        fileName: fileName,
        content: _controller.buildBackupJson(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(saved ? '已导出备份：$fileName' : '已取消导出备份')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('导出失败：$error')));
    }
  }

  Future<void> _importBackup() async {
    try {
      final raw = await BackupFileService.openBackup();
      if (!mounted || raw == null) return;
      final mode = await _askImportMode();
      if (!mounted || mode == null) return;
      final result = await _controller.importBackupJson(raw, mode: mode);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '已导入 ${result.importedCount} 条 SOP，当前共 ${result.totalCount} 条。',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('导入失败：$error')));
    }
  }

  Future<BackupImportMode?> _askImportMode() {
    return showDialog<BackupImportMode>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.paper,
        title: const Text(
          '导入 SOP 备份',
          style: TextStyle(color: AppColors.brown, fontWeight: FontWeight.w900),
        ),
        content: const Text(
          '合并导入会保留当前 SOP，并用备份中的同 ID SOP 更新旧版本；覆盖当前会先清空当前 SOP。',
          style: TextStyle(color: AppColors.softBrown, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, BackupImportMode.replace),
            child: const Text('覆盖当前'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.coral),
            onPressed: () => Navigator.pop(context, BackupImportMode.merge),
            child: const Text('合并导入'),
          ),
        ],
      ),
    );
  }

  String _backupFileName() {
    final now = DateTime.now();
    final stamp =
        '${now.year.toString().padLeft(4, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}-'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}';
    return 'OrSOP-backup-$stamp.orsop.json';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return ColoredBox(
          color: AppColors.cream,
          child: Stack(
            children: [
              const IslandBackdrop(),
              SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    Expanded(
                      child: IndexedStack(
                        index: _tabIndex,
                        children: [
                          HomeHubScreen(
                            controller: _controller,
                            onOpenMySop: () => _switchToMySop(),
                            onRunSop: (id, progressId) => _switchToMySop(
                              runSopId: id,
                              runProgressId: progressId,
                            ),
                            onGenerateWithAi: _openAiGenerate,
                            onOpenSettings: _openSettings,
                          ),
                          widget.mySopBuilder(
                            _controller,
                            _pendingRunSopId,
                            _pendingRunProgressId,
                            _clearPendingRun,
                            _openAiGenerate,
                            _openSettings,
                          ),
                        ],
                      ),
                    ),
                    _BottomTabBar(
                      index: _tabIndex,
                      onChanged: (i) => setState(() => _tabIndex = i),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BottomTabBar extends StatelessWidget {
  const _BottomTabBar({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper.withValues(alpha: 0.96),
        border: Border(
          top: BorderSide(color: AppColors.line.withValues(alpha: 0.9)),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A101828),
            blurRadius: 18,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
          child: Row(
            children: [
              _TabItem(
                icon: Icons.home_rounded,
                label: '首页',
                selected: index == 0,
                onTap: () => onChanged(0),
              ),
              _TabItem(
                icon: Icons.checklist_rounded,
                label: '我的 SOP',
                selected: index == 1,
                onTap: () => onChanged(1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.coral : AppColors.softBrown;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 42,
                  height: 30,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.coral.withValues(alpha: 0.10)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
