import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../constants/app_styles.dart';

/// An elegant church emblem featuring a stylized cross and gentle gold aura.
///
/// Can be displayed as an icon emblem alone, or with the church title and tagline.
class AppLogo extends StatelessWidget {
  final double size;
  final bool showTitle;
  final bool showTagline;
  final Color? crossColor;
  final Color? circleColor;

  const AppLogo({
    super.key,
    this.size = 80.0,
    this.showTitle = false,
    this.showTagline = false,
    this.crossColor,
    this.circleColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveCircleColor = circleColor ?? AppColors.primaryBrown;
    final effectiveCrossColor = crossColor ?? AppColors.mutedGold;

    final logoGraphic = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: effectiveCircleColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.mutedGold.withValues(alpha: 0.5),
          width: size * 0.04,
        ),
        boxShadow: AppStyles.goldGlowShadow,
      ),
      child: Center(
        child: CustomPaint(
          size: Size(size * 0.55, size * 0.55),
          painter: _ChurchCrossPainter(color: effectiveCrossColor),
        ),
      ),
    );

    if (!showTitle && !showTagline) {
      return logoGraphic;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        logoGraphic,
        if (showTitle) ...[
          const SizedBox(height: AppStyles.space16),
          Text(
            AppStrings.churchName,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryBrown,
                  letterSpacing: 0.5,
                ),
          ),
        ],
        if (showTagline) ...[
          const SizedBox(height: AppStyles.space8),
          Text(
            AppStrings.tagline,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.mutedGoldDark,
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ],
    );
  }
}

/// Custom painter for a classic Christian Cross with soft tapered edges.
class _ChurchCrossPainter extends CustomPainter {
  final Color color;

  _ChurchCrossPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final double w = size.width;
    final double h = size.height;
    final double beamThickness = w * 0.22;
    final double radius = beamThickness * 0.25;

    // Vertical beam (starts at 0, goes down to h)
    final verticalRect = RRect.fromRectAndRadius(
      Rect.fromLTWH((w - beamThickness) / 2, 0, beamThickness, h),
      Radius.circular(radius),
    );

    // Horizontal cross beam (sits at 28% from top)
    final double beamY = h * 0.28;
    final horizontalRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, beamY, w, beamThickness),
      Radius.circular(radius),
    );

    canvas.drawRRect(verticalRect, paint);
    canvas.drawRRect(horizontalRect, paint);
  }

  @override
  bool shouldRepaint(covariant _ChurchCrossPainter oldDelegate) =>
      oldDelegate.color != color;
}
