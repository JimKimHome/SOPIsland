import 'package:flutter/material.dart';

abstract final class AppColors {
  static const cream = Color(0xFFF7F8FA);
  static const paper = Color(0xFFFFFFFF);
  static const mint = Color(0xFFEAF7EF);
  static const deepMint = Color(0xFF2F855A);
  static const sky = Color(0xFFE8F1FF);
  static const coral = Color(0xFFE5483D);
  static const honey = Color(0xFFFFF4D6);
  static const brown = Color(0xFF1F2933);
  static const softBrown = Color(0xFF667085);
  static const line = Color(0xFFE4E7EC);
  static const headerBg = Color(0xFFF2F4F7);
  static const cardBorder = Color(0xFFEAECF0);
}

ThemeData buildAppTheme() => ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  scaffoldBackgroundColor: AppColors.cream,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.coral,
    brightness: Brightness.light,
  ),
  fontFamily: 'sans',
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    centerTitle: false,
    foregroundColor: AppColors.brown,
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.coral,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(fontWeight: FontWeight.w800),
    ),
  ),
);

BoxDecoration softBox(Color color) => BoxDecoration(
  color: color,
  borderRadius: BorderRadius.circular(18),
  border: Border.all(color: AppColors.line),
  boxShadow: const [
    BoxShadow(color: Color(0x0F101828), offset: Offset(0, 10), blurRadius: 24),
  ],
);

BoxDecoration cardDecoration(Color color) => BoxDecoration(
  color: color,
  borderRadius: BorderRadius.circular(18),
  border: Border.all(color: AppColors.cardBorder),
  boxShadow: const [
    BoxShadow(color: Color(0x0A101828), offset: Offset(0, 8), blurRadius: 22),
  ],
);

InputDecoration inputDecoration(String label) => InputDecoration(
  labelText: label,
  filled: true,
  fillColor: AppColors.paper,
  labelStyle: const TextStyle(color: AppColors.softBrown),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: AppColors.line),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: AppColors.coral, width: 1.6),
  ),
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
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Padding(
        padding: padding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.45),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.brown,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: subtitleWidth),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brown,
                        height: 1.12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: AppColors.softBrown,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.softBrown,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
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
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFFFFF), AppColors.cream],
      ).createShader(rect);
    canvas.drawRect(rect, paint);

    paint
      ..shader = null
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.line.withValues(alpha: 0.45);
    for (var y = 96.0; y < size.height; y += 56) {
      canvas.drawLine(Offset(20, y), Offset(size.width - 20, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
