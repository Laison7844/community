import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import 'app_button.dart';
import 'app_card.dart';

/// A standard error state widget conforming to the CSI Church Design System.
///
/// Provides graceful error communication with actionable retry triggers.
class AppErrorState extends StatelessWidget {
  final String title;
  final String? message;
  final VoidCallback? onRetry;
  final String retryLabel;
  final IconData icon;
  final bool isCard;
  final EdgeInsetsGeometry padding;

  const AppErrorState({
    super.key,
    this.title = 'Unable to Load Data',
    this.message,
    this.onRetry,
    this.retryLabel = 'Retry',
    this.icon = Icons.error_outline_rounded,
    this.isCard = true,
    this.padding = const EdgeInsets.all(AppStyles.space24),
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(AppStyles.space12),
          decoration: BoxDecoration(
            color: AppColors.errorRedLight,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.2)),
          ),
          child: Icon(icon, color: AppColors.errorRed, size: 32),
        ),
        const SizedBox(height: AppStyles.space12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.errorRed,
          ),
        ),
        if (message != null && message!.isNotEmpty) ...[
          const SizedBox(height: AppStyles.space8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Text(
              message!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
        if (onRetry != null) ...[
          const SizedBox(height: AppStyles.space16),
          AppButton(
            label: retryLabel,
            icon: Icons.refresh_rounded,
            onPressed: onRetry,
            size: AppButtonSize.compact,
            width: null, // Wrap content
          ),
        ],
      ],
    );

    if (isCard) {
      return Center(
        child: Padding(
          padding: padding,
          child: AppCard(
            color: AppColors.errorRedLight.withValues(alpha: 0.35),
            border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.3), width: 1.0),
            padding: const EdgeInsets.all(AppStyles.space24),
            child: content,
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: padding,
        child: content,
      ),
    );
  }
}

