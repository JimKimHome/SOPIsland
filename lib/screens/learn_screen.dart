import 'package:flutter/material.dart';

import '../data/content.dart';
import '../models/sop.dart';
import '../theme/app_theme.dart';

const _learnHero = 'assets/images/learn/hero_learn.png';

String _learnPostImage(String id) {
  if (id == 'learn-how-to-create' || id == 'book-business-process-improvement' || id == 'book-lean-six-sigma-toolbook') {
    return 'assets/images/learn/posts/learn_how_to_create.png';
  }
  if (id == 'learn-stick-to-it' || id == 'book-toyota-way' || id == 'book-out-of-the-crisis') {
    return 'assets/images/learn/posts/learn_stick_to_it.png';
  }
  if (id == 'learn-team-factory' || id == 'book-traction' || id == 'book-bpm-profiting-from-process') {
    return 'assets/images/learn/posts/learn_team_factory.png';
  }
  return 'assets/images/learn/posts/learn_what_is_sop.png';
}

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('SOP 学习', style: TextStyle(fontWeight: FontWeight.w900))),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: learnArticles.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          if (i == 0) {
            return const AssetBlendCard(
              image: _learnHero,
              title: '学习 SOP 方法',
              subtitle: '从入门到实操，把流程写成真正能跑起来的清单。',
              tint: AppColors.mint,
              height: 142,
            );
          }
          final article = learnArticles[i - 1];
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => LearnDetailScreen(article: article)),
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
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(8)),
                                child: Text(article.tag, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.brown)),
                              ),
                              const Spacer(),
                              Text('${article.readMinutes} 分钟', style: const TextStyle(fontSize: 11, color: AppColors.softBrown)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(article.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.brown)),
                          const SizedBox(height: 6),
                          Text(article.summary, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.softBrown, height: 1.4)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _PostThumb(image: _learnPostImage(article.id)),
                  ],
                ),
              ),
            ),
          );
        },
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

class LearnDetailScreen extends StatelessWidget {
  const LearnDetailScreen({super.key, required this.article});

  final LearnArticle article;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: Text(article.tag, style: const TextStyle(fontWeight: FontWeight.w900))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          AssetBlendCard(
            image: _learnHero,
            title: article.title,
            subtitle: '约 ${article.readMinutes} 分钟阅读',
            tint: AppColors.mint,
            height: 164,
            titleSize: 20,
            subtitleWidth: 230,
          ),
          const SizedBox(height: 20),
          Text(article.body, style: const TextStyle(color: AppColors.brown, height: 1.7, fontSize: 15)),
        ],
      ),
    );
  }
}
