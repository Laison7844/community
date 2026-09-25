import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/responsive_container.dart';
import '../../admin/providers/admin_provider.dart';
import '../../auth/models/auth_state.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/announcement.dart';
import '../providers/announcement_provider.dart';
import 'widgets/announcement_card.dart';
import 'widgets/announcement_form_dialog.dart';

/// Announcements list page showing active parish notices to church members and staff.
class AnnouncementsPage extends ConsumerStatefulWidget {
  const AnnouncementsPage({super.key});

  @override
  ConsumerState<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends ConsumerState<AnnouncementsPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openCreateDialog(AnnouncementType type) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AnnouncementFormDialog(initialType: type),
    );
  }

  void _showStaffCreateOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create New Announcement',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryBrown,
                ),
              ),
              const SizedBox(height: 16),
              _buildActionCard(
                title: 'Marriage Announcement',
                subtitle: 'Publish 1st, 2nd or 3rd marriage announcement',
                icon: Icons.favorite_rounded,
                color: AppColors.accentWine,
                onTap: () {
                  Navigator.pop(ctx);
                  _openCreateDialog(AnnouncementType.marriage);
                },
              ),
              const SizedBox(height: 10),
              _buildActionCard(
                title: 'General Announcement',
                subtitle: 'Share regular church information',
                icon: Icons.campaign_rounded,
                color: AppColors.primaryBrown,
                onTap: () {
                  Navigator.pop(ctx);
                  _openCreateDialog(AnnouncementType.general);
                },
              ),
              const SizedBox(height: 10),
              _buildActionCard(
                title: 'Special Announcement',
                subtitle: 'Highlight major church celebrations',
                icon: Icons.star_rounded,
                color: AppColors.mutedGoldDark,
                onTap: () {
                  Navigator.pop(ctx);
                  _openCreateDialog(AnnouncementType.special);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final isStaff = ref.watch(isStaffUserProvider);
    final isApproved = ref.watch(isApprovedMemberProvider);

    // 1. Enforce Authentication
    if (!auth.isAuthenticated) {
      return _buildAuthRequiredView(context);
    }

    // 2. Enforce Approved Church Membership
    if (!isApproved) {
      return _buildPendingApprovalView(context, auth);
    }

    final announcementsAsync = ref.watch(filteredAnnouncementsProvider);
    final activeType = ref.watch(announcementTypeFilterProvider);
    final activeStatus = ref.watch(announcementStatusFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundIvory,
      appBar: AppBar(
        title: const Text('Parish Announcements'),
        actions: [
          if (isStaff)
            IconButton(
              tooltip: 'New Notice',
              icon: const Icon(
                Icons.add_circle_outline_rounded,
                color: AppColors.primaryBrown,
              ),
              onPressed: _showStaffCreateOptions,
            ),
        ],
      ),
      floatingActionButton: isStaff
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primaryBrown,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Post Notice'),
              onPressed: _showStaffCreateOptions,
            )
          : null,
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: 720,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              const SizedBox(height: AppStyles.space12),

              // Staff Prominent Action Buttons
              if (isStaff) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppStyles.space16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'STAFF ACTIONS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // 1. Marriage Action
                          Expanded(
                            child: _buildStaffHeaderActionButton(
                              title: 'Marriage',
                              subtitle: 'Publish Banns',
                              icon: Icons.favorite_rounded,
                              color: AppColors.accentWine,
                              onTap: () => _openCreateDialog(AnnouncementType.marriage),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // 2. General Action
                          Expanded(
                            child: _buildStaffHeaderActionButton(
                              title: 'General',
                              subtitle: 'Church News',
                              icon: Icons.campaign_rounded,
                              color: AppColors.primaryBrown,
                              onTap: () => _openCreateDialog(AnnouncementType.general),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // 3. Special Action
                          Expanded(
                            child: _buildStaffHeaderActionButton(
                              title: 'Special',
                              subtitle: 'Celebration',
                              icon: Icons.star_rounded,
                              color: AppColors.mutedGoldDark,
                              onTap: () => _openCreateDialog(AnnouncementType.special),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppStyles.space12),
                    ],
                  ),
                ),
              ],

              // Search bar and Type Filter Chips
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppStyles.space16,
                ),
                child: Column(
                  children: [
                    // Search Input
                    TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        ref
                            .read(announcementSearchQueryProvider.notifier)
                            .setQuery(val);
                      },
                      decoration: InputDecoration(
                        hintText: 'Search notices, bride, groom, events...',
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppColors.primaryBrown,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  ref
                                      .read(
                                        announcementSearchQueryProvider.notifier,
                                      )
                                      .setQuery('');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: AppColors.cardSurface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: AppStyles.roundedLarge,
                          borderSide: const BorderSide(
                            color: AppColors.softBeige,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppStyles.roundedLarge,
                          borderSide: const BorderSide(
                            color: AppColors.softBeige,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AppStyles.roundedLarge,
                          borderSide: const BorderSide(
                            color: AppColors.primaryBrown,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppStyles.space12),

                    // Staff Publication Status Filter Chips (All / Published / Drafts)
                    if (isStaff) ...[
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip(
                              label: 'All Statuses',
                              isSelected: activeStatus == AnnouncementStatusFilter.all,
                              onTap: () => ref
                                  .read(announcementStatusFilterProvider.notifier)
                                  .setFilter(AnnouncementStatusFilter.all),
                            ),
                            const SizedBox(width: AppStyles.space8),
                            _buildFilterChip(
                              label: 'Published Only',
                              isSelected: activeStatus == AnnouncementStatusFilter.published,
                              badgeColor: AppColors.subtleOlive,
                              onTap: () => ref
                                  .read(announcementStatusFilterProvider.notifier)
                                  .setFilter(AnnouncementStatusFilter.published),
                            ),
                            const SizedBox(width: AppStyles.space8),
                            _buildFilterChip(
                              label: 'Drafts Only',
                              isSelected: activeStatus == AnnouncementStatusFilter.draft,
                              badgeColor: Colors.grey.shade600,
                              onTap: () => ref
                                  .read(announcementStatusFilterProvider.notifier)
                                  .setFilter(AnnouncementStatusFilter.draft),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppStyles.space8),
                    ],

                    // Announcement Type Chips Row (Replaces old Priority filter)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(
                            label: 'All Types',
                            isSelected: activeType == null,
                            onTap: () => ref
                                .read(announcementTypeFilterProvider.notifier)
                                .setType(null),
                          ),
                          const SizedBox(width: AppStyles.space8),
                          _buildFilterChip(
                            label: '💍 Marriage',
                            isSelected: activeType == AnnouncementType.marriage,
                            badgeColor: AppColors.accentWine,
                            onTap: () => ref
                                .read(announcementTypeFilterProvider.notifier)
                                .setType(AnnouncementType.marriage),
                          ),
                          const SizedBox(width: AppStyles.space8),
                          _buildFilterChip(
                            label: '📢 General',
                            isSelected: activeType == AnnouncementType.general,
                            badgeColor: AppColors.primaryBrown,
                            onTap: () => ref
                                .read(announcementTypeFilterProvider.notifier)
                                .setType(AnnouncementType.general),
                          ),
                          const SizedBox(width: AppStyles.space8),
                          _buildFilterChip(
                            label: '⭐ Special',
                            isSelected: activeType == AnnouncementType.special,
                            badgeColor: AppColors.mutedGoldDark,
                            onTap: () => ref
                                .read(announcementTypeFilterProvider.notifier)
                                .setType(AnnouncementType.special),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppStyles.space16),

              // Announcements List Feed
              Expanded(
                child: announcementsAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(
                        color: AppColors.primaryBrown,
                      ),
                    ),
                  ),
                  error: (error, _) => Center(
                    child: Padding(
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
                            'Failed to load announcements',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryBrown,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            error.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  data: (announcements) {
                    if (announcements.isEmpty) {
                      return _buildEmptyState(context, isStaff);
                    }

                    return RefreshIndicator(
                      color: AppColors.primaryBrown,
                      onRefresh: () async {
                        ref.invalidate(publishedAnnouncementsStreamProvider);
                        if (isStaff) {
                          ref.invalidate(allAnnouncementsStreamProvider);
                        }
                      },
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                          AppStyles.space16,
                          0,
                          AppStyles.space16,
                          AppStyles.space32,
                        ),
                        itemCount: announcements.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: AppStyles.space12),
                        itemBuilder: (context, index) {
                          final a = announcements[index];
                          return AnnouncementCard(
                            announcement: a,
                            isStaff: isStaff,
                            onTap: () {
                              context.push('/announcements/${a.id}', extra: a);
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStaffHeaderActionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppStyles.roundedMedium,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: AppStyles.roundedMedium,
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                color: AppColors.textSecondary.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppStyles.roundedMedium,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: AppStyles.roundedMedium,
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? badgeColor,
  }) {
    final activeColor = badgeColor ?? AppColors.primaryBrown;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : AppColors.cardSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.softBeige,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isStaff) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppStyles.space32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.campaign_outlined,
              size: 54,
              color: AppColors.mutedGoldDark,
            ),
            const SizedBox(height: AppStyles.space16),
            const Text(
              'No Announcements Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryBrown,
              ),
            ),
            const SizedBox(height: AppStyles.space8),
            const Text(
              'There are no active notices matching your filter.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            if (isStaff) ...[
              const SizedBox(height: AppStyles.space20),
              AppButton(
                label: 'Create Notice',
                icon: Icons.add_circle_outline_rounded,
                onPressed: _showStaffCreateOptions,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAuthRequiredView(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundIvory,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppStyles.space32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_person_outlined,
                size: 56,
                color: AppColors.primaryBrown,
              ),
              const SizedBox(height: AppStyles.space16),
              const Text(
                'Parish Access Required',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryBrown,
                ),
              ),
              const SizedBox(height: AppStyles.space8),
              const Text(
                'Please sign in to view CSI church notices and celebrations.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppStyles.space24),
              AppButton(
                label: 'Go to Sign In',
                icon: Icons.login_rounded,
                onPressed: () => context.go('/login'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingApprovalView(BuildContext context, AuthState auth) {
    return Scaffold(
      backgroundColor: AppColors.backgroundIvory,
      appBar: AppBar(title: const Text('Parish Announcements')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppStyles.space32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.hourglass_top_rounded,
                size: 56,
                color: AppColors.warningAmber,
              ),
              const SizedBox(height: AppStyles.space16),
              const Text(
                'Verification In Progress',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryBrown,
                ),
              ),
              const SizedBox(height: AppStyles.space8),
              Text(
                'Welcome, ${auth.fullName ?? "Church Member"}. Your registration is awaiting committee approval before accessing parish bulletins.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppStyles.space24),
              AppButton(
                label: 'View Application Status',
                icon: Icons.badge_outlined,
                onPressed: () => context.go('/pending-approval'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
