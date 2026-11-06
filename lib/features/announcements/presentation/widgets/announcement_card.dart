import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../models/announcement.dart';

/// Clean church-themed card presenting announcements (Marriage, General, Special) in feeds.
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    switch (a.announcementType) {
      case AnnouncementType.marriage:
        return _buildMarriageCard(context, a, isMobile);
      case AnnouncementType.special:
        return _buildSpecialCard(context, a, isMobile);
      case AnnouncementType.general:
        return _buildGeneralCard(context, a, isMobile);
    }
  }

  /// 1. Marriage Announcement Card
  Widget _buildMarriageCard(BuildContext context, Announcement a, bool isMobile) {
    final marriageDateStr = a.marriageDate != null
        ? DateFormat('dd MMM yyyy').format(a.marriageDate!)
        : 'Date Announced Soon';

    return AppCard(
      padding: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppStyles.roundedLarge,
          border: Border.all(color: AppColors.accentWine.withValues(alpha: 0.25), width: 1.5),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              AppColors.surfaceCream.withValues(alpha: 0.6),
            ],
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: AppStyles.roundedLarge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Banner with rings & stage badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.accentWine.withValues(alpha: 0.08),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppStyles.radiusLarge),
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.accentWine.withValues(alpha: 0.15),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.accentWine,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Marriage Announcement',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accentWine,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    if (a.announcementStage != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.accentWine,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          a.announcementStage!.displayName,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    if (isStaff && !a.isPublished) ...[
                      const SizedBox(width: 6),
                      _buildDraftBadge(),
                    ],
                  ],
                ),
              ),

              // Attached image if available
              if (a.imageUrl != null && a.imageUrl!.isNotEmpty)
                _buildBannerImage(a.imageUrl!, isMobile ? 130 : 160),

              Padding(
                padding: EdgeInsets.all(isMobile ? 12.0 : AppStyles.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bride & Groom Info Box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCream,
                        borderRadius: AppStyles.roundedMedium,
                        border: Border.all(color: AppColors.softBeige),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Bride
                          _buildPersonRow(
                            role: 'Bride',
                            name: a.brideName ?? 'Bride',
                            details: a.brideDetails,
                            icon: Icons.person_outline_rounded,
                          ),
                          const Divider(height: 16, color: AppColors.softBeige),
                          // Groom
                          _buildPersonRow(
                            role: 'Groom',
                            name: a.groomName ?? 'Groom',
                            details: a.groomDetails,
                            icon: Icons.person_rounded,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.accentWine.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.accentWine.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.calendar_month_rounded,
                                size: 14,
                                color: AppColors.accentWine,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Marriage Date: $marriageDateStr',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.accentWine,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildReadMoreButton(),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 2. Special Announcement Card (Church Celebrations: Christmas, Easter, Church Day)
  Widget _buildSpecialCard(BuildContext context, Announcement a, bool isMobile) {
    final dateStr = a.scheduledDate != null
        ? DateFormat('EEE, MMM d, y').format(a.scheduledDate!)
        : (a.createdAt != null ? DateFormat('MMM d, y').format(a.createdAt!) : '');

    return AppCard(
      padding: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppStyles.roundedLarge,
          border: Border.all(color: AppColors.mutedGoldDark.withValues(alpha: 0.4), width: 1.5),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              AppColors.mutedGoldLight.withValues(alpha: 0.18),
            ],
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: AppStyles.roundedLarge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Festive celebration header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.mutedGoldLight.withValues(alpha: 0.4),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppStyles.radiusLarge),
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.mutedGoldDark.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: AppColors.mutedGoldDark,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'SPECIAL CELEBRATION',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.mutedGoldDark,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const Spacer(),
                    if (isStaff && !a.isPublished) _buildDraftBadge(),
                  ],
                ),
              ),

              // Attached image
              if (a.imageUrl != null && a.imageUrl!.isNotEmpty)
                _buildBannerImage(a.imageUrl!, isMobile ? 120 : 155),

              Padding(
                padding: EdgeInsets.all(isMobile ? 12.0 : AppStyles.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Scheduled Date & Time row
                    if (dateStr.isNotEmpty || a.scheduledTime != null) ...[
                      Row(
                        children: [
                          if (dateStr.isNotEmpty) ...[
                            Icon(Icons.event_rounded, size: 14, color: AppColors.primaryBrown),
                            const SizedBox(width: 4),
                            Text(
                              dateStr,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryBrown,
                              ),
                            ),
                          ],
                          if (a.scheduledTime != null && a.scheduledTime!.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            Icon(Icons.schedule_rounded, size: 14, color: AppColors.primaryBrown),
                            const SizedBox(width: 4),
                            Text(
                              a.scheduledTime!,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryBrown,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Title
                    Text(
                      a.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryBrown,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Description
                    if (a.description.isNotEmpty)
                      Text(
                        a.description,
                        maxLines: isMobile ? 2 : 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 13,
                          color: AppColors.textPrimary.withValues(alpha: 0.85),
                          height: 1.35,
                        ),
                      ),
                    const SizedBox(height: 10),

                    // Footer
                    Row(
                      children: [
                        if (a.createdByName != null && a.createdByName!.isNotEmpty)
                          Expanded(
                            child: Text(
                              'Posted by ${a.createdByName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          )
                        else
                          const Spacer(),
                        _buildReadMoreButton(),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 3. General Announcement Card
  Widget _buildGeneralCard(BuildContext context, Announcement a, bool isMobile) {
    final dateStr = a.scheduledDate != null
        ? DateFormat('EEE, MMM d, y').format(a.scheduledDate!)
        : (a.createdAt != null ? DateFormat('MMM d, y').format(a.createdAt!) : 'Recent');

    return AppCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppStyles.roundedLarge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Attached image
            if (a.imageUrl != null && a.imageUrl!.isNotEmpty)
              _buildBannerImage(a.imageUrl!, isMobile ? 120 : 155),

            Padding(
              padding: EdgeInsets.all(isMobile ? 12.0 : AppStyles.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBrown.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.campaign_outlined, size: 12, color: AppColors.primaryBrown),
                            SizedBox(width: 4),
                            Text(
                              'GENERAL',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryBrown,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isStaff && !a.isPublished) ...[
                        const SizedBox(width: 8),
                        _buildDraftBadge(),
                      ],
                      const Spacer(),
                      Text(
                        dateStr,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Scheduled time if present
                  if (a.scheduledTime != null && a.scheduledTime!.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.schedule_rounded, size: 13, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          a.scheduledTime!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],

                  // Title
                  Text(
                    a.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isMobile ? 15 : 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryBrown,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Description snippet
                  if (a.description.isNotEmpty)
                    Text(
                      a.description,
                      maxLines: isMobile ? 2 : 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 13,
                        color: AppColors.textPrimary.withValues(alpha: 0.85),
                        height: 1.35,
                      ),
                    ),
                  const SizedBox(height: 8),

                  // Read details footer
                  Row(
                    children: [
                      if (a.createdByName != null && a.createdByName!.isNotEmpty)
                        Expanded(
                          child: Text(
                            'Posted by ${a.createdByName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        )
                      else
                        const Spacer(),
                      _buildReadMoreButton(),
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

  Widget _buildPersonRow({
    required String role,
    required String name,
    String? details,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.accentWine),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$role: $name',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryBrown,
                ),
              ),
              if (details != null && details.trim().isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  details,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBannerImage(String imageUrl, double height) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppStyles.radiusLarge),
      ),
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          cacheWidth: 800,
          errorBuilder: (_, error, stack) => Container(
            color: AppColors.surfaceCream,
            child: const Center(
              child: Icon(
                Icons.image_not_supported_outlined,
                color: AppColors.mutedGold,
                size: 32,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDraftBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: const Text(
        'Draft',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildReadMoreButton() {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Read Details',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryBrown,
          ),
        ),
        SizedBox(width: 4),
        Icon(
          Icons.arrow_forward_rounded,
          size: 13,
          color: AppColors.primaryBrown,
        ),
      ],
    );
  }
}
