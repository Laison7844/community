import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/responsive_container.dart';
import '../../admin/providers/admin_provider.dart';
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

  void _openCreateDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AnnouncementFormDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isStaff = ref.watch(isStaffUserProvider);
    final announcementsAsync = ref.watch(filteredAnnouncementsProvider);
    final activePriority = ref.watch(announcementPriorityFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundIvory,
      appBar: AppBar(
        title: const Text('Parish Announcements'),
        actions: [
          if (isStaff)
            IconButton(
              tooltip: 'Post New Announcement',
              icon: const Icon(
                Icons.add_circle_outline_rounded,
                color: AppColors.primaryBrown,
              ),
              onPressed: _openCreateDialog,
            ),
        ],
      ),
      floatingActionButton: isStaff
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primaryBrown,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.campaign_rounded),
              label: const Text('Post Notice'),
              onPressed: _openCreateDialog,
            )
          : null,
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: 900,
          child: Column(
            children: [
              const SizedBox(height: AppStyles.space12),

              // Search bar and Priority Filter Chips
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
                        hintText: 'Search parish announcements...',
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

                    // Priority Chips Row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(
                            label: 'All Notices',
                            isSelected: activePriority == null,
                            onTap: () => ref
                                .read(
                                  announcementPriorityFilterProvider.notifier,
                                )
                                .setPriority(null),
                          ),
                          const SizedBox(width: AppStyles.space8),
                          _buildFilterChip(
                            label: 'Urgent',
                            isSelected:
                                activePriority == AnnouncementPriority.urgent,
                            badgeColor: AppColors.errorRed,
                            onTap: () => ref
                                .read(
                                  announcementPriorityFilterProvider.notifier,
                                )
                                .setPriority(AnnouncementPriority.urgent),
                          ),
                          const SizedBox(width: AppStyles.space8),
                          _buildFilterChip(
                            label: 'High Priority',
                            isSelected:
                                activePriority == AnnouncementPriority.high,
                            badgeColor: AppColors.warningAmber,
                            onTap: () => ref
                                .read(
                                  announcementPriorityFilterProvider.notifier,
                                )
                                .setPriority(AnnouncementPriority.high),
                          ),
                          const SizedBox(width: AppStyles.space8),
                          _buildFilterChip(
                            label: 'General',
                            isSelected:
                                activePriority == AnnouncementPriority.normal,
                            badgeColor: AppColors.primaryBrown,
                            onTap: () => ref
                                .read(
                                  announcementPriorityFilterProvider.notifier,
                                )
                                .setPriority(AnnouncementPriority.normal),
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
                  error: (err, _) => Center(
                    child: AppCard(
                      margin: const EdgeInsets.all(AppStyles.space16),
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
                              isStaff
                                  ? allAnnouncementsStreamProvider
                                  : publishedAnnouncementsStreamProvider,
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  data: (announcements) {
                    if (announcements.isEmpty) {
                      return _buildEmptyState(isStaff);
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppStyles.space16,
                        vertical: AppStyles.space8,
                      ),
                      itemCount: announcements.length,
                      separatorBuilder: (_, index) =>
                          const SizedBox(height: AppStyles.space16),
                      itemBuilder: (context, index) {
                        final announcement = announcements[index];
                        return AnnouncementCard(
                          announcement: announcement,
                          isStaff: isStaff,
                          onTap: () => context.push(
                            '/announcements/${announcement.id}',
                            extra: announcement,
                          ),
                        );
                      },
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

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? badgeColor,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primaryBrown,
      backgroundColor: AppColors.cardSurface,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? Colors.white : AppColors.textPrimary,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primaryBrown : AppColors.softBeige,
      ),
      avatar: badgeColor != null
          ? CircleAvatar(radius: 4, backgroundColor: badgeColor)
          : null,
    );
  }

  Widget _buildEmptyState(bool isStaff) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppStyles.space32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.surfaceCream,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.campaign_outlined,
                color: AppColors.mutedGold,
                size: 48,
              ),
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
            Text(
              isStaff
                  ? 'No announcements match your search or filter. Tap "Post Notice" to create one.'
                  : 'There are currently no published announcements for the parish.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            if (isStaff) ...[
              const SizedBox(height: AppStyles.space20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBrown,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Post First Announcement'),
                onPressed: _openCreateDialog,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
