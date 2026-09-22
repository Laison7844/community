import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/responsive_container.dart';
import '../../admin/providers/admin_provider.dart';
import '../../auth/providers/auth_provider.dart';

/// Temporary landing page for verified church members in Phase 1.
///
/// Demonstrates successful navigation for approved accounts before Phase 4 dashboard build.
class HomePreviewPage extends ConsumerWidget {
  const HomePreviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final isStaff = ref.watch(isStaffUserProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundIvory,
      appBar: AppBar(
        title: Text(
          AppStrings.churchName,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.primaryBrown,
                fontWeight: FontWeight.w700,
              ),
        ),
        actions: [
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
            onPressed: () async {
              await ref.read(authProvider.notifier).signOut();
              if (context.mounted) {
                context.go('/welcome');
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: AppStyles.maxDashboardWidth,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: AppStyles.space20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Banner Card
                AppCard(
                  color: AppColors.primaryBrown,
                  child: Row(
                    children: [
                      const AppLogo(
                        size: 56,
                        circleColor: AppColors.primaryBrownDark,
                        crossColor: AppColors.mutedGold,
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
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: AppStyles.space4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.subtleOlive,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Approved Member',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isStaff) ...[
                  const SizedBox(height: AppStyles.space20),
                  AppCard(
                    color: AppColors.surfaceCream,
                    padding: const EdgeInsets.all(AppStyles.space16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.mutedGold.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.how_to_reg_rounded,
                            color: AppColors.primaryBrown,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: AppStyles.space16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Committee Verification Portal',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: AppColors.primaryBrown,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Review pending member registrations, compare with parish register, and record verification audit logs.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textPrimary.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppStyles.space12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBrown,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.dashboard_outlined, size: 16),
                          label: const Text('Open Portal'),
                          onPressed: () => context.go('/admin'),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppStyles.space24),

                // Phase 1 verification card
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.successGreenLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.successGreen,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: AppStyles.space12),
                          Text(
                            'Phase 1 Architecture Active',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppStyles.space16),
                      Text(
                        'Riverpod state management, Material 3 church theme, responsive layout, and authentication navigation are fully active.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppStyles.space12),
                      Text(
                        'Next: Phase 2 will connect live Firebase Authentication and Firestore Member Profiles.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppStyles.space24),

                // Scripture highlight
                AppCard(
                  color: AppColors.surfaceCream,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        AppStrings.dailyVerse,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: AppColors.primaryBrown,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const SizedBox(height: AppStyles.space8),
                      Text(
                        AppStrings.dailyVerseRef,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.mutedGoldDark,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppStyles.space32),

                // Sign Out Action
                Center(
                  child: SizedBox(
                    width: 220,
                    child: AppButton(
                      label: AppStrings.logout,
                      icon: Icons.logout_rounded,
                      variant: AppButtonVariant.outline,
                      onPressed: () async {
                        await ref.read(authProvider.notifier).signOut();
                        if (context.mounted) {
                          context.go('/welcome');
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
