import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:communtiy/core/constants/app_colors.dart';
import 'package:communtiy/core/constants/app_styles.dart';
import 'package:communtiy/app/app_theme.dart';
import 'package:communtiy/core/widgets/app_button.dart';
import 'package:communtiy/core/widgets/app_card.dart';
import 'package:communtiy/core/widgets/app_text_field.dart';
import 'package:communtiy/core/widgets/app_status_badge.dart';
import 'package:communtiy/core/widgets/app_stat_card.dart';
import 'package:communtiy/core/widgets/app_section_header.dart';
import 'package:communtiy/core/widgets/app_info_row.dart';
import 'package:communtiy/core/widgets/app_empty_state.dart';
import 'package:communtiy/core/widgets/app_error_state.dart';
import 'package:communtiy/core/widgets/app_confirmation_dialog.dart';

void main() {
  group('CSI Church Design System - Tokens', () {
    test('AppColors contains approved palette values', () {
      expect(AppColors.primaryBrown, const Color(0xFF3E2723));
      expect(AppColors.primary, const Color(0xFF3E2723));
      expect(AppColors.primaryBrownLight, const Color(0xFF5D4037));
      expect(AppColors.primaryBrownDark, const Color(0xFF271512));

      expect(AppColors.mutedGold, const Color(0xFFC5A059));
      expect(AppColors.accentGold, const Color(0xFFC5A059));
      expect(AppColors.mutedGoldDark, const Color(0xFF9E7B35));
      expect(AppColors.accentGoldDark, const Color(0xFF9E7B35));
      expect(AppColors.mutedGoldLight, const Color(0xFFDFBF7E));

      expect(AppColors.accentWine, const Color(0xFF8B263E));
      expect(AppColors.accentBurgundy, const Color(0xFF8B263E));

      expect(AppColors.backgroundIvory, const Color(0xFFFAF8F5));
      expect(AppColors.surfaceCream, const Color(0xFFF5F0E8));
      expect(AppColors.cardSurface, const Color(0xFFFFFFFF));
      expect(AppColors.softBeige, const Color(0xFFE8E2D8));
      expect(AppColors.borderDefault, const Color(0xFFE8E2D8));
      expect(AppColors.lightBeige, const Color(0xFFF1ECE4));
      expect(AppColors.borderSubtle, const Color(0xFFF1ECE4));

      expect(AppColors.textPrimary, const Color(0xFF2C2523));
      expect(AppColors.textSecondary, const Color(0xFF6E655F));
      expect(AppColors.textMuted, const Color(0xFF9E958F));

      // Semantic status colors
      expect(AppColors.statusPendingBg, const Color(0xFFFEF3C7));
      expect(AppColors.statusPendingFg, const Color(0xFFD97706));
      expect(AppColors.statusApprovedBg, const Color(0xFFEBF1E5));
      expect(AppColors.statusApprovedFg, const Color(0xFF556B2F));
      expect(AppColors.statusSuspendedBg, const Color(0xFFFFEBEE));
      expect(AppColors.statusSuspendedFg, const Color(0xFFC62828));
      expect(AppColors.statusRejectedBg, const Color(0xFFF3F4F6));
      expect(AppColors.statusRejectedFg, const Color(0xFF4B5563));
      expect(AppColors.statusDraftBg, const Color(0xFFFEF3C7));
      expect(AppColors.statusDraftFg, const Color(0xFFB45309));
    });

    test('AppStyles contains 8-point base grid spacing and radius constants', () {
      expect(AppStyles.space4, 4.0);
      expect(AppStyles.space8, 8.0);
      expect(AppStyles.space12, 12.0);
      expect(AppStyles.space16, 16.0);
      expect(AppStyles.space20, 20.0);
      expect(AppStyles.space24, 24.0);
      expect(AppStyles.space32, 32.0);
      expect(AppStyles.space48, 48.0);

      expect(AppStyles.radiusSmall, 8.0);
      expect(AppStyles.radiusMedium, 12.0);
      expect(AppStyles.radiusLarge, 16.0);
      expect(AppStyles.radiusXLarge, 24.0);
      expect(AppStyles.radiusFull, 999.0);

      expect(AppStyles.mobileBreakpoint, 600.0);
      expect(AppStyles.tabletBreakpoint, 1024.0);
      expect(AppStyles.desktopBreakpoint, 1024.0);
    });

    test('AppTheme.lightTheme builds correctly with Material 3 and church tokens', () {
      final theme = AppTheme.lightTheme;
      expect(theme.useMaterial3, isTrue);
      expect(theme.scaffoldBackgroundColor, AppColors.backgroundIvory);
      expect(theme.colorScheme.primary, AppColors.primaryBrown);
      expect(theme.colorScheme.secondary, AppColors.mutedGold);
      expect(theme.colorScheme.surface, AppColors.cardSurface);

      // Typography scales
      expect(theme.textTheme.displayLarge?.fontSize, 32);
      expect(theme.textTheme.headlineLarge?.fontSize, 24);
      expect(theme.textTheme.headlineMedium?.fontSize, 20);
      expect(theme.textTheme.titleLarge?.fontSize, 18);
      expect(theme.textTheme.titleMedium?.fontSize, 16);
      expect(theme.textTheme.titleSmall?.fontSize, 14);
      expect(theme.textTheme.bodyLarge?.fontSize, 16);
      expect(theme.textTheme.bodyMedium?.fontSize, 14);
      expect(theme.textTheme.bodySmall?.fontSize, 12);
      expect(theme.textTheme.labelSmall?.fontSize, 11);
    });
  });

  group('CSI Church Design System - Shared Widgets', () {
    testWidgets('AppButton renders label, icon, and responds to taps', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppButton(
              label: 'Save Changes',
              icon: Icons.check,
              onPressed: () => tapped = true,
              size: AppButtonSize.regular,
              variant: AppButtonVariant.primary,
            ),
          ),
        ),
      );

      expect(find.text('Save Changes'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);

      await tester.tap(find.text('Save Changes'));
      expect(tapped, isTrue);
    });

    testWidgets('AppButton handles loading state and backward compatible constructors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppButton(
              label: 'Submit',
              isLoading: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Submit'), findsNothing);
    });

    testWidgets('AppCard renders child and variants properly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: Column(
              children: [
                AppCard(
                  variant: AppCardVariant.elevated,
                  child: Text('Elevated Card'),
                ),
                AppCard(
                  variant: AppCardVariant.subtle,
                  child: Text('Subtle Card'),
                ),
                AppCard(
                  variant: AppCardVariant.burgundyAccent,
                  child: Text('Burgundy Card'),
                ),
                AppCard(
                  variant: AppCardVariant.goldAccent,
                  child: Text('Gold Card'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Elevated Card'), findsOneWidget);
      expect(find.text('Subtle Card'), findsOneWidget);
      expect(find.text('Burgundy Card'), findsOneWidget);
      expect(find.text('Gold Card'), findsOneWidget);
    });

    testWidgets('AppStatusBadge maps statuses accurately', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Column(
              children: [
                AppStatusBadge.fromString('pending'),
                AppStatusBadge.fromString('approved'),
                AppStatusBadge.fromString('suspended'),
                AppStatusBadge.fromString('rejected'),
                AppStatusBadge.fromString('draft'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Pending Review'), findsOneWidget);
      expect(find.text('Approved'), findsOneWidget);
      expect(find.text('Suspended'), findsOneWidget);
      expect(find.text('Rejected'), findsOneWidget);
      expect(find.text('Draft'), findsOneWidget);
    });

    testWidgets('AppStatCard renders title, count, and triggers tap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppStatCard(
              title: 'Pending Applicants',
              count: '14',
              icon: Icons.hourglass_top,
              color: AppColors.statusPendingFg,
              isSelected: true,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Pending Applicants'), findsOneWidget);
      expect(find.text('14'), findsOneWidget);
      expect(find.byIcon(Icons.hourglass_top), findsOneWidget);

      await tester.tap(find.text('Pending Applicants'));
      expect(tapped, isTrue);
    });

    testWidgets('AppSectionHeader renders title, icon, and count pill', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppSectionHeader(
              title: 'Weekly Birthdays',
              icon: Icons.cake,
              count: 7,
            ),
          ),
        ),
      );

      expect(find.text('Weekly Birthdays'), findsOneWidget);
      expect(find.byIcon(Icons.cake), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('AppInfoRow renders label and value with divider', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppInfoRow(
              icon: Icons.person,
              label: 'Full Name',
              value: 'Abraham Thomas',
              showDivider: true,
            ),
          ),
        ),
      );

      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Abraham Thomas'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.byType(Divider), findsOneWidget);
    });

    testWidgets('AppEmptyState renders icon, title, message and action button', (tester) async {
      bool actionTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppEmptyState(
              icon: Icons.celebration,
              title: 'No Celebrations This Week',
              message: 'Check back next Sunday for upcoming parish birthdays.',
              actionLabel: 'Refresh Bulletin',
              onAction: () => actionTriggered = true,
            ),
          ),
        ),
      );

      expect(find.text('No Celebrations This Week'), findsOneWidget);
      expect(find.text('Check back next Sunday for upcoming parish birthdays.'), findsOneWidget);
      expect(find.text('Refresh Bulletin'), findsOneWidget);

      await tester.tap(find.text('Refresh Bulletin'));
      expect(actionTriggered, isTrue);
    });

    testWidgets('AppErrorState renders title, message, and retry button', (tester) async {
      bool retried = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppErrorState(
              title: 'Connection Lost',
              message: 'Unable to reach the church server. Please check your network.',
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      expect(find.text('Connection Lost'), findsOneWidget);
      expect(find.text('Unable to reach the church server. Please check your network.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      expect(retried, isTrue);
    });

    testWidgets('AppTextField renders label, hint, and required asterisk', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppTextField(
              label: 'Official Full Name',
              hint: 'As in church register',
              controller: controller,
              isRequired: true,
              prefixIcon: Icons.badge_outlined,
            ),
          ),
        ),
      );

      expect(find.text('Official Full Name'), findsOneWidget);
      expect(find.text('*'), findsOneWidget);
      expect(find.byIcon(Icons.badge_outlined), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'Samuel Johnson');
      expect(controller.text, 'Samuel Johnson');
    });

    testWidgets('AppConfirmationDialog renders title, prompt, and action buttons', (tester) async {
      String? result;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  result = await AppConfirmationDialog.show(
                    ctx,
                    title: 'Approve Member',
                    prompt: 'Confirm membership approval for applicant.',
                    confirmLabel: 'Approve',
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Approve Member'), findsOneWidget);
      expect(find.text('Confirm membership approval for applicant.'), findsOneWidget);
      expect(find.text('Approve'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      await tester.tap(find.text('Approve'));
      await tester.pumpAndSettle();

      expect(result, 'confirmed');
    });
  });
}
