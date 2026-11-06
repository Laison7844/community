import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/widgets/app_logo.dart';
import '../models/auth_state.dart';
import '../providers/auth_provider.dart';
import '../../admin/providers/admin_provider.dart';

/// Initial splash screen with church branding and session restoration.
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  Timer? _minDisplayTimer;
  bool _minTimeElapsed = false;

  @override
  void initState() {
    super.initState();
    // Ensure splash is visible for at least 1.2s for clean branding experience
    _minDisplayTimer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() {
        _minTimeElapsed = true;
      });
      _checkAndNavigate();
    });
  }

  void _checkAndNavigate() {
    if (!_minTimeElapsed || !mounted) return;
    final auth = ref.read(authProvider);
    final isStaff = ref.read(isStaffUserProvider);
    if (auth.isLoading) return; // Wait until background session restore finishes

    if (!auth.isAuthenticated) {
      context.go('/welcome');
    } else if (isStaff) {
      context.go('/admin');
    } else if (auth.status == MemberStatus.pending) {
      context.go('/pending-approval');
    } else if (auth.status == MemberStatus.approved) {
      context.go('/home');
    } else {
      context.go('/welcome');
    }
  }

  @override
  void dispose() {
    _minDisplayTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen for auth state change if session restore completes after timer
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (_minTimeElapsed && !next.isLoading) {
        _checkAndNavigate();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundIvory,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              const AppLogo(
                size: 96,
                showTitle: true,
                showTagline: true,
              ),
              const Spacer(flex: 2),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.mutedGoldDark.withValues(alpha: 0.7),
                  ),
                ),
              ),
              const SizedBox(height: AppStyles.space32),
            ],
          ),
        ),
      ),
    );
  }
}
