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
    final isStaff = ref.watch(isStaffUserProvider);
    final detailAsync =
        ref.watch(announcementDetailProvider(widget.announcementId));

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
          loading: () => widget.preloadedAnnouncement != null
              ? _buildContent(widget.preloadedAnnouncement!, isStaff)
              : const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryBrown,
                  ),
                ),
          error: (err, _) => widget.preloadedAnnouncement != null
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
            if (announcement == null) {
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
    final formattedDate = a.createdAt != null
        ? DateFormat('EEEE, MMMM d, y · h:mm a').format(a.createdAt!)
        : 'Recent Notice';

    return ResponsiveContainer(
      maxWidth: 800,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppStyles.space16,
          vertical: AppStyles.space20,
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
                child: Image.network(
                  a.imageUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, error, stack) => Container(
                    height: 180,
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
              ),
              const SizedBox(height: AppStyles.space20),
            ],

            // Priority and Status Badges Row
            Row(
              children: [
                _buildPriorityBadge(a.priority),
                if (!a.isPublished) ...[
                  const SizedBox(width: AppStyles.space8),
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

            // Publication Metadata
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
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
            const Divider(height: AppStyles.space32),

            // Main Body Description Card
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(
            Icons.admin_panel_settings_rounded,
            color: AppColors.primaryBrown,
            size: 20,
          ),
          const SizedBox(width: AppStyles.space8),
          const Text(
            'Staff Actions',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryBrown,
            ),
          ),
          const Spacer(),

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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        priority.displayName.toUpperCase(),
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
