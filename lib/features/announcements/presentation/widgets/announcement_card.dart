import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../models/announcement.dart';

/// Clean church-themed card presenting an announcement in feeds.
class AnnouncementCard extends StatelessWidget {
  final Announcement announcement;
  final VoidCallback onTap;
  final bool isStaff;

  const AnnouncementCard({
    super.key,
    required this.announcement,
    required this.onTap,
    this.isStaff = false,
  });

  @override
  Widget build(BuildContext context) {
    final a = announcement;
    final dateStr = a.createdAt != null
        ? DateFormat('MMM d, y').format(a.createdAt!)
        : 'Recent';

    return AppCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppStyles.roundedLarge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Attached banner image preview if available
            if (a.imageUrl != null && a.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppStyles.radiusLarge),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 160,
                  child: Image.network(
                    a.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, error, stack) => Container(
                      color: AppColors.surfaceCream,
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: AppColors.mutedGold,
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(AppStyles.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges Row (Priority + Date + Draft status for staff)
                  Row(
                    children: [
                      _buildPriorityBadge(a.priority),
                      if (isStaff && !a.isPublished) ...[
                        const SizedBox(width: AppStyles.space8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey.shade400),
                          ),
                          child: const Text(
                            'Draft (Unpublished)',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      Text(
                        dateStr,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppStyles.space12),

                  // Announcement Title
                  Text(
                    a.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryBrown,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: AppStyles.space8),

                  // Announcement Description snippet
                  Text(
                    a.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary.withValues(alpha: 0.85),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: AppStyles.space12),

                  // Read More Link
                  Row(
                    children: [
                      if (a.createdByName != null &&
                          a.createdByName!.isNotEmpty) ...[
                        Text(
                          'Posted by ${a.createdByName}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const Spacer(),
                      ] else
                        const Spacer(),
                      const Text(
                        'Read Details',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryBrown,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: AppColors.primaryBrown,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(AnnouncementPriority priority) {
    Color bg;
    Color fg;

    switch (priority) {
      case AnnouncementPriority.urgent:
        bg = AppColors.errorRedLight;
        fg = AppColors.errorRed;
        break;
      case AnnouncementPriority.high:
        bg = AppColors.warningAmberLight;
        fg = AppColors.warningAmber;
        break;
      case AnnouncementPriority.normal:
        bg = AppColors.mutedGold.withValues(alpha: 0.15);
        fg = AppColors.primaryBrown;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        priority.displayName.toUpperCase(),
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
