import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/logout_confirmation_dialog.dart';
import '../../../core/widgets/member_avatar.dart';
import '../../../core/widgets/responsive_container.dart';
import '../../admin/providers/admin_provider.dart';
import '../../announcements/providers/announcement_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../birthdays/providers/birthday_provider.dart';

/// Production-ready mobile-first Home screen for CSI Church Community members.
class HomePreviewPage extends ConsumerWidget {
  const HomePreviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final isStaff = ref.watch(isStaffUserProvider);
    final announcementsAsync = ref.watch(filteredAnnouncementsProvider);
    final currentWeekAsync = ref.watch(weekBulletinStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundIvory,
      appBar: AppBar(
        title: Text(
          AppStrings.churchName,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.primaryBrown,
                fontWeight: FontWeight.w700,
              ),
        ),
        actions: [
          IconButton(
            tooltip: 'Parish Announcements',
            icon: const Icon(Icons.campaign_outlined,
                color: AppColors.primaryBrown),
            onPressed: () => context.push('/announcements'),
          ),
          IconButton(
            tooltip: 'Birthdays & Anniversaries',
            icon: const Icon(Icons.cake_outlined,
                color: AppColors.primaryBrown),
            onPressed: () => context.push('/birthdays-anniversaries'),
          ),
          if (isStaff)
            IconButton(
              tooltip: 'Committee Dashboard',
              icon: const Icon(Icons.admin_panel_settings_rounded,
                  color: AppColors.primaryBrown),
              onPressed: () => context.go('/admin'),
            ),
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => showLogoutConfirmationDialog(context, ref),
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: 650,
          padding: const EdgeInsets.symmetric(horizontal: AppStyles.space16),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: AppStyles.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Compact Member Greeting Card
                _buildMemberGreeting(context, auth),
                const SizedBox(height: AppStyles.space16),

                // 2. Staff Management Portal (if authorized staff)
                if (isStaff) ...[
                  _buildStaffCard(context),
                  const SizedBox(height: AppStyles.space16),
                ],

                // 3. Parish Announcements Shortcut & Highlights
                _buildAnnouncementsCard(context, announcementsAsync),
                const SizedBox(height: AppStyles.space16),

                // 4. Phase 5: Birthdays & Anniversaries Card
                _buildBirthdaysCard(context, currentWeekAsync),
                const SizedBox(height: AppStyles.space20),

                // 5. Daily Scripture Verse Card
                _buildScriptureCard(context),
                const SizedBox(height: AppStyles.space28),

                // 6. Sign Out
                Center(
                  child: SizedBox(
                    width: 200,
                    child: AppButton(
                      label: AppStrings.logout,
                      icon: Icons.logout_rounded,
                      variant: AppButtonVariant.outline,
                      onPressed: () => showLogoutConfirmationDialog(context, ref),
                    ),
                  ),
                ),
                const SizedBox(height: AppStyles.space20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMemberGreeting(BuildContext context, dynamic auth) {
    return AppCard(
      color: AppColors.primaryBrown,
      padding: const EdgeInsets.all(AppStyles.space16),
      child: Row(
        children: [
          MemberAvatar(
            imageUrl: auth.profile?.profileImageUrl,
            radius: 26,
            backgroundColor: AppColors.primaryBrownDark,
            iconColor: AppColors.mutedGold,
            border: Border.all(color: AppColors.mutedGold, width: 2),
          ),
          const SizedBox(width: AppStyles.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Peace be with you,',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedGoldLight,
                      ),
                ),
                Text(
                  auth.fullName ?? 'Church Member',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppStyles.space4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.subtleOlive,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Approved Member',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (auth.profile?.familyNumber != null &&
                        auth.profile!.familyNumber.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        'Family: ${auth.profile!.familyNumber}',
                        style: const TextStyle(
                          color: AppColors.mutedGoldLight,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsCard(
      BuildContext context, AsyncValue<dynamic> announcementsAsync) {
    return AppCard(
      color: AppColors.cardSurface,
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () => context.push('/announcements'),
        borderRadius: AppStyles.roundedLarge,
        child: Padding(
          padding: const EdgeInsets.all(AppStyles.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBrown.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.campaign_rounded,
                      color: AppColors.primaryBrown,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppStyles.space12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Parish Announcements',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.primaryBrown,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Official notices, service bulletins & prayer requests',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.primaryBrown,
                    size: 22,
                  ),
                ],
              ),
              announcementsAsync.when(
                data: (list) {
                  if (list == null || (list is List && list.isEmpty)) {
                    return const SizedBox.shrink();
                  }
                  final first = list.first;
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCream,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.fiber_new_rounded,
                              size: 16, color: AppColors.mutedGoldDark),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              first.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryBrown,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBirthdaysCard(
      BuildContext context, AsyncValue<dynamic> currentWeekAsync) {
    return AppCard(
      color: AppColors.cardSurface,
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () => context.push('/birthdays-anniversaries'),
        borderRadius: AppStyles.roundedLarge,
        child: Padding(
          padding: const EdgeInsets.all(AppStyles.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accentWine.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.cake_rounded,
                      color: AppColors.accentWine,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppStyles.space12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Birthdays & Anniversaries',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.primaryBrown,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Weekly parish celebrations, reminders & wishes',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.primaryBrown,
                    size: 22,
                  ),
                ],
              ),
              currentWeekAsync.when(
                data: (week) {
                  if (week == null) return const SizedBox.shrink();
                  final bdayCount = week.birthdays.length;
                  final annivCount = week.anniversaries.length;
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCream,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.celebration_rounded,
                              size: 16, color: AppColors.accentWine),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'This week: $bdayCount Birthdays • $annivCount Anniversaries',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryBrown,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStaffCard(BuildContext context) {
    return AppCard(
      color: AppColors.surfaceCream,
      padding: const EdgeInsets.all(AppStyles.space12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.mutedGold.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: AppColors.primaryBrown,
              size: 22,
            ),
          ),
          const SizedBox(width: AppStyles.space12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Committee Dashboard',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.primaryBrown,
                  ),
                ),
                Text(
                  'Member verification & parish register',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBrown,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => context.go('/admin'),
            child: const Text('Open', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildScriptureCard(BuildContext context) {
    return AppCard(
      color: AppColors.surfaceCream,
      padding: const EdgeInsets.all(AppStyles.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            AppStrings.dailyVerse,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: AppColors.primaryBrown,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: AppStyles.space8),
          Text(
            AppStrings.dailyVerseRef,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.mutedGoldDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
          ),
        ],
      ),
    );
  }
}
