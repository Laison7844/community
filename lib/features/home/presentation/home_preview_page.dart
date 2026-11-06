import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_info_row.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../core/widgets/app_status_badge.dart';
import '../../../core/widgets/logout_confirmation_dialog.dart';
import '../../../core/widgets/member_avatar.dart';
import '../../../core/widgets/responsive_container.dart';
import '../../admin/providers/admin_provider.dart';
import '../../announcements/models/announcement.dart';
import '../../announcements/providers/announcement_provider.dart';
import '../../auth/models/auth_state.dart';
import '../../auth/providers/auth_provider.dart';
import '../../birthdays/providers/birthday_provider.dart';

/// Redesigned production-grade Home screen for CSI Church Community members.
///
/// Features an elegant church aesthetic, member greeting card, scripture banner,
/// quick-access grid, recent announcements preview, and celebrations summary.
class HomePreviewPage extends ConsumerStatefulWidget {
  const HomePreviewPage({super.key});

  @override
  ConsumerState<HomePreviewPage> createState() => _HomePreviewPageState();
}

class _HomePreviewPageState extends ConsumerState<HomePreviewPage> {
  int _currentNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final isStaff = ref.watch(isStaffUserProvider);
    final announcementsAsync = ref.watch(filteredAnnouncementsProvider);
    final currentWeekAsync = ref.watch(weekBulletinStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundIvory,
      appBar: _buildAppBar(context, auth, isStaff),
      bottomNavigationBar: _buildBottomNavigationBar(context, auth),
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: AppStyles.isDesktop(context) ? 1120 : (AppStyles.isTablet(context) ? 768 : 600),
          padding: const EdgeInsets.symmetric(horizontal: AppStyles.space16),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: AppStyles.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Member Welcome Card
                _buildMemberWelcomeCard(context, auth),
                const SizedBox(height: AppStyles.space16),

                // Staff Portal shortcut banner (for authorized staff)
                if (isStaff) ...[
                  _buildStaffManagementBanner(context, auth),
                  const SizedBox(height: AppStyles.space16),
                ],

                // 2. Today's Scripture Verse Card
                _buildTodaysVerseCard(context),
                const SizedBox(height: AppStyles.space20),

                // 3. Quick Access 6-Feature Grid
                _buildQuickAccessSection(context),
                const SizedBox(height: AppStyles.space24),

                // 4. Desktop dual-column vs Mobile/Tablet stacked layout
                if (AppStyles.isDesktop(context))
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 6,
                        child: _buildRecentAnnouncementsSection(context, announcementsAsync),
                      ),
                      const SizedBox(width: AppStyles.space24),
                      Expanded(
                        flex: 5,
                        child: _buildUpcomingCelebrationsSection(context, currentWeekAsync),
                      ),
                    ],
                  )
                else ...[
                  // 4. Recent Announcements Section
                  _buildRecentAnnouncementsSection(context, announcementsAsync),
                  const SizedBox(height: AppStyles.space24),

                  // 5. Upcoming Celebrations Section
                  _buildUpcomingCelebrationsSection(context, currentWeekAsync),
                ],
                const SizedBox(height: AppStyles.space32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===============================================================
  // A. App Header Bar
  // ===============================================================
  PreferredSizeWidget _buildAppBar(BuildContext context, AuthState auth, bool isStaff) {
    return AppBar(
      backgroundColor: AppColors.backgroundIvory,
      elevation: 0,
      scrolledUnderElevation: 1.0,
      centerTitle: false,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppLogo(size: 34),
          const SizedBox(width: AppStyles.space10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'CSI Church',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.primaryBrown,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                      height: 1.1,
                    ),
              ),
              Text(
                'Community',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.mutedGoldDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      letterSpacing: 0.4,
                      height: 1.1,
                    ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Notification bell with unread indicator dot
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              tooltip: 'Notifications',
              icon: const Icon(
                Icons.notifications_outlined,
                color: AppColors.primaryBrown,
                size: 24,
              ),
              onPressed: () => _showNotificationSheet(context),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.errorRed,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),

        // Profile Avatar button
        Padding(
          padding: const EdgeInsets.only(right: AppStyles.space12, left: AppStyles.space4),
          child: InkWell(
            onTap: () => _showProfileSheet(context, auth),
            borderRadius: BorderRadius.circular(AppStyles.radiusFull),
            child: MemberAvatar(
              imageUrl: auth.profile?.profileImageUrl,
              radius: 17,
              backgroundColor: AppColors.surfaceCream,
              iconColor: AppColors.mutedGold,
              border: Border.all(color: AppColors.mutedGold, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  // ===============================================================
  // B. Member Welcome Card
  // ===============================================================
  Widget _buildMemberWelcomeCard(BuildContext context, AuthState auth) {
    final memberName = auth.fullName ?? 'Church Member';
    final familyNo = auth.profile?.familyNumber;

    return Container(
      decoration: BoxDecoration(
        borderRadius: AppStyles.roundedLarge,
        border: Border.all(color: AppColors.mutedGold.withValues(alpha: 0.35), width: 1.2),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFDF8),
            Color(0xFFF7EFE2),
          ],
        ),
        boxShadow: AppStyles.elevation1,
      ),
      child: ClipRRect(
        borderRadius: AppStyles.roundedLarge,
        child: Padding(
          padding: const EdgeInsets.all(AppStyles.space16),
          child: Row(
            children: [
              // Member Avatar with elegant gold ring
              MemberAvatar(
                imageUrl: auth.profile?.profileImageUrl,
                radius: 28,
                backgroundColor: AppColors.surfaceCream,
                iconColor: AppColors.mutedGold,
                border: Border.all(color: AppColors.mutedGold, width: 2.0),
              ),
              const SizedBox(width: AppStyles.space14),

              // Greeting, Name, and Status Badges
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Peace be with you,',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mutedGoldDark,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      memberName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryBrown,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: AppStyles.space8,
                      runSpacing: 4,
                      children: [
                        const AppStatusBadge(
                          label: 'Approved Member',
                          type: AppStatusType.approved,
                          showDot: true,
                          isCompact: true,
                        ),
                        if (familyNo != null && familyNo.isNotEmpty)
                          Text(
                            'Family No: $familyNo',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
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

  // ===============================================================
  // Staff Portal Access Banner (For Admin / Committee / Pastor)
  // ===============================================================
  Widget _buildStaffManagementBanner(BuildContext context, AuthState auth) {
    final staffRole = (auth.profile?.role ?? 'Staff').toUpperCase();

    return AppCard(
      color: AppColors.surfaceCream,
      padding: const EdgeInsets.symmetric(horizontal: AppStyles.space14, vertical: AppStyles.space10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppStyles.space8),
            decoration: BoxDecoration(
              color: AppColors.mutedGold.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: AppColors.primaryBrown,
              size: 20,
            ),
          ),
          const SizedBox(width: AppStyles.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Staff Portal ($staffRole)',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.primaryBrown,
                  ),
                ),
                const Text(
                  'Manage members, notices & parish register',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          AppButton(
            label: 'Open',
            size: AppButtonSize.compact,
            width: null,
            onPressed: () => context.go('/admin'),
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // C. Today's Verse Card
  // ===============================================================
  Widget _buildTodaysVerseCard(BuildContext context) {
    return AppCard(
      variant: AppCardVariant.subtle,
      padding: const EdgeInsets.all(AppStyles.space16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.menu_book_rounded,
                      size: 17,
                      color: AppColors.primaryBrown,
                    ),
                    const SizedBox(width: AppStyles.space8),
                    Text(
                      "Today's Verse",
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.primaryBrown,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: AppStyles.space8),
                Text(
                  AppStrings.dailyVerse,
                  style: const TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textPrimary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: AppStyles.space8),
                Text(
                  AppStrings.dailyVerseRef,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mutedGoldDark,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppStyles.space12),
          // Subtle decorative graphic
          Container(
            padding: const EdgeInsets.all(AppStyles.space12),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderDefault, width: 1.0),
              boxShadow: AppStyles.elevation1,
            ),
            child: const Icon(
              Icons.auto_stories_rounded,
              color: AppColors.mutedGold,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // D. Quick Access 6-Feature Section
  // ===============================================================
  Widget _buildQuickAccessSection(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.sizeOf(context).width;
        final int crossAxisCount;
        final double childAspectRatio;
        final double crossAxisSpacing;
        final double mainAxisSpacing;

        if (screenWidth < 600) {
          // Mobile (below 600px): 2 columns, comfortable card spacing, no text overflow
          crossAxisCount = 2;
          childAspectRatio = 1.35;
          crossAxisSpacing = AppStyles.space10;
          mainAxisSpacing = AppStyles.space10;
        } else if (screenWidth <= 1024) {
          // Tablet (600–1024px): 3 columns, balanced card dimensions
          crossAxisCount = 3;
          childAspectRatio = 1.35;
          crossAxisSpacing = AppStyles.space12;
          mainAxisSpacing = AppStyles.space12;
        } else {
          // Desktop (above 1024px): 6 cards in one row, consistent dimensions
          crossAxisCount = 6;
          childAspectRatio = 1.15;
          crossAxisSpacing = AppStyles.space12;
          mainAxisSpacing = AppStyles.space12;
        }

        final items = [
          _QuickAccessItem(
            title: 'Announcements',
            icon: Icons.campaign_rounded,
            color: AppColors.primaryBrown,
            backgroundColor: AppColors.primaryBrown.withValues(alpha: 0.10),
            onTap: () => context.push('/announcements'),
          ),
          _QuickAccessItem(
            title: 'Celebrations',
            icon: Icons.cake_rounded,
            color: AppColors.accentBurgundy,
            backgroundColor: AppColors.accentBurgundy.withValues(alpha: 0.10),
            onTap: () => context.push('/birthdays-anniversaries'),
          ),
          _QuickAccessItem(
            title: 'Events',
            icon: Icons.calendar_month_rounded,
            color: AppColors.warningAmber,
            backgroundColor: AppColors.warningAmber.withValues(alpha: 0.12),
            onTap: () => _showComingSoonSnackBar(context, 'Events & Calendar'),
          ),
          _QuickAccessItem(
            title: 'Prayer\nRequests',
            icon: Icons.volunteer_activism_rounded,
            color: AppColors.mutedGoldDark,
            backgroundColor: AppColors.mutedGold.withValues(alpha: 0.15),
            onTap: () => _showComingSoonSnackBar(context, 'Prayer Requests'),
          ),
          _QuickAccessItem(
            title: 'Documents',
            icon: Icons.description_rounded,
            color: const Color(0xFF556B2F),
            backgroundColor: AppColors.oliveLight,
            onTap: () => _showComingSoonSnackBar(context, 'Church Documents'),
          ),
          _QuickAccessItem(
            title: 'Church\nInformation',
            icon: Icons.info_outline_rounded,
            color: AppColors.primaryBrownLight,
            backgroundColor: AppColors.surfaceCream,
            onTap: () => _showComingSoonSnackBar(context, 'Church Information'),
          ),
        ];

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: crossAxisSpacing,
            mainAxisSpacing: mainAxisSpacing,
            childAspectRatio: childAspectRatio,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return InkWell(
              onTap: item.onTap,
              borderRadius: AppStyles.roundedLarge,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: AppStyles.roundedLarge,
                  border: Border.all(color: AppColors.borderDefault, width: 1.0),
                  boxShadow: AppStyles.elevation1,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: item.backgroundColor,
                        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                      ),
                      child: Icon(item.icon, color: item.color, size: 22),
                    ),
                    const SizedBox(height: AppStyles.space8),
                    Text(
                      item.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ===============================================================
  // E. Recent Announcements Section
  // ===============================================================
  Widget _buildRecentAnnouncementsSection(
    BuildContext context,
    AsyncValue<List<Announcement>> announcementsAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: 'Recent Announcements',
          action: InkWell(
            onTap: () => context.push('/announcements'),
            borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'See All',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentBurgundy,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: AppColors.accentBurgundy,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppStyles.space4),
        announcementsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(AppStyles.space20),
              child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.primaryBrown),
            ),
          ),
          error: (err, _) => AppCard(
            color: AppColors.surfaceCream,
            child: Text(
              'Could not load announcements: $err',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          data: (list) {
            if (list.isEmpty) {
              return const AppEmptyState(
                icon: Icons.campaign_outlined,
                title: 'No Notices Posted',
                message: 'Recent parish announcements and marriage notices will appear here.',
                padding: EdgeInsets.all(AppStyles.space20),
              );
            }

            // Show top 2 most recent notices
            final previews = list.take(2).toList();
            return Column(
              children: previews.map((a) => _buildAnnouncementPreviewCard(context, a)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAnnouncementPreviewCard(BuildContext context, Announcement a) {
    final dateStr = a.createdAt != null
        ? DateFormat('EEE, d MMM y').format(a.createdAt!)
        : 'Recent Notice';

    // Format type badge and icons
    String badgeLabel = 'General';
    Color badgeColor = AppColors.primaryBrown;
    Color badgeBg = AppColors.surfaceCream;
    IconData badgeIcon = Icons.campaign_rounded;

    if (a.announcementType == AnnouncementType.marriage) {
      badgeLabel = 'Marriage';
      badgeColor = AppColors.accentBurgundy;
      badgeBg = AppColors.accentBurgundyLight;
      badgeIcon = Icons.favorite_rounded;
    } else if (a.announcementType == AnnouncementType.special) {
      badgeLabel = 'Special';
      badgeColor = AppColors.mutedGoldDark;
      badgeBg = AppColors.statusDraftBg;
      badgeIcon = Icons.celebration_rounded;
    }

    final rawImageUrl = a.imageUrl?.trim() ?? '';
    final lower = rawImageUrl.toLowerCase();
    final isDisallowed = lower.contains('pikachu') ||
        lower.contains('pokemon') ||
        lower.contains('avatar_placeholder') ||
        lower.contains('cartoon');
    final uri = Uri.tryParse(rawImageUrl);
    final hasValidImage = rawImageUrl.isNotEmpty &&
        uri != null &&
        (uri.isScheme('http') || uri.isScheme('https')) &&
        uri.host.isNotEmpty &&
        !isDisallowed;

    final String subtitle = a.announcementType == AnnouncementType.marriage &&
            a.brideName != null &&
            a.groomName != null
        ? '${a.brideName} & ${a.groomName}'
        : (a.description.isNotEmpty ? a.description : 'Tap to read full announcement details.');

    return Padding(
      padding: const EdgeInsets.only(bottom: AppStyles.space10),
      child: AppCard(
        padding: EdgeInsets.zero,
        onTap: () => context.push('/announcements/${a.id}', extra: a),
        child: Padding(
          padding: const EdgeInsets.all(AppStyles.space12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left graphic / image container
              ClipRRect(
                borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
                    border: Border.all(
                      color: badgeColor.withValues(alpha: 0.20),
                      width: 1.0,
                    ),
                  ),
                  child: hasValidImage
                      ? Image.network(
                          rawImageUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Center(child: Icon(badgeIcon, color: badgeColor, size: 28)),
                        )
                      : Center(child: Icon(badgeIcon, color: badgeColor, size: 28)),
                ),
              ),
              const SizedBox(width: AppStyles.space12),

              // Title, Subtitle, and Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
                        border: Border.all(color: badgeColor.withValues(alpha: 0.3), width: 0.8),
                      ),
                      child: Text(
                        badgeLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: badgeColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      a.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryBrown,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 11,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            dateStr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textLight),
            ],
          ),
        ),
      ),
    );
  }

  // ===============================================================
  // F. Upcoming Celebrations Section
  // ===============================================================
  Widget _buildUpcomingCelebrationsSection(
    BuildContext context,
    AsyncValue<dynamic> currentWeekAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: 'Upcoming Celebrations',
          action: InkWell(
            onTap: () => context.push('/birthdays-anniversaries'),
            borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'See All',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentBurgundy,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: AppColors.accentBurgundy,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppStyles.space4),
        currentWeekAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(AppStyles.space16),
              child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.primaryBrown),
            ),
          ),
          error: (err, _) => AppCard(
            color: AppColors.surfaceCream,
            child: Text(
              'Could not load celebrations: $err',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          data: (week) {
            if (week == null) {
              return const AppEmptyState(
                icon: Icons.cake_outlined,
                title: 'No Celebrations Published',
                message: 'Parish birthdays and anniversaries will be displayed once the weekly bulletin is published.',
                padding: EdgeInsets.all(AppStyles.space20),
              );
            }

            final birthdays = week.birthdays;
            final anniversaries = week.anniversaries;
            final int bdayCount = birthdays.length;
            final int annivCount = anniversaries.length;

            if (bdayCount == 0 && annivCount == 0) {
              return const AppEmptyState(
                icon: Icons.cake_outlined,
                title: 'No Celebrations This Week',
                message: 'There are no parish birthdays or wedding anniversaries registered for this week.',
                padding: EdgeInsets.all(AppStyles.space20),
              );
            }

            return AppCard(
              variant: AppCardVariant.goldAccent,
              padding: const EdgeInsets.all(AppStyles.space16),
              onTap: () => context.push('/birthdays-anniversaries'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.mutedGold.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.celebration_rounded,
                          color: AppColors.mutedGoldDark,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: AppStyles.space12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'This Week in Fellowship',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryBrown,
                              ),
                            ),
                            Text(
                              '$bdayCount Birthdays • $annivCount Wedding Anniversaries',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, size: 22, color: AppColors.primaryBrown),
                    ],
                  ),
                  if (birthdays.isNotEmpty || anniversaries.isNotEmpty) ...[
                    const Divider(height: AppStyles.space20, color: AppColors.borderSubtle),
                    // Compact preview list of first 2 individuals/couples
                    if (birthdays.isNotEmpty)
                      _buildCompactCelebrantRow(
                        icon: Icons.cake_rounded,
                        color: AppColors.primaryBrown,
                        name: birthdays.first.memberName,
                        eventLabel: DateFormat('EEE, d MMM').format(birthdays.first.eventDate),
                      ),
                    if (anniversaries.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _buildCompactCelebrantRow(
                        icon: Icons.favorite_rounded,
                        color: AppColors.accentBurgundy,
                        name: anniversaries.first.coupleName,
                        eventLabel: DateFormat('EEE, d MMM').format(anniversaries.first.eventDate),
                      ),
                    ],
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCompactCelebrantRow({
    required IconData icon,
    required Color color,
    required String name,
    required String eventLabel,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: AppStyles.space8),
        Expanded(
          flex: 3,
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: AppStyles.space8),
        Flexible(
          flex: 2,
          child: Text(
            eventLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  // ===============================================================
  // G. Polished Bottom Navigation Bar
  // ===============================================================
  Widget _buildBottomNavigationBar(BuildContext context, AuthState auth) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardSurface,
        border: Border(
          top: BorderSide(color: AppColors.borderDefault, width: 1.0),
        ),
        boxShadow: AppStyles.elevation1,
      ),
      child: NavigationBar(
        selectedIndex: _currentNavIndex,
        backgroundColor: AppColors.cardSurface,
        indicatorColor: AppColors.mutedGold.withValues(alpha: 0.22),
        elevation: 0,
        height: 64,
        onDestinationSelected: (index) {
          setState(() {
            _currentNavIndex = index;
          });

          switch (index) {
            case 0:
              // Home
              break;
            case 1:
              // Community
              _showComingSoonSnackBar(context, 'Parish Community Directory');
              break;
            case 2:
              // Celebrations
              context.push('/birthdays-anniversaries');
              break;
            case 3:
              // Notices
              context.push('/announcements');
              break;
            case 4:
              // Profile
              _showProfileSheet(context, auth);
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: AppColors.textSecondary),
            selectedIcon: Icon(Icons.home_rounded, color: AppColors.primaryBrown),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined, color: AppColors.textSecondary),
            selectedIcon: Icon(Icons.groups_rounded, color: AppColors.primaryBrown),
            label: 'Community',
          ),
          NavigationDestination(
            icon: Icon(Icons.cake_outlined, color: AppColors.textSecondary),
            selectedIcon: Icon(Icons.cake_rounded, color: AppColors.accentBurgundy),
            label: 'Celebrations',
          ),
          NavigationDestination(
            icon: Icon(Icons.campaign_outlined, color: AppColors.textSecondary),
            selectedIcon: Icon(Icons.campaign_rounded, color: AppColors.primaryBrown),
            label: 'Notices',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded, color: AppColors.textSecondary),
            selectedIcon: Icon(Icons.person_rounded, color: AppColors.primaryBrown),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // Helper Modals & Actions
  // ===============================================================
  void _showComingSoonSnackBar(BuildContext context, String featureName) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$featureName will be available in the upcoming parish update.'),
        backgroundColor: AppColors.primaryBrown,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showNotificationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppStyles.radiusXLarge)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppStyles.space20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceCream,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_active_rounded, color: AppColors.primaryBrown),
                  ),
                  const SizedBox(width: AppStyles.space12),
                  const Expanded(
                    child: Text(
                      'Church Notifications',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryBrown,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(height: AppStyles.space20),
              const Text(
                'You are subscribed to daily morning celebration reminders and church announcements.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: AppStyles.space16),
              AppButton(
                label: 'Close',
                size: AppButtonSize.regular,
                variant: AppButtonVariant.outline,
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProfileSheet(BuildContext context, AuthState auth) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppStyles.radiusXLarge)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppStyles.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MemberAvatar(
                imageUrl: auth.profile?.profileImageUrl,
                radius: 36,
                backgroundColor: AppColors.surfaceCream,
                iconColor: AppColors.mutedGold,
                border: Border.all(color: AppColors.mutedGold, width: 2),
              ),
              const SizedBox(height: AppStyles.space12),
              Text(
                auth.fullName ?? 'Church Member',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryBrown,
                ),
              ),
              const SizedBox(height: 4),
              const AppStatusBadge(
                label: 'Approved Member',
                type: AppStatusType.approved,
                showDot: true,
                isCompact: true,
              ),
              const SizedBox(height: AppStyles.space20),
              AppInfoRow(
                icon: Icons.groups_outlined,
                label: 'Family Number',
                value: auth.profile?.familyNumber ?? '—',
                showDivider: true,
              ),
              AppInfoRow(
                icon: Icons.email_outlined,
                label: 'Email',
                value: auth.email ?? '—',
                showDivider: true,
              ),
              if (auth.profile?.phone != null && auth.profile!.phone!.isNotEmpty)
                AppInfoRow(
                  icon: Icons.phone_outlined,
                  label: 'Phone',
                  value: auth.profile!.phone!,
                  showDivider: true,
                ),
              AppInfoRow(
                icon: Icons.shield_outlined,
                label: 'Parish Role',
                value: (auth.profile?.role ?? 'Member').toUpperCase(),
                showDivider: true,
              ),
              const SizedBox(height: AppStyles.space24),
              AppButton(
                label: 'Sign Out',
                icon: Icons.logout_rounded,
                variant: AppButtonVariant.destructive,
                size: AppButtonSize.regular,
                onPressed: () {
                  Navigator.pop(ctx);
                  showLogoutConfirmationDialog(context, ref);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAccessItem {
  final String title;
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _QuickAccessItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.onTap,
  });
}
