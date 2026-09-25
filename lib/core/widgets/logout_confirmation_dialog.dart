import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import '../../features/auth/providers/auth_provider.dart';

/// Shows a standardized Material 3 confirmation dialog before logging out.
///
/// Ensures the user explicitly confirms before any authentication state is cleared.
Future<void> showLogoutConfirmationDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      backgroundColor: AppColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: AppStyles.roundedLarge,
      ),
      title: const Text(
        'Logout',
        style: TextStyle(
          color: AppColors.primaryBrown,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: const Text(
        'Are you sure you want to logout?',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogCtx, false),
          child: const Text(
            'Cancel',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.errorRed,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: const RoundedRectangleBorder(
              borderRadius: AppStyles.roundedMedium,
            ),
          ),
          onPressed: () => Navigator.pop(dialogCtx, true),
          child: const Text(
            'Logout',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );

  if (confirmed == true && context.mounted) {
    await ref.read(authProvider.notifier).signOut();
    if (context.mounted) {
      context.go('/welcome');
    }
  }
}
