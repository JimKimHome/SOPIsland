import 'dart:async';

import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../data/content.dart';
import '../models/sop.dart';
import '../theme/app_theme.dart';
import 'efficiency_screen.dart';
import 'learn_screen.dart';
import 'plaza_screen.dart';

const _homeHubHero = 'assets/images/home_hub/hero_island_hub.png';
const _hubTilePlaza = 'assets/images/home_hub/tile_plaza.png';
const _hubTileLearn = 'assets/images/home_hub/tile_learn.png';
const _hubTileMySop = 'assets/images/home_hub/tile_my_sop.png';
const _hubTileEfficiency = 'assets/images/home_hub/tile_efficiency.png';
const _featuredImages = [
  'assets/images/home_hub/featured_meeting.png',
  'assets/images/home_hub/featured_content.png',
  'assets/images/home_hub/featured_support.png',
];

class HomeHubScreen extends StatelessWidget {
  const HomeHubScreen({
    super.key,
    required this.controller,
    required this.onOpenMySop,
    this.onRunSop,
  });

  final AppController controller;
  final VoidCallback onOpenMySop;
  final void Function(String sopId)? onRunSop;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 88),
      children: [
        const Text(
          'SOP Island',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.brown),
        ),
        const SizedBox(height: 4),
        const Text(
          '把重复性工作变成可执行的清单',
          style: TextStyle(fontSize: 14, color: AppColors.softBrown, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        const _AnnouncementCarousel(),
        const SizedBox(height: 18),
        _HubGrid(
          onPlaza: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PlazaScreen(controller: controller))),
          onLearn: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const LearnScreen())),
          onMySop: onOpenMySop,
          onEfficiency: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => EfficiencyScreen(controller: controller))),
        ),
        const SizedBox(height: 24),
        if (!controller.loading && controller.sops.isNotEmpty) ...[
          _TodaySection(
            suggestions: controller.todaySuggestions(),
            onRun: onRunSop,
            onOpenMySop: onOpenMySop,
          ),
          const SizedBox(height: 24),
        ],
        _FeaturedPlaza(
          onOpenPlaza: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PlazaScreen(controller: controller))),
          onOpenTemplate: (id) => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => PlazaScreen(controller: controller, initialTemplateId: id)),
          ),
        ),
      ],
    );
  }
}

const _announcements = [
  _Announcement(
    title: '新手指引',
    subtitle: '第一次来小岛？先用 3 分钟熟悉常用入口。',
    badge: '入门',
    tint: AppColors.mint,
    sections: [
      _GuideSection(
        title: '你可以先做这 4 件事',
        items: [
          '进「SOP 广场」挑一个接近你场景的模板。',
          '把模板添加到「我的 SOP」，改成自己的流程。',
          '在「我的 SOP」里点「运行」，按步骤勾选完成。',
          '回到首页看「今日建议」，快速继续常用流程。',
        ],
      ),
      _GuideSection(
        title: '常用入口',
        items: [
          'SOP 广场：找模板和灵感，适合不知道从哪里开始时使用。',
          'SOP 学习：学习 SOP 的概念、写法和经典书籍知识点。',
          '我的 SOP：管理自己的流程，创建、编辑、运行都在这里。',
          '效率咨询：查看时间管理、批处理、5S 等效率方法。',
        ],
      ),
      _GuideSection(
        title: '建议的第一条 SOP',
        items: [
          '选一个每周至少重复 2 次的任务。',
          '拆成 2-4 个阶段，每个阶段 2-4 个检查项。',
          '先跑 3 次，再决定哪些步骤要删、合并或补充。',
        ],
      ),
    ],
  ),
  _Announcement(
    title: '使用手册',
    subtitle: '完整了解创建、执行、学习和优化 SOP 的方式。',
    badge: '指南',
    tint: AppColors.sky,
    sections: [
      _GuideSection(
        title: '首页 HomeHub',
        items: [
          '顶部公告提供新手指引和使用手册入口。',
          '四个功能入口分别是 SOP 广场、SOP 学习、我的 SOP、效率咨询。',
          '今日建议会根据已有 SOP 推荐可继续运行的流程。',
          '广场精选会展示适合快速添加的模板。',
        ],
      ),
      _GuideSection(
        title: 'SOP 广场',
        items: [
          '按个人效率、门店运营、工厂产线、团队协作筛选模板。',
          '点开模板可查看场景、说明、使用人数和步骤预览。',
          '点击「添加到我的 SOP」后，可以继续编辑成自己的版本。',
        ],
      ),
      _GuideSection(
        title: '我的 SOP',
        items: [
          '管理所有已创建或从广场添加的流程。',
          '每张 SOP 卡片会展示步骤数、执行次数和上次执行时间。',
          '可以新建、编辑、删除，也可以直接点击「运行」。',
          '编辑时建议每个步骤标题简短，检查项用动词开头。',
        ],
      ),
      _GuideSection(
        title: '运行模式',
        items: [
          '运行时按阶段推进，每个检查项都可以勾选。',
          '可通过总览跳转到任意阶段。',
          '最后一步完成后会记录执行次数，帮助你看到持续执行的反馈。',
        ],
      ),
      _GuideSection(
        title: '学习与优化',
        items: [
          'SOP 学习里包含入门文章和经典书籍知识点。',
          '效率咨询提供番茄工作法、两分钟法则、批处理、5S 等方法。',
          '当流程反复卡住时，优先检查步骤是否太多、责任是否不清、触发时机是否明确。',
          '建议每执行 3-5 次后复盘一次，删除多余步骤，补上容易遗漏的检查点。',
        ],
      ),
    ],
  ),
];

