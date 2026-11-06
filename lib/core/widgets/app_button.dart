import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';

enum AppButtonVariant {
  primary,     // Deep Church Brown
  gold,        // Muted Gold
  secondary,   // Alias for Gold
  outline,     // Soft Beige / Brown Outline
  destructive, // Error Red (Confirm rejection, suspend, delete)
  text,        // Flat Text / Ghost
  ghost,       // Alias for Text
}

enum AppButtonSize {
  compact, // 36px height (In-table actions, inline chips)
  regular, // 44px height (Standard cards, dialog actions)
  large,   // 50px height (Prominent full-width form submits, landing actions)
}

/// A reusable, elegant button adhering to the CSI Church theme.
///
/// Supports primary, secondary/gold, outline, destructive, and ghost variants
/// across compact (36px), regular (44px), and large (50px) sizes.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool isLoading;
  final IconData? icon;
  final IconData? trailingIcon;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.large,
    this.isLoading = false,
    this.icon,
    this.trailingIcon,
    this.width = double.infinity,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Resolve size parameters
    final double resolvedHeight = height ?? _resolveDefaultHeight(size);
    final double iconSize = _resolveIconSize(size);
    final double fontSize = _resolveFontSize(size);
    final EdgeInsets padding = _resolvePadding(size);
    final BorderRadius effectiveRadius = borderRadius ?? AppStyles.roundedMedium;

    // 2. Resolve colors according to variant
    final Color spinnerColor = _resolveSpinnerColor(variant);

    Widget childContent = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              valueColor: AlwaysStoppedAnimation<Color>(spinnerColor),
            ),
          )
        else ...[
          if (icon != null) ...[
            Icon(icon, size: iconSize),
            SizedBox(width: size == AppButtonSize.compact ? AppStyles.space4 : AppStyles.space8),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
          if (trailingIcon != null) ...[
            SizedBox(width: size == AppButtonSize.compact ? AppStyles.space4 : AppStyles.space8),
            Icon(trailingIcon, size: iconSize),
          ],
        ],
      ],
    );

    final effectiveOnPressed = isLoading ? null : onPressed;

    Widget button;
    switch (variant) {
      case AppButtonVariant.primary:
        button = ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBrown,
            foregroundColor: AppColors.textOnPrimary,
            elevation: 0,
            padding: padding,
            shape: RoundedRectangleBorder(borderRadius: effectiveRadius),
          ),
          child: childContent,
        );
        break;

      case AppButtonVariant.gold:
      case AppButtonVariant.secondary:
        button = ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.mutedGold,
            foregroundColor: AppColors.textOnGold,
            elevation: 0,
            padding: padding,
            shape: RoundedRectangleBorder(borderRadius: effectiveRadius),
          ),
          child: childContent,
        );
        break;

      case AppButtonVariant.outline:
        button = OutlinedButton(
          onPressed: effectiveOnPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryBrown,
            padding: padding,
            side: const BorderSide(color: AppColors.borderDefault, width: 1.2),
            shape: RoundedRectangleBorder(borderRadius: effectiveRadius),
          ),
          child: childContent,
        );
        break;

      case AppButtonVariant.destructive:
        button = OutlinedButton(
          onPressed: effectiveOnPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: AppColors.statusSuspendedBg.withValues(alpha: 0.5),
            foregroundColor: AppColors.errorRed,
            padding: padding,
            side: const BorderSide(color: AppColors.errorRed, width: 1.2),
            shape: RoundedRectangleBorder(borderRadius: effectiveRadius),
          ),
          child: childContent,
        );
        break;

      case AppButtonVariant.text:
      case AppButtonVariant.ghost:
        button = TextButton(
          onPressed: effectiveOnPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primaryBrown,
            padding: padding,
            shape: RoundedRectangleBorder(borderRadius: effectiveRadius),
          ),
          child: childContent,
        );
        break;
    }

    if (width == null) {
      return SizedBox(
        height: resolvedHeight,
        child: button,
      );
    }

    return SizedBox(
      width: width,
      height: resolvedHeight,
      child: button,
    );
  }

  static double _resolveDefaultHeight(AppButtonSize size) {
    switch (size) {
      case AppButtonSize.compact:
        return 36.0;
      case AppButtonSize.regular:
        return 44.0;
      case AppButtonSize.large:
        return 50.0;
    }
  }

  static double _resolveIconSize(AppButtonSize size) {
    switch (size) {
      case AppButtonSize.compact:
        return 16.0;
      case AppButtonSize.regular:
        return 18.0;
      case AppButtonSize.large:
        return 20.0;
    }
  }

  static double _resolveFontSize(AppButtonSize size) {
    switch (size) {
      case AppButtonSize.compact:
        return 13.0;
      case AppButtonSize.regular:
        return 14.0;
      case AppButtonSize.large:
        return 15.0;
    }
  }

  static EdgeInsets _resolvePadding(AppButtonSize size) {
    switch (size) {
      case AppButtonSize.compact:
        return const EdgeInsets.symmetric(horizontal: AppStyles.space12, vertical: AppStyles.space4);
      case AppButtonSize.regular:
        return const EdgeInsets.symmetric(horizontal: AppStyles.space16, vertical: AppStyles.space8);
      case AppButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: AppStyles.space20, vertical: AppStyles.space12);
    }
  }

  static Color _resolveSpinnerColor(AppButtonVariant variant) {
    switch (variant) {
      case AppButtonVariant.primary:
        return AppColors.textOnPrimary;
      case AppButtonVariant.gold:
      case AppButtonVariant.secondary:
        return AppColors.textOnGold;
      case AppButtonVariant.outline:
      case AppButtonVariant.text:
      case AppButtonVariant.ghost:
        return AppColors.primaryBrown;
      case AppButtonVariant.destructive:
        return AppColors.errorRed;
    }
  }
}
