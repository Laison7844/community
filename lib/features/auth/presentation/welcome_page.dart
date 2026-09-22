import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/responsive_container.dart';

/// Welcoming landing screen introducing members and visitors to the church app.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundIvory,
      body: SafeArea(
        child: ResponsiveContainer(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppStyles.space24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: AppStyles.space24),
                  // Church Emblem and Header
                  const AppLogo(
                    size: 88,
                    showTitle: true,
                    showTagline: true,
                  ),
                  const SizedBox(height: AppStyles.space32),

                  // Scripture / Community Welcome Card
                  AppCard(
                    color: AppColors.surfaceCream,
                    padding: const EdgeInsets.all(AppStyles.space24),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.menu_book_rounded,
                          color: AppColors.mutedGoldDark,
                          size: 28,
                        ),
                        const SizedBox(height: AppStyles.space12),
                        Text(
                          AppStrings.dailyVerse,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontStyle: FontStyle.italic,
                                color: AppColors.primaryBrown,
                                fontWeight: FontWeight.w500,
                                height: 1.5,
                              ),
                        ),
                        const SizedBox(height: AppStyles.space8),
                        Text(
                          AppStrings.dailyVerseRef,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.mutedGoldDark,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppStyles.space24),

                  // Welcoming description
                  Text(
                    AppStrings.welcomeSubtitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                  ),
                  const SizedBox(height: AppStyles.space40),

                  // Action Buttons
                  AppButton(
                    label: AppStrings.signIn,
                    icon: Icons.login_rounded,
                    onPressed: () => context.go('/login'),
                  ),
                  const SizedBox(height: AppStyles.space16),
                  AppButton(
                    label: AppStrings.requestAccess,
                    icon: Icons.person_add_alt_1_rounded,
                    variant: AppButtonVariant.outline,
                    onPressed: () => context.go('/request-access'),
                  ),
                  const SizedBox(height: AppStyles.space24),

                  // Footer caption
                  Text(
                    'Private community for verified CSI church members',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textLight,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
