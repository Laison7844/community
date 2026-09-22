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
import '../models/auth_state.dart';
import '../providers/auth_provider.dart';

/// Screen displayed when a church member's account is pending committee verification.
class PendingApprovalPage extends ConsumerWidget {
  const PendingApprovalPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundIvory,
      body: SafeArea(
        child: ResponsiveContainer(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppStyles.space32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: AppStyles.space20),
                  const AppLogo(size: 72),
                  const SizedBox(height: AppStyles.space32),

                  // Pending status emblem
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: AppColors.warningAmberLight,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.warningAmber.withValues(alpha: 0.4),
                        width: 2.0,
                      ),
                    ),
                    child: const Icon(
                      Icons.hourglass_top_rounded,
                      color: AppColors.warningAmber,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: AppStyles.space24),

                  // Title & Friendly Message
                  Text(
                    AppStrings.pendingApprovalTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppStyles.space12),
                  Text(
                    AppStrings.pendingApprovalMessage,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                        ),
                  ),
                  const SizedBox(height: AppStyles.space28),

                  // Member details summary card
                  AppCard(
                    color: AppColors.surfaceCream,
                    padding: const EdgeInsets.all(AppStyles.space20),
                    child: Column(
                      children: [
                        if (auth.profile?.profileImageUrl != null &&
                            auth.profile!.profileImageUrl.isNotEmpty) ...[
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: AppColors.softBeige,
                            backgroundImage:
                                NetworkImage(auth.profile!.profileImageUrl),
                          ),
                          const SizedBox(height: AppStyles.space16),
                        ],
                        _buildDetailRow(
                          context,
                          icon: Icons.person_outline_rounded,
                          label: 'Applicant',
                          value: auth.fullName ?? 'Registered Member',
                        ),
                        if (auth.profile?.familyNumber != null &&
                            auth.profile!.familyNumber.isNotEmpty) ...[
                          const Divider(height: AppStyles.space24),
                          _buildDetailRow(
                            context,
                            icon: Icons.groups_outlined,
                            label: 'Family No.',
                            value: auth.profile!.familyNumber,
                          ),
                        ],
                        const Divider(height: AppStyles.space24),
                        _buildDetailRow(
                          context,
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: auth.email ?? '—',
                        ),
                        const Divider(height: AppStyles.space24),
                        _buildDetailRow(
                          context,
                          icon: Icons.verified_outlined,
                          label: 'Current Status',
                          value: 'Pending Committee Review',
                          valueColor: AppColors.warningAmber,
                          isBold: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppStyles.space20),

                  // Reassurance note
                  Text(
                    AppStrings.pendingNotice,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textLight,
                          height: 1.4,
                        ),
                  ),
                  const SizedBox(height: AppStyles.space32),

                  // Refresh Button
                  AppButton(
                    label: AppStrings.refreshStatus,
                    icon: Icons.refresh_rounded,
                    isLoading: auth.isLoading,
                    onPressed: () async {
                      final newStatus =
                          await ref.read(authProvider.notifier).refreshStatus();
                      if (context.mounted) {
                        if (newStatus == MemberStatus.approved) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Congratulations! Your church membership has been approved.',
                              ),
                              backgroundColor: AppColors.subtleOlive,
                            ),
                          );
                          context.go('/home');
                        } else if (newStatus == MemberStatus.rejected) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Your church membership application was not approved by the committee.',
                              ),
                              backgroundColor: AppColors.errorRed,
                            ),
                          );
                          await ref.read(authProvider.notifier).signOut();
                          if (context.mounted) {
                            context.go('/welcome');
                          }
                        } else if (newStatus == MemberStatus.suspended) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'This church membership account has been suspended.',
                              ),
                              backgroundColor: AppColors.errorRed,
                            ),
                          );
                          await ref.read(authProvider.notifier).signOut();
                          if (context.mounted) {
                            context.go('/welcome');
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Status checked: Application is still under committee review.',
                              ),
                              backgroundColor: AppColors.primaryBrown,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(height: AppStyles.space16),

                  // Logout Button
                  AppButton(
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: AppStyles.space12),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const Spacer(),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: valueColor ?? AppColors.textPrimary,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              ),
        ),
      ],
    );
  }
}
