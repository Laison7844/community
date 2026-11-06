import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';

/// A standard key-value display row conforming to the CSI Church Design System.
///
/// Used in member profile inspection dialogs, registration summaries,
/// and church directory views.
class AppInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final bool isSelectable;
  final Color? valueColor;
  final bool isBold;
  final Widget? trailing;
  final bool showDivider;

  const AppInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.isSelectable = true,
    this.valueColor,
    this.isBold = false,
    this.trailing,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    final valueWidget = isSelectable
        ? SelectableText(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
              color: valueColor ?? AppColors.textPrimary,
            ),
          )
        : Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
              color: valueColor ?? AppColors.textPrimary,
            ),
          );

    final rowContent = Padding(
      padding: const EdgeInsets.symmetric(vertical: AppStyles.space8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: AppStyles.space8),
          ],
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Flexible(child: valueWidget),
          if (trailing != null) ...[
            const SizedBox(width: AppStyles.space8),
            trailing!,
          ],
        ],
      ),
    );

    if (showDivider) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          rowContent,
          const Divider(height: 1.0, color: AppColors.borderSubtle),
        ],
      );
    }

    return rowContent;
  }
}

