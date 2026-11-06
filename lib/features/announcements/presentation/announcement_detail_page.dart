import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/responsive_container.dart';
import '../../admin/providers/admin_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/announcement.dart';
import '../providers/announcement_provider.dart';
import 'widgets/announcement_form_dialog.dart';

/// Full-page detailed view for a church announcement.
class AnnouncementDetailPage extends ConsumerStatefulWidget {
  final String announcementId;
  final Announcement? preloadedAnnouncement;

  const AnnouncementDetailPage({
    super.key,
    required this.announcementId,
    this.preloadedAnnouncement,
  });

  @override
  ConsumerState<AnnouncementDetailPage> createState() =>
      _AnnouncementDetailPageState();
}

class _AnnouncementDetailPageState
    extends ConsumerState<AnnouncementDetailPage> {
  bool _isProcessingAction = false;

  void _showDeleteConfirmation(Announcement announcement) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        shape: const RoundedRectangleBorder(
          borderRadius: AppStyles.roundedLarge,
        ),
        title: const Text(
          'Delete Announcement',
          style: TextStyle(
            color: AppColors.errorRed,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete "${announcement.title}"? This action cannot be undone and will be recorded in the audit log.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: AppStyles.space16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Deletion Reason (Optional)',
                hintText: 'e.g. Expired notice / Incorrect information',
                filled: true,
                fillColor: AppColors.surfaceCream,
                border: OutlineInputBorder(
                  borderRadius: AppStyles.roundedMedium,
                  borderSide: BorderSide(color: AppColors.softBeige),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await _executeDelete(announcement, reasonController.text.trim());
            },
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  Future<void> _executeDelete(Announcement announcement, String reason) async {
    final auth = ref.read(authProvider);
    final staffUid = auth.uid ?? '';
    final staffRole = auth.profile?.role ?? 'committee';

    setState(() {
      _isProcessingAction = true;
    });

    try {
      final repo = ref.read(announcementRepositoryProvider);
      final storageRepo = ref.read(storageRepositoryProvider);

      await repo.deleteAnnouncement(
        announcementId: announcement.id,
        announcementTitle: announcement.title,
        performedByUid: staffUid,
        performedByRole: staffRole,
        reason: reason.isNotEmpty ? reason : 'Announcement deleted by staff',
        storageRepo: storageRepo,
      );

      if (!mounted) return;
      context.pop(); // Return to previous page
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Announcement successfully deleted.'),
          backgroundColor: AppColors.subtleOlive,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessingAction = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  Future<void> _togglePublish(Announcement announcement) async {
    final auth = ref.read(authProvider);
    final staffUid = auth.uid ?? '';
    final staffRole = auth.profile?.role ?? 'committee';
    final targetState = !announcement.isPublished;

    setState(() {
      _isProcessingAction = true;
    });

    try {
      final repo = ref.read(announcementRepositoryProvider);
      await repo.togglePublishStatus(
        announcementId: announcement.id,
        announcementTitle: announcement.title,
        isPublished: targetState,
        performedByUid: staffUid,
        performedByRole: staffRole,
      );

      if (!mounted) return;
      setState(() {
        _isProcessingAction = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            targetState
                ? 'Announcement is now Published for congregation view.'
                : 'Announcement moved to Unpublished Draft.',
          ),
          backgroundColor: AppColors.subtleOlive,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessingAction = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final isStaff = ref.watch(isStaffUserProvider);
    final isApproved = ref.watch(isApprovedMemberProvider);

    // 1. Enforce Authentication and Approved Status
    if (!auth.isAuthenticated || !isApproved) {
      return Scaffold(
        backgroundColor: AppColors.backgroundIvory,
        appBar: AppBar(title: const Text('Parish Notice')),
        body: const Center(
          child: Text('Access restricted to verified church members.'),
        ),
      );
    }

    final detailAsync =
        ref.watch(announcementDetailProvider(widget.announcementId));

    final canUsePreloaded = widget.preloadedAnnouncement != null &&
        (isStaff || widget.preloadedAnnouncement!.isPublished);

    return Scaffold(
      backgroundColor: AppColors.backgroundIvory,
      appBar: AppBar(
        title: const Text('Parish Notice'),
        actions: [
          IconButton(
            tooltip: 'Share Notice',
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notice link ready to share.'),
                  backgroundColor: AppColors.primaryBrown,
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: detailAsync.when(
          loading: () => canUsePreloaded
              ? _buildContent(widget.preloadedAnnouncement!, isStaff)
              : const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryBrown,
                  ),
                ),
          error: (err, _) => canUsePreloaded
              ? _buildContent(widget.preloadedAnnouncement!, isStaff)
              : Center(
                  child: AppCard(
                    padding: const EdgeInsets.all(AppStyles.space24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.errorRed,
                          size: 40,
                        ),
                        const SizedBox(height: AppStyles.space12),
                        const Text(
                          'Unable to load announcement',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.errorRed,
                          ),
                        ),
                        const SizedBox(height: AppStyles.space8),
                        Text(
                          err.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: AppStyles.space16),
                        ElevatedButton(
                          onPressed: () => ref.refresh(
                            announcementDetailProvider(widget.announcementId),
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
          data: (announcement) {
            if (announcement == null || (!isStaff && !announcement.isPublished)) {
              return const Center(
                child: Text('Announcement not found or has been deleted.'),
              );
            }
            return _buildContent(announcement, isStaff);
          },
        ),
      ),
    );
  }

  Widget _buildContent(Announcement a, bool isStaff) {
    if (!isStaff && !a.isPublished) {
      return const Center(
        child: Text('Announcement not found or has been deleted.'),
      );
    }

    final formattedDate = a.createdAt != null
        ? DateFormat('EEEE, MMMM d, y · h:mm a').format(a.createdAt!)
        : 'Recent Notice';

    return ResponsiveContainer(
      maxWidth: 700,
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppStyles.space16,
          vertical: AppStyles.space16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Staff Control Ribbon (Edit, Publish, Delete)
            if (isStaff) ...[
              _buildStaffControlRibbon(a),
              const SizedBox(height: AppStyles.space16),
            ],

            // Attached Banner Image
            if (a.imageUrl != null && a.imageUrl!.isNotEmpty) ...[
              ClipRRect(
                borderRadius: AppStyles.roundedLarge,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 250),
                  child: Image.network(
                    a.imageUrl!,
                    width: double.infinity,
                    cacheWidth: 1200,
                    fit: BoxFit.cover,
                    errorBuilder: (_, error, stack) => Container(
                      height: 160,
                    color: AppColors.surfaceCream,
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: AppColors.mutedGold,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),),
              const SizedBox(height: AppStyles.space20)
            ],

            // Type and Status Badges Row
            Wrap(
              spacing: AppStyles.space8,
              runSpacing: AppStyles.space8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _buildTypeBadge(a),
                if (a.announcementStage != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentWine,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      a.announcementStage!.displayName,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                if (!a.isPublished)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: const Text(
                      'Unpublished Draft',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppStyles.space12),

            // Announcement Title
            SelectableText(
              a.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryBrown,
                height: 1.3,
              ),
            ),
            const SizedBox(height: AppStyles.space8),

            // Publication Metadata & Scheduled Event Timing
            Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                Text(
                  formattedDate,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (a.createdByName != null &&
                    a.createdByName!.isNotEmpty) ...[
                  const Text(
                    ' · ',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  Text(
                    'By ${a.createdByName}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),

            // Scheduled Date/Time Banner for General / Special
            if (a.scheduledDate != null || (a.scheduledTime != null && a.scheduledTime!.isNotEmpty)) ...[
              const SizedBox(height: AppStyles.space12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: a.announcementType == AnnouncementType.special
                      ? AppColors.mutedGoldLight.withValues(alpha: 0.3)
                      : AppColors.surfaceCream,
                  borderRadius: AppStyles.roundedMedium,
                  border: Border.all(
                    color: a.announcementType == AnnouncementType.special
                        ? AppColors.mutedGoldDark.withValues(alpha: 0.3)
                        : AppColors.softBeige,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.event_available_rounded,
                      size: 16,
                      color: a.announcementType == AnnouncementType.special
                          ? AppColors.mutedGoldDark
                          : AppColors.primaryBrown,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Scheduled Event: ${a.scheduledDate != null ? DateFormat('EEEE, MMM d, y').format(a.scheduledDate!) : ''} ${a.scheduledTime ?? ''}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: a.announcementType == AnnouncementType.special
                              ? AppColors.mutedGoldDark
                              : AppColors.primaryBrown,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const Divider(height: AppStyles.space32),

            // Marriage Announcement Details Card
            if (a.announcementType == AnnouncementType.marriage) ...[
              Container(
                padding: const EdgeInsets.all(AppStyles.space16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCream,
                  borderRadius: AppStyles.roundedLarge,
                  border: Border.all(color: AppColors.accentWine.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bride Section
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.person_outline_rounded, color: AppColors.accentWine, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Bride',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.accentWine,
                                ),
                              ),
                              Text(
                                a.brideName ?? '',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryBrown,
                                ),
                              ),
                              if (a.brideDetails != null && a.brideDetails!.isNotEmpty)
                                Text(
                                  a.brideDetails!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24, color: AppColors.softBeige),

                    // Groom Section
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.person_rounded, color: AppColors.accentWine, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Groom',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.accentWine,
                                ),
                              ),
                              Text(
                                a.groomName ?? '',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryBrown,
                                ),
                              ),
                              if (a.groomDetails != null && a.groomDetails!.isNotEmpty)
                                Text(
                                  a.groomDetails!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24, color: AppColors.softBeige),

                    // Marriage Date
                    Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded, color: AppColors.accentWine, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Marriage Date: ${a.marriageDate != null ? DateFormat('dd MMMM yyyy').format(a.marriageDate!) : "Announced Soon"}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accentWine,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppStyles.space16),
            ],

            // Main Body Description Card (if present)
            if (a.description.isNotEmpty) ...[
              AppCard(
                color: AppColors.cardSurface,
                padding: const EdgeInsets.all(AppStyles.space20),
                child: SelectableText(
                  a.description,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: AppStyles.space32),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStaffControlRibbon(Announcement a) {
    if (_isProcessingAction) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(8),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return AppCard(
      color: AppColors.surfaceCream,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.admin_panel_settings_rounded,
                color: AppColors.primaryBrown,
                size: 20,
              ),
              SizedBox(width: AppStyles.space8),
              Text(
                'Staff Actions',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryBrown,
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Edit Button
              TextButton.icon(
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit'),
                onPressed: () => showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => AnnouncementFormDialog(
                    initialAnnouncement: a,
                  ),
                ).then((val) {
                  if (val == true) {
                    ref.invalidate(
                      announcementDetailProvider(widget.announcementId),
                    );
                  }
                }),
              ),

              // Publish/Unpublish Toggle
              TextButton.icon(
                icon: Icon(
                  a.isPublished
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 16,
                ),
                label: Text(a.isPublished ? 'Unpublish' : 'Publish'),
                onPressed: () => _togglePublish(a),
              ),

              // Delete Button
              IconButton(
                tooltip: 'Delete Notice',
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.errorRed,
                  size: 20,
                ),
                onPressed: () => _showDeleteConfirmation(a),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(Announcement a) {
    Color bg;
    Color fg;
    IconData icon;
    String label;

    switch (a.announcementType) {
      case AnnouncementType.marriage:
        bg = AppColors.accentWine.withValues(alpha: 0.12);
        fg = AppColors.accentWine;
        icon = Icons.favorite_rounded;
        label = 'MARRIAGE ANNOUNCEMENT';
        break;
      case AnnouncementType.special:
        bg = AppColors.mutedGoldLight.withValues(alpha: 0.5);
        fg = AppColors.mutedGoldDark;
        icon = Icons.star_rounded;
        label = 'SPECIAL ANNOUNCEMENT';
        break;
      case AnnouncementType.general:
        bg = AppColors.primaryBrown.withValues(alpha: 0.1);
        fg = AppColors.primaryBrown;
        icon = Icons.campaign_outlined;
        label = 'GENERAL ANNOUNCEMENT';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
