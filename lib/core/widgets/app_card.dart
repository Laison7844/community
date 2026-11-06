import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';

enum AppCardVariant {
  elevated,        // Pure white card with soft ambient shadow
  subtle,          // Soft cream background for scripture/callouts
  burgundyAccent,  // Top burgundy accent line for marriage/anniversaries
  goldAccent,      // Top gold accent line for celebrations/highlights
}

/// An elegant, rounded card with subtle CSI Church styling and warm shadows.
///
/// Supports elevated, subtle, burgundyAccent, and goldAccent variants while
/// maintaining complete backward compatibility with custom colors and borders.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final BoxBorder? border;
  final AppCardVariant variant;
  final List<BoxShadow>? shadow;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppStyles.space20),
    this.margin,
    this.color,
    this.onTap,
    this.borderRadius,
    this.border,
    this.variant = AppCardVariant.elevated,
    this.shadow,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? AppStyles.roundedLarge;

    // 1. Resolve Background Color
    final Color effectiveColor = color ?? _resolveBgColor(variant);

    // 2. Resolve Border
    final BoxBorder effectiveBorder = border ?? _resolveBorder(variant);

    // 3. Resolve Shadow
    final List<BoxShadow> effectiveShadow = shadow ?? _resolveShadow(variant);

    Widget cardContent = ClipRRect(
      borderRadius: effectiveRadius,
      child: Padding(
        padding: padding ?? EdgeInsets.zero,
        child: child,
      ),
    );

    // Accent top banner line if accent variant is active
    if (variant == AppCardVariant.burgundyAccent || variant == AppCardVariant.goldAccent) {
      final Color accentColor = variant == AppCardVariant.burgundyAccent
          ? AppColors.accentBurgundy
          : AppColors.mutedGold;

      cardContent = ClipRRect(
        borderRadius: effectiveRadius,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(height: 3.5, color: accentColor),
            Padding(
              padding: padding ?? EdgeInsets.zero,
              child: child,
            ),
          ],
        ),
      );
    }

    Widget cardWidget = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: effectiveColor,
        borderRadius: effectiveRadius,
        border: effectiveBorder,
        boxShadow: effectiveShadow,
      ),
      child: cardContent,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: effectiveRadius,
        child: cardWidget,
      );
    }

    return cardWidget;
  }

  static Color _resolveBgColor(AppCardVariant variant) {
    switch (variant) {
      case AppCardVariant.elevated:
        return AppColors.cardSurface;
      case AppCardVariant.subtle:
        return AppColors.surfaceCream;
      case AppCardVariant.burgundyAccent:
        return AppColors.cardSurface;
      case AppCardVariant.goldAccent:
        return AppColors.cardSurface;
    }
  }

  static BoxBorder _resolveBorder(AppCardVariant variant) {
    switch (variant) {
      case AppCardVariant.elevated:
        return Border.all(color: AppColors.borderDefault, width: 1.0);
      case AppCardVariant.subtle:
        return Border.all(color: AppColors.borderSubtle, width: 1.0);
      case AppCardVariant.burgundyAccent:
        return Border.all(color: AppColors.accentBurgundy.withValues(alpha: 0.25), width: 1.2);
      case AppCardVariant.goldAccent:
        return Border.all(color: AppColors.mutedGold.withValues(alpha: 0.35), width: 1.2);
    }
  }

  static List<BoxShadow> _resolveShadow(AppCardVariant variant) {
    switch (variant) {
      case AppCardVariant.elevated:
      case AppCardVariant.burgundyAccent:
      case AppCardVariant.goldAccent:
        return AppStyles.elevation1;
      case AppCardVariant.subtle:
        return AppStyles.elevation0;
    }
  }
}
