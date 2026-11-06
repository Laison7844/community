import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';

/// A standard section header conforming to the CSI Church Design System.
///
/// Features an optional leading icon, section title, item count badge,
/// optional subtitle, and trailing action button.
class AppSectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color? color;
  final int? count;
  final String? subtitle;
  final Widget? action;
  final EdgeInsetsGeometry padding;

  const AppSectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.color,
    this.count,
    this.subtitle,
    this.action,
    this.padding = const EdgeInsets.symmetric(vertical: AppStyles.space8),
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primaryBrown;

    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(AppStyles.space8),
              decoration: BoxDecoration(
                color: effectiveColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
              ),
              child: Icon(icon, color: effectiveColor, size: 18),
            ),
            const SizedBox(width: AppStyles.space12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: effectiveColor,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                    if (count != null) ...[
                      const SizedBox(width: AppStyles.space8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: effectiveColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppStyles.radiusFull),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: effectiveColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}
