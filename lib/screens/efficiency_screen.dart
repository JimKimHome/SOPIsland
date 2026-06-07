import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../data/content.dart';
import '../models/sop.dart';
import '../theme/app_theme.dart';

const _efficiencyHero = 'assets/images/efficiency/hero_efficiency.png';

String _efficiencyPostImage(String id) => switch (id) {
      'eff-two-minute' => 'assets/images/efficiency/posts/eff_two_minute.png',
      'eff-batch' => 'assets/images/efficiency/posts/eff_batch.png',
      'eff-5s' => 'assets/images/efficiency/posts/eff_5s.png',
      'eff-checklist-manifesto' => 'assets/images/efficiency/posts/eff_checklist_manifesto.png',
      'eff-energy' => 'assets/images/efficiency/posts/eff_energy.png',
      _ => 'assets/images/efficiency/posts/eff_pomodoro.png',
    };

class EfficiencyScreen extends StatelessWidget {
  const EfficiencyScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('效率咨询', style: TextStyle(fontWeight: FontWeight.w900))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const AssetBlendCard(
            image: _efficiencyHero,
            title: '让流程更省力',
            subtitle: '用方法和执行记录，找到最适合你的工作节奏。',
            tint: AppColors.sky,
            height: 142,
          ),
          const SizedBox(height: 16),
          if (!controller.loading && controller.sops.isNotEmpty) ...[
            _StatsOverview(controller: controller),
            const SizedBox(height: 16),
          ],
          const Text('效率方法', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.brown)),
          const SizedBox(height: 4),
          const Text('精选效率提升文章，暂不提供 AI 问答', style: TextStyle(fontSize: 12, color: AppColors.softBrown)),
          const SizedBox(height: 12),
          ...efficiencyPosts.map((post) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => EfficiencyDetailScreen(post: post)),
                    ),
                    borderRadius: BorderRadius.circular(20),
                    child: Ink(
                      decoration: cardDecoration(AppColors.paper),
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(post.category, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.deepMint)),
                                const SizedBox(height: 6),
                                Text(post.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.brown)),
                                const SizedBox(height: 6),
                                Text(post.summary, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.softBrown, height: 1.4)),
                                const SizedBox(height: 8),
                                Text('${post.readMinutes} 分钟阅读', style: const TextStyle(fontSize: 11, color: AppColors.softBrown)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          _PostThumb(image: _efficiencyPostImage(post.id)),
                        ],
                      ),
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

class _PostThumb extends StatelessWidget {
  const _PostThumb({required this.image});

  final String image;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      height: 92,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.asset(image, fit: BoxFit.cover),
      ),
    );
  }
}

class _StatsOverview extends StatelessWidget {
  const _StatsOverview({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final most = controller.mostUsed;
    return Container(
      decoration: cardDecoration(AppColors.sky.withValues(alpha: 0.5)),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('我的执行概览', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.brown)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _StatItem(label: 'SOP 数量', value: '${controller.sops.length}')),
              Expanded(child: _StatItem(label: '累计执行', value: '${controller.totalRuns}')),
            ],
          ),
          if (most != null) ...[
            const SizedBox(height: 10),
            Text(
              '最常用：${most.title}（${most.runCount} 次）',
              style: const TextStyle(fontSize: 12, color: AppColors.softBrown, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.brown)),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.softBrown)),
      ],
    );
  }
}

class EfficiencyDetailScreen extends StatelessWidget {
  const EfficiencyDetailScreen({super.key, required this.post});

  final EfficiencyPost post;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: Text(post.category, style: const TextStyle(fontWeight: FontWeight.w900))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          AssetBlendCard(
            image: _efficiencyHero,
            title: post.title,
            subtitle: '${post.category} · 约 ${post.readMinutes} 分钟阅读',
            tint: AppColors.sky,
            height: 164,
            titleSize: 20,
            subtitleWidth: 240,
          ),
          const SizedBox(height: 20),
          Text(post.body, style: const TextStyle(color: AppColors.brown, height: 1.7, fontSize: 15)),
        ],
      ),
    );
  }
}
