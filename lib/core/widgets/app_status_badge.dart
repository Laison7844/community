import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';

enum AppStatusType {
  pending,
  approved,
  suspended,
  rejected,
  draft,
  published,
  info,
}

/// A unified status chip conforming to the CSI Church Design System.
///
/// Automatically maps member and publication states to accessible semantic colors.
class AppStatusBadge extends StatelessWidget {
  final String label;
  final AppStatusType type;
  final bool showDot;
  final bool isCompact;

  const AppStatusBadge({
    super.key,
    required this.label,
    this.type = AppStatusType.info,
    this.showDot = false,
    this.isCompact = false,
  });

  /// Factory for string representation of status
  factory AppStatusBadge.fromString(String? status, {bool isCompact = false, bool showDot = false}) {
    final lower = status?.toLowerCase().trim() ?? '';
    AppStatusType type = AppStatusType.info;
    String label = status ?? 'Unknown';

    if (lower.contains('pending')) {
      type = AppStatusType.pending;
      label = 'Pending Review';
    } else if (lower.contains('approved') || lower.contains('active')) {
      type = AppStatusType.approved;
      label = 'Approved';
    } else if (lower.contains('suspend')) {
      type = AppStatusType.suspended;
      label = 'Suspended';
    } else if (lower.contains('reject')) {
      type = AppStatusType.rejected;
      label = 'Rejected';
    } else if (lower.contains('draft')) {
      type = AppStatusType.draft;
      label = 'Draft';
    } else if (lower.contains('publish')) {
      type = AppStatusType.published;
      label = 'Published';
    }

    return AppStatusBadge(
      label: label,
      type: type,
      isCompact: isCompact,
      showDot: showDot,
    );
  }

  @override
  Widget build(BuildContext context) {
    final _BadgeColors colors = _resolveColors(type);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? AppStyles.space8 : AppStyles.space10,
        vertical: isCompact ? 3.0 : 4.5,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
        border: Border.all(color: colors.foreground.withValues(alpha: 0.25), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: colors.foreground,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppStyles.space4),
          ],
          Text(
            label,
            style: TextStyle(
              color: colors.foreground,
              fontSize: isCompact ? 10.5 : 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  static _BadgeColors _resolveColors(AppStatusType type) {
    switch (type) {
      case AppStatusType.pending:
      case AppStatusType.draft:
        return const _BadgeColors(
          background: AppColors.statusPendingBg,
          foreground: AppColors.statusPendingFg,
        );
      case AppStatusType.approved:
      case AppStatusType.published:
        return const _BadgeColors(
          background: AppColors.statusApprovedBg,
          foreground: AppColors.statusApprovedFg,
        );
      case AppStatusType.suspended:
        return const _BadgeColors(
          background: AppColors.statusSuspendedBg,
          foreground: AppColors.statusSuspendedFg,
        );
      case AppStatusType.rejected:
        return const _BadgeColors(
          background: AppColors.statusRejectedBg,
          foreground: AppColors.statusRejectedFg,
        );
      case AppStatusType.info:
        return const _BadgeColors(
          background: AppColors.surfaceCream,
          foreground: AppColors.primaryBrown,
        );
    }
  }
}

class _BadgeColors {
  final Color background;
  final Color foreground;
  const _BadgeColors({required this.background, required this.foreground});
}