class _AnnouncementCarousel extends StatefulWidget {
  const _AnnouncementCarousel();

  @override
  State<_AnnouncementCarousel> createState() => _AnnouncementCarouselState();
}

class _AnnouncementCarouselState extends State<_AnnouncementCarousel> {
  late final PageController _controller;
  Timer? _timer;
  var _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      final next = (_index + 1) % _announcements.length;
      _controller.animateToPage(next, duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 154,
          child: PageView.builder(
            controller: _controller,
            itemCount: _announcements.length,
            onPageChanged: (index) => setState(() => _index = index),
            itemBuilder: (context, index) => _AnnouncementCard(
              announcement: _announcements[index],
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => _GuideDetailScreen(announcement: _announcements[index])),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _announcements.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: i == _index ? 18 : 7,
              height: 7,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: i == _index ? AppColors.deepMint : AppColors.line,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.announcement, required this.onTap});

  final _Announcement announcement;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            decoration: cardDecoration(AppColors.paper),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      _homeHubHero,
                      fit: BoxFit.cover,
                      alignment: Alignment.centerRight,
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            AppColors.paper.withValues(alpha: 0.98),
                            announcement.tint.withValues(alpha: 0.62),
                            AppColors.paper.withValues(alpha: 0.12),
                            AppColors.paper.withValues(alpha: 0.0),
                          ],
                          stops: const [0.0, 0.42, 0.74, 1.0],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(color: AppColors.paper.withValues(alpha: 0.86), borderRadius: BorderRadius.circular(999)),
                          child: Text(announcement.badge, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.brown)),
                        ),
                        const SizedBox(height: 8),
                        Text(announcement.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.brown)),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: 206,
                          child: Text(
                            announcement.subtitle,
                            style: const TextStyle(fontSize: 13, height: 1.35, color: AppColors.softBrown, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 14,
                    bottom: 12,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(color: AppColors.paper.withValues(alpha: 0.88), shape: BoxShape.circle, border: Border.all(color: AppColors.line)),
                      child: const Icon(Icons.chevron_right_rounded, color: AppColors.brown, size: 24),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GuideDetailScreen extends StatelessWidget {
  const _GuideDetailScreen({required this.announcement});

  final _Announcement announcement;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: Text(announcement.title, style: const TextStyle(fontWeight: FontWeight.w900))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          AssetBlendCard(
            image: _homeHubHero,
            title: announcement.title,
            subtitle: announcement.subtitle,
            tint: announcement.tint,
            height: 160,
            titleSize: 22,
            subtitleWidth: 230,
          ),
          const SizedBox(height: 18),
          ...announcement.sections.map((section) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  decoration: cardDecoration(AppColors.paper),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(section.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.brown)),
                      const SizedBox(height: 10),
                      ...section.items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 7),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ', style: TextStyle(color: AppColors.deepMint, fontWeight: FontWeight.w900)),
                              Expanded(child: Text(item, style: const TextStyle(color: AppColors.softBrown, height: 1.45, fontWeight: FontWeight.w600))),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

class _Announcement {
  const _Announcement({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.tint,
    required this.sections,
  });

  final String title;
  final String subtitle;
  final String badge;
  final Color tint;
  final List<_GuideSection> sections;
}

class _GuideSection {
  const _GuideSection({required this.title, required this.items});

  final String title;
  final List<String> items;
}

class _HubGrid extends StatelessWidget {
  const _HubGrid({
    required this.onPlaza,
    required this.onLearn,
    required this.onMySop,
    required this.onEfficiency,
  });

  final VoidCallback onPlaza;
  final VoidCallback onLearn;
  final VoidCallback onMySop;
  final VoidCallback onEfficiency;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.02,
      children: [
        _HubTile(tint: AppColors.sky, image: _hubTilePlaza, title: 'SOP 广场', subtitle: '模板与灵感', onTap: onPlaza),
        _HubTile(tint: AppColors.mint, image: _hubTileLearn, title: 'SOP 学习', subtitle: '入门与技巧', onTap: onLearn),
        _HubTile(tint: AppColors.honey, image: _hubTileMySop, title: '我的 SOP', subtitle: '创建与执行', onTap: onMySop),
        _HubTile(tint: const Color(0xFFFFC4B8), image: _hubTileEfficiency, title: '效率咨询', subtitle: '效率方法库', onTap: onEfficiency),
      ],
    );
  }
}

