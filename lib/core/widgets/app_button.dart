import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';

enum AppButtonVariant {
  primary, // Deep Church Brown
  gold,    // Muted Gold
  outline, // Soft Beige / Brown Outline
  text,    // Flat Text
}

/// A reusable, elegant button adhering to the church theme.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double height;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.width = double.infinity,
    this.height = 50.0,
  });

  @override
  Widget build(BuildContext context) {
    Widget childContent = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(
                variant == AppButtonVariant.outline
                    ? AppColors.primaryBrown
                    : (variant == AppButtonVariant.gold
                        ? AppColors.textOnGold
                        : AppColors.textOnPrimary),
              ),
            ),
          )
        else ...[
          if (icon != null) ...[
            Icon(icon, size: 20),
            const SizedBox(width: AppStyles.space8),
          ],
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
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
            elevation: 1,
            shadowColor: AppColors.primaryBrown.withValues(alpha: 0.3),
            shape: const RoundedRectangleBorder(
              borderRadius: AppStyles.roundedMedium,
            ),
          ),
          child: childContent,
        );
        break;

      case AppButtonVariant.gold:
        button = ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.mutedGold,
            foregroundColor: AppColors.textOnGold,
            elevation: 1,
            shadowColor: AppColors.mutedGold.withValues(alpha: 0.3),
            shape: const RoundedRectangleBorder(
              borderRadius: AppStyles.roundedMedium,
            ),
          ),
          child: childContent,
        );
        break;

      case AppButtonVariant.outline:
        button = OutlinedButton(
          onPressed: effectiveOnPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryBrown,
            side: const BorderSide(color: AppColors.softBeige, width: 1.5),
            shape: const RoundedRectangleBorder(
              borderRadius: AppStyles.roundedMedium,
            ),
          ),
          child: childContent,
        );
        break;

      case AppButtonVariant.text:
        button = TextButton(
          onPressed: effectiveOnPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primaryBrown,
          ),
          child: childContent,
        );
        break;
    }

    return SizedBox(
      width: width,
      height: height,
      child: button,
    );
  }
}
