import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../data/content.dart';
import '../models/sop.dart';
import '../theme/app_theme.dart';

const _plazaHero = 'assets/images/plaza/hero_plaza.png';
const _plazaCategoryPersonal = 'assets/images/plaza/category_personal.png';
const _plazaCategoryStore = 'assets/images/plaza/category_store.png';
const _plazaCategoryFactory = 'assets/images/plaza/category_factory.png';
const _plazaCategoryTeam = 'assets/images/plaza/category_team.png';

String _plazaCategoryImage(String category) => switch (category) {
      '门店运营' => _plazaCategoryStore,
      '工厂产线' => _plazaCategoryFactory,
      '团队协作' => _plazaCategoryTeam,
      _ => _plazaCategoryPersonal,
    };

class PlazaScreen extends StatefulWidget {
  const PlazaScreen({super.key, required this.controller, this.initialTemplateId});

  final AppController controller;
  final String? initialTemplateId;

  @override
  State<PlazaScreen> createState() => _PlazaScreenState();
}

class _PlazaScreenState extends State<PlazaScreen> {
  var _category = '全部';

  @override
  void initState() {
    super.initState();
    if (widget.initialTemplateId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openTemplate(widget.initialTemplateId!));
    }
  }

  List<SopTemplate> get _filtered {
    if (_category == '全部') return plazaTemplates;
    return plazaTemplates.where((t) => t.category == _category).toList();
  }

  void _openTemplate(String id) {
    final template = findPlazaTemplate(id);
    if (template == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => PlazaDetailScreen(controller: widget.controller, template: template)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('SOP 广场', style: TextStyle(fontWeight: FontWeight.w900))),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: AssetBlendCard(
              image: _plazaHero,
              title: '发现可复用流程',
              subtitle: '从模板开始，把常做的事整理成可执行清单。',
              tint: AppColors.sky,
              height: 140,
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: plazaCategories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final cat = plazaCategories[i];
                final selected = cat == _category;
                return FilterChip(
                  label: Text(cat),
                  selected: selected,
                  onSelected: (_) => setState(() => _category = cat),
                  selectedColor: AppColors.mint,
                  checkmarkColor: AppColors.brown,
                  labelStyle: TextStyle(
                    color: AppColors.brown,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: _filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final t = _filtered[i];
                final added = widget.controller.hasTemplate(t.id);
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _openTemplate(t.id),
                    borderRadius: BorderRadius.circular(20),
                    child: Ink(
                      decoration: cardDecoration(AppColors.paper),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          _TemplateThumb(image: _plazaCategoryImage(t.category)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(t.title, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.brown, fontSize: 16)),
                                    ),
                                    if (added)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.mint.withValues(alpha: 0.6),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text('已添加', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.brown)),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(t.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.softBrown)),
                                const SizedBox(height: 6),
                                Text('${t.category} · ${t.steps.length} 阶段 · ${t.useCount} 人使用', style: const TextStyle(fontSize: 11, color: AppColors.softBrown)),
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
      ),
    );
  }
}

class PlazaDetailScreen extends StatelessWidget {
  const PlazaDetailScreen({super.key, required this.controller, required this.template});

  final AppController controller;
  final SopTemplate template;

  @override
  Widget build(BuildContext context) {
    final added = controller.hasTemplate(template.id);
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: Text(template.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        children: [
          AssetBlendCard(
            image: _plazaCategoryImage(template.category),
            title: template.title,
            subtitle: template.scene,
            tint: AppColors.sky,
            height: 158,
            titleSize: 21,
          ),
          const SizedBox(height: 16),
          Text(template.scene, style: const TextStyle(color: AppColors.softBrown, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(template.description, style: const TextStyle(color: AppColors.brown, height: 1.5)),
          const SizedBox(height: 8),
          Text('${template.category} · ${template.useCount} 人使用', style: const TextStyle(fontSize: 12, color: AppColors.softBrown)),
          const SizedBox(height: 20),
          const Text('步骤预览', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.brown)),
          const SizedBox(height: 10),
          ...template.steps.map((step) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  decoration: cardDecoration(AppColors.paper),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(step.title, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.brown)),
                      const SizedBox(height: 6),
                      ...step.items.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• ', style: TextStyle(color: AppColors.deepMint, fontWeight: FontWeight.w900)),
                                Expanded(child: Text(item, style: const TextStyle(color: AppColors.softBrown))),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              )),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: FilledButton.icon(
            onPressed: added
                ? null
                : () async {
                    await controller.addFromTemplate(template);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('已添加「${template.title}」到我的 SOP'),
                        backgroundColor: AppColors.deepMint,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    Navigator.of(context).pop();
                  },
            icon: Icon(added ? Icons.check_rounded : Icons.add_rounded),
            label: Text(added ? '已在「我的 SOP」中' : '添加到我的 SOP'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.coral,
              disabledBackgroundColor: AppColors.mint,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
          ),
        ),
      ),
    );
  }
}

class _TemplateThumb extends StatelessWidget {
  const _TemplateThumb({required this.image});

  final String image;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(image, fit: BoxFit.cover),
      ),
    );
  }
}
