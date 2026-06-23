import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.aiConfigured,
    required this.onOpenApiSettings,
    required this.onImportSop,
    required this.onExportSop,
  });

  final bool aiConfigured;
  final VoidCallback onOpenApiSettings;
  final VoidCallback onImportSop;
  final VoidCallback onExportSop;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('设置', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _SettingsItem(
            icon: Icons.tune_rounded,
            title: 'API设置',
            subtitle: aiConfigured ? '已配置模型服务' : '未配置模型服务',
            onTap: onOpenApiSettings,
          ),
          const SizedBox(height: 10),
          _SettingsItem(
            icon: Icons.file_download_rounded,
            title: '导入SOP',
            subtitle: '从 .orsop.json 备份恢复 SOP',
            onTap: onImportSop,
          ),
          const SizedBox(height: 10),
          _SettingsItem(
            icon: Icons.file_upload_rounded,
            title: '导出SOP',
            subtitle: '保存当前 SOP 为 .orsop.json 备份',
            onTap: onExportSop,
          ),
        ],
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.coral.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.coral, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.brown,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.softBrown,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.softBrown,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
