import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../models/sop.dart';
import '../theme/app_theme.dart';
import '../utils/date_format.dart';

class HomeHubScreen extends StatelessWidget {
  const HomeHubScreen({
    super.key,
    required this.controller,
    required this.onOpenMySop,
    required this.onRunSop,
    required this.onGenerateWithAi,
    required this.onOpenSettings,
  });

  final AppController controller;
  final VoidCallback onOpenMySop;
  final void Function(String sopId, String? runProgressId) onRunSop;
  final VoidCallback onGenerateWithAi;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final inProgress = [
      for (final sop in controller.sops)
        for (var i = 0; i < sop.runProgresses.length; i++)
          _InProgressRun(
            sop: sop,
            progress: sop.runProgresses[i],
            instanceNumber: i + 1,
          ),
    ]..sort((a, b) => b.progress.updatedAt.compareTo(a.progress.updatedAt));
    final suggestions = controller
        .todaySuggestions(limit: 6)
        .where((sop) => sop.runProgresses.isEmpty)
        .take(3)
        .toList();
    final recent = List<Sop>.from(controller.sops)
      ..removeWhere(
        (sop) => sop.lastRunAt == null || sop.runProgresses.isNotEmpty,
      )
      ..sort((a, b) {
        final aTime = a.lastRunAt?.millisecondsSinceEpoch ?? 0;
        final bTime = b.lastRunAt?.millisecondsSinceEpoch ?? 0;
        return bTime.compareTo(aTime);
      });
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 88),
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '今日执行',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppColors.brown,
                      height: 1.05,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '只看现在值得做的流程。',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.softBrown,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              onPressed: onOpenSettings,
              icon: const Icon(Icons.tune_rounded),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _AiQuickAction(
          configured: controller.aiConfig.isConfigured,
          onGenerate: onGenerateWithAi,
          onConfig: onOpenSettings,
        ),
        const SizedBox(height: 18),
        if (inProgress.isNotEmpty) ...[
          _SectionHeader(title: '未完成', action: '流程库', onTap: onOpenMySop),
          const SizedBox(height: 8),
          ...inProgress.map(
            (run) => _SopRow(
              title: _runTitle(run),
              meta: _runMeta(run),
              onTap: () => onRunSop(run.sop.id, run.progress.id),
              leadingText: '#${run.instanceNumber}',
              trailing: const Text(
                '继续',
                style: TextStyle(
                  color: AppColors.coral,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
        _SectionHeader(title: '今日建议', action: '流程库', onTap: onOpenMySop),
        const SizedBox(height: 8),
        if (suggestions.isEmpty)
          const _EmptyBlock(text: '还没有今日建议。可以先用 AI 生成一条流程。')
        else
          ...suggestions.map(
            (sop) => _SopRow(
              title: sop.title,
              meta: _sopMeta(sop),
              onTap: () => onRunSop(sop.id, null),
              trailing: const Icon(
                Icons.play_arrow_rounded,
                color: AppColors.coral,
              ),
            ),
          ),
        const SizedBox(height: 24),
        _SectionHeader(title: '最近执行', action: '流程库', onTap: onOpenMySop),
        const SizedBox(height: 8),
        if (recent.isEmpty)
          const _EmptyBlock(text: '完成一次 SOP 后，这里会显示最近运行。')
        else
          ...recent
              .take(3)
              .map(
                (sop) => _SopRow(
                  title: sop.title,
                  meta: _sopMeta(sop),
                  onTap: () => onRunSop(sop.id, null),
                  trailing: Text(
                    formatLastRun(sop.lastRunAt),
                    style: const TextStyle(
                      color: AppColors.softBrown,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
      ],
    );
  }
}

class _AiQuickAction extends StatelessWidget {
  const _AiQuickAction({
    required this.configured,
    required this.onGenerate,
    required this.onConfig,
  });

  final bool configured;
  final VoidCallback onGenerate;
  final VoidCallback onConfig;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onGenerate,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.coral.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.coral,
                    size: 17,
                  ),
                ),
                const SizedBox(width: 11),
                const Expanded(
                  child: Text(
                    'AI 生成 SOP',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.brown,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: configured
                        ? AppColors.mint.withValues(alpha: 0.78)
                        : AppColors.cream,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    configured ? '已配置' : '未配置',
                    style: TextStyle(
                      color: configured
                          ? AppColors.deepMint
                          : AppColors.softBrown,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'AI 配置',
                  onPressed: onConfig,
                  icon: const Icon(Icons.tune_rounded),
                  color: AppColors.softBrown,
                  iconSize: 20,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.action,
    required this.onTap,
  });

  final String title;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.brown,
            ),
          ),
        ),
        TextButton(onPressed: onTap, child: Text(action)),
      ],
    );
  }
}

class _SopRow extends StatelessWidget {
  const _SopRow({
    required this.title,
    required this.meta,
    required this.onTap,
    required this.trailing,
    this.leadingText,
  });

  final String title;
  final String meta;
  final VoidCallback onTap;
  final Widget trailing;
  final String? leadingText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.line, width: 1.7),
                  ),
                  child: leadingText == null
                      ? null
                      : Text(
                          leadingText!,
                          style: const TextStyle(
                            color: AppColors.coral,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.brown,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        meta,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.softBrown,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InProgressRun {
  const _InProgressRun({
    required this.sop,
    required this.progress,
    required this.instanceNumber,
  });

  final Sop sop;
  final SopRunProgress progress;
  final int instanceNumber;
}

String _runMeta(_InProgressRun run) {
  final progress = run.progress;
  return '${run.sop.title} · 开始 ${formatLastRun(progress.createdAt)} · 已完成 ${progress.checkedCount}/${run.sop.subStepCount} 项 · 暂存 ${formatLastRun(progress.updatedAt)}';
}

String _runTitle(_InProgressRun run) {
  final name = run.progress.name.trim();
  if (name.isNotEmpty) return name;
  return '实例 #${run.instanceNumber}';
}

String _sopMeta(Sop sop) {
  final progress = sop.runProgress;
  if (progress == null) {
    return '${sop.steps.length} 步 · ${sop.subStepCount} 项 · 执行 ${sop.runCount} 次';
  }
  final prefix = sop.runProgresses.length == 1
      ? '进行中'
      : '${sop.runProgresses.length} 个进行中';
  return '$prefix · 已完成 ${progress.checkedCount}/${sop.subStepCount} 项 · 暂存 ${formatLastRun(progress.updatedAt)}';
}

class _EmptyBlock extends StatelessWidget {
  const _EmptyBlock({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Text(
        text,
        style: const TextStyle(color: AppColors.softBrown, height: 1.4),
      ),
    );
  }
}