class _HubTile extends StatelessWidget {
  const _HubTile({
    required this.tint,
    required this.image,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Color tint;
  final String image;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: cardDecoration(AppColors.paper),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  image,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                      colors: [
                        AppColors.paper.withValues(alpha: 0.98),
                        tint.withValues(alpha: 0.66),
                        AppColors.paper.withValues(alpha: 0.12),
                        AppColors.paper.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.32, 0.66, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        AppColors.paper.withValues(alpha: 0.52),
                        AppColors.paper.withValues(alpha: 0.08),
                        AppColors.paper.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 112),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.brown)),
                        const SizedBox(height: 3),
                        Text(subtitle, style: const TextStyle(fontSize: 12, height: 1.2, color: AppColors.softBrown, fontWeight: FontWeight.w700)),
                      ],
                    ),
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

class _TodaySection extends StatelessWidget {
  const _TodaySection({
    required this.suggestions,
    required this.onRun,
    required this.onOpenMySop,
  });

  final List<Sop> suggestions;
  final void Function(String sopId)? onRun;
  final VoidCallback onOpenMySop;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('今日建议', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.brown)),
            ),
            TextButton(onPressed: onOpenMySop, child: const Text('全部')),
          ],
        ),
        const SizedBox(height: 8),
        ...suggestions.map((sop) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onRun != null ? () => onRun!(sop.id) : null,
                  borderRadius: BorderRadius.circular(16),
                  child: Ink(
                    decoration: cardDecoration(AppColors.paper),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        SopIllustration(variant: sop.illustration, size: 48),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(sop.title, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.brown)),
                              Text(
                                '上次 ${formatLastRun(sop.lastRunAt)} · ${sop.subStepCount} 步',
                                style: const TextStyle(fontSize: 12, color: AppColors.softBrown),
                              ),
                            ],
                          ),
                        ),
                        if (onRun != null)
                          FilledButton(
                            onPressed: () => onRun!(sop.id),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.deepMint,
                              minimumSize: const Size(56, 36),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            child: const Text('运行', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            )),
      ],
    );
  }
}

class _FeaturedPlaza extends StatelessWidget {
  const _FeaturedPlaza({required this.onOpenPlaza, required this.onOpenTemplate});

  final VoidCallback onOpenPlaza;
  final void Function(String id) onOpenTemplate;

  @override
  Widget build(BuildContext context) {
    final featured = plazaTemplates.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('广场精选', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.brown)),
            ),
            TextButton(onPressed: onOpenPlaza, child: const Text('更多')),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 148,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: featured.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final t = featured[i];
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onOpenTemplate(t.id),
                  borderRadius: BorderRadius.circular(18),
                  child: Ink(
                    width: 220,
                    decoration: cardDecoration(AppColors.paper),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.asset(
                            _featuredImages[i % _featuredImages.length],
                            fit: BoxFit.cover,
                            alignment: Alignment.centerRight,
                          ),
                        ),
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  AppColors.paper.withValues(alpha: 0.98),
                                  [AppColors.sky, AppColors.mint, AppColors.honey][i % 3].withValues(alpha: 0.58),
                                  AppColors.paper.withValues(alpha: 0.12),
                                  AppColors.paper.withValues(alpha: 0.0),
                                ],
                                stops: const [0.0, 0.42, 0.74, 1.0],
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomLeft,
                                end: Alignment.topRight,
                                colors: [
                                  AppColors.paper.withValues(alpha: 0.58),
                                  AppColors.paper.withValues(alpha: 0.16),
                                  AppColors.paper.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.category, style: const TextStyle(fontSize: 11, color: AppColors.softBrown, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              SizedBox(
                                width: 128,
                                child: Text(
                                  t.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.brown),
                                ),
                              ),
                              const Spacer(),
                              Text('${t.useCount} 人使用', style: const TextStyle(fontSize: 11, color: AppColors.softBrown)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
