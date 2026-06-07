import 'dart:math' as math;

import 'package:flutter/material.dart';

abstract final class AppColors {
  static const cream = Color(0xFFFFF4D8);
  static const paper = Color(0xFFFFFBEE);
  static const mint = Color(0xFFAADFC0);
  static const deepMint = Color(0xFF4F9E79);
  static const sky = Color(0xFFBFE5F5);
  static const coral = Color(0xFFF37E67);
  static const honey = Color(0xFFFFD76D);
  static const brown = Color(0xFF453528);
  static const softBrown = Color(0xFF806B58);
  static const line = Color(0xFFEEDCB7);
  static const headerBg = Color(0xFFF5EED8);
  static const cardBorder = Color(0xFFD8C7A8);
}

const cardArtSize = 86.0;

ThemeData buildAppTheme() => ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.cream,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.deepMint, brightness: Brightness.light),
      fontFamily: 'sans',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: AppColors.brown,
      ),
    );

BoxDecoration softBox(Color color) => BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: Colors.white.withValues(alpha: 0.75), width: 2),
      boxShadow: const [BoxShadow(color: Color(0x22000000), offset: Offset(0, 6), blurRadius: 0)],
    );

BoxDecoration cardDecoration(Color color) => BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.cardBorder, width: 1.2),
      boxShadow: const [BoxShadow(color: Color(0x14000000), offset: Offset(0, 3), blurRadius: 6)],
    );

InputDecoration inputDecoration(String label) => InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.paper,
      labelStyle: const TextStyle(color: AppColors.softBrown),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: AppColors.line)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: AppColors.deepMint, width: 2)),
    );

class AssetBlendCard extends StatelessWidget {
  const AssetBlendCard({
    super.key,
    required this.image,
    required this.title,
    required this.subtitle,
    this.height = 148,
    this.tint = AppColors.mint,
    this.padding = const EdgeInsets.all(18),
    this.titleSize = 20,
    this.subtitleWidth = 190,
  });

  final String image;
  final String title;
  final String subtitle;
  final double height;
  final Color tint;
  final EdgeInsets padding;
  final double titleSize;
  final double subtitleWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: cardDecoration(AppColors.paper),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              image,
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
                    tint.withValues(alpha: 0.55),
                    AppColors.paper.withValues(alpha: 0.12),
                    AppColors.paper.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.44, 0.76, 1.0],
                ),
              ),
            ),
          ),
          Padding(
            padding: padding,
            child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: subtitleWidth),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontSize: titleSize, fontWeight: FontWeight.w900, color: AppColors.brown),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 13, height: 1.35, color: AppColors.softBrown, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String formatLastRun(DateTime? time) {
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

class IslandBackdrop extends StatelessWidget {
  const IslandBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(child: CustomPaint(painter: _BackdropPainter()));
  }
}

class _BackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    paint.color = AppColors.cream;
    canvas.drawRect(Offset.zero & size, paint);

    for (var i = 0; i < 8; i++) {
      final x = size.width * (0.08 + (i * 0.11) % 0.84);
      final y = size.height * (0.06 + (i * 0.13) % 0.82);
      _drawStar(canvas, Offset(x, y), 5 + (i % 3), AppColors.honey.withValues(alpha: 0.55));
      if (i.isEven) _drawLeaf(canvas, Offset(x + 18, y + 12), AppColors.deepMint.withValues(alpha: 0.35));
    }

    paint.color = AppColors.sky.withValues(alpha: 0.28);
    canvas.drawCircle(Offset(size.width * 0.86, size.height * 0.08), 72, paint);
    paint.color = AppColors.mint.withValues(alpha: 0.32);
    canvas.drawCircle(Offset(size.width * 0.05, size.height * 0.22), 54, paint);
    paint.color = AppColors.honey.withValues(alpha: 0.32);
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

class SopIllustration extends StatelessWidget {
  const SopIllustration({super.key, required this.variant, this.size = cardArtSize});

  final int variant;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line, width: 1.2),
        boxShadow: const [BoxShadow(color: Color(0x10000000), offset: Offset(0, 2), blurRadius: 0)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: CustomPaint(painter: _IllustrationPainter(variant: variant % 3)),
      ),
    );
  }
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
    paint.color = AppColors.mint;
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.62, size.width, size.height * 0.38), paint);
    paint.color = const Color(0xFF8B5E3C);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.28, size.height * 0.38, size.width * 0.44, size.height * 0.34), paint);
    paint.color = AppColors.coral;
    final roof = Path()
      ..moveTo(size.width * 0.22, size.height * 0.40)
      ..lineTo(size.width * 0.50, size.height * 0.18)
      ..lineTo(size.width * 0.78, size.height * 0.40)
      ..close();
    canvas.drawPath(roof, paint);
    paint.color = AppColors.sky;
    canvas.drawRect(Rect.fromLTWH(size.width * 0.42, size.height * 0.50, size.width * 0.16, size.height * 0.14), paint);
  }

  void _paintBoard(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    paint.color = AppColors.cream;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    paint.color = const Color(0xFF9B6B43);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.18, size.height * 0.12, size.width * 0.64, size.height * 0.76), const Radius.circular(6)), paint);
    paint.color = AppColors.paper;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.24, size.height * 0.18, size.width * 0.52, size.height * 0.46), const Radius.circular(4)), paint);
    paint.color = AppColors.sky;
    canvas.drawRect(Rect.fromLTWH(size.width * 0.30, size.height * 0.24, size.width * 0.40, size.height * 0.18), paint);
    paint.color = AppColors.mint;
    canvas.drawCircle(Offset(size.width * 0.72, size.height * 0.72), size.width * 0.08, paint);
  }

  void _paintLighthouse(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    paint.color = AppColors.sky;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height * 0.55), paint);
    paint.color = const Color(0xFF7EC0E8);
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.55, size.width, size.height * 0.45), paint);
    paint.color = AppColors.paper;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.58, size.height * 0.48, size.width * 0.28, size.height * 0.34), const Radius.circular(6)), paint);
    paint.color = AppColors.coral;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.22, size.height * 0.22, size.width * 0.18, size.height * 0.58), const Radius.circular(4)), paint);
    paint.color = AppColors.honey;
    canvas.drawRect(Rect.fromLTWH(size.width * 0.20, size.height * 0.16, size.width * 0.22, size.height * 0.10), paint);
  }

  @override
  bool shouldRepaint(covariant _IllustrationPainter oldDelegate) => oldDelegate.variant != variant;
}
