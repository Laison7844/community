import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import 'app_button.dart';

/// A standard empty state placeholder conforming to the CSI Church Design System.
///
/// Features a gentle circular icon emblem, bold headline, descriptive subtitle,
/// and optional primary action button.
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final EdgeInsetsGeometry padding;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.iconColor,
    this.iconBackgroundColor,
    this.padding = const EdgeInsets.all(AppStyles.space32),
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? AppColors.primaryBrown;
    final effectiveBgColor = iconBackgroundColor ?? AppColors.surfaceCream;

    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppStyles.space20),
              decoration: BoxDecoration(
                color: effectiveBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: effectiveIconColor,
                size: 40,
              ),
            ),
            const SizedBox(height: AppStyles.space16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryBrown,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: AppStyles.space8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppStyles.space20),
              AppButton(
                label: actionLabel!,
                onPressed: onAction,
                size: AppButtonSize.regular,
                width: null, // Wrap content
              ),
            ],
          ],
        ),
      ),
    );
  }
}

