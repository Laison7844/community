import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';

/// An elegant, rounded card with subtle church styling and soft shadows.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final Border? border;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppStyles.space20),
    this.margin,
    this.color,
    this.onTap,
    this.borderRadius,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? AppStyles.roundedLarge;

    Widget cardWidget = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? AppColors.cardSurface,
        borderRadius: effectiveRadius,
        border: border ?? Border.all(color: AppColors.softBeige, width: 1.0),
        boxShadow: AppStyles.softCardShadow,
      ),
      child: ClipRRect(
        borderRadius: effectiveRadius,
        child: Padding(
          padding: padding ?? EdgeInsets.zero,
          child: child,
        ),
      ),
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
}
