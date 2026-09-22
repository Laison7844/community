import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/responsive_container.dart';
import '../models/auth_state.dart';
import '../providers/auth_provider.dart';

/// Login screen enabling members to sign in with email & password.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authProvider.notifier).signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );

    if (!mounted) return;

    final auth = ref.read(authProvider);
    if (success) {
      if (auth.status == MemberStatus.pending) {
        context.go('/pending-approval');
      } else if (auth.status == MemberStatus.approved) {
        context.go('/home');
      }
    } else if (auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage!),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  void _showForgotPasswordDialog() {
    final emailResetController = TextEditingController(text: _emailController.text);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        shape: const RoundedRectangleBorder(borderRadius: AppStyles.roundedLarge),
        title: const Text(
          'Reset Password',
          style: TextStyle(color: AppColors.primaryBrown, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your registered church email address and we will send you instructions to reset your password.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: AppStyles.space16),
            AppTextField(
              label: AppStrings.email,
              hint: AppStrings.emailHint,
              controller: emailResetController,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailResetController.text.trim();
              if (email.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter your email address to reset password.'),
                    backgroundColor: AppColors.errorRed,
                  ),
                );
                return;
              }
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(dialogContext);
              final success =
                  await ref.read(authProvider.notifier).sendPasswordReset(email);
              if (!mounted) return;
              if (success) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Password reset instructions sent to your email.'),
                    backgroundColor: AppColors.subtleOlive,
                  ),
                );
              } else {
                final err = ref.read(authProvider).errorMessage ??
                    'Could not send reset email.';
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(err),
                    backgroundColor: AppColors.errorRed,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBrown,
              foregroundColor: AppColors.textOnPrimary,
            ),
            child: const Text('Send Link'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundIvory,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.go('/welcome'),
        ),
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppStyles.space32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: AppStyles.space12),
                    const AppLogo(size: 68),
                    const SizedBox(height: AppStyles.space20),
                    Text(
                      AppStrings.welcomeBack,
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppStyles.space8),
                    Text(
                      AppStrings.loginSubtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppStyles.space28),

                    // Login Card
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppTextField(
                            label: AppStrings.email,
                            hint: AppStrings.emailHint,
                            controller: _emailController,
                            validator: Validators.email,
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: Icons.email_outlined,
                          ),
                          const SizedBox(height: AppStyles.space20),
                          AppTextField(
                            label: AppStrings.password,
                            hint: AppStrings.passwordHint,
                            controller: _passwordController,
                            validator: Validators.password,
                            isPassword: true,
                            textInputAction: TextInputAction.done,
                            prefixIcon: Icons.lock_outline_rounded,
                            onFieldSubmitted: (_) => _handleSignIn(),
                          ),
                          const SizedBox(height: AppStyles.space12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _showForgotPasswordDialog,
                              child: const Text(
                                AppStrings.forgotPassword,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.mutedGoldDark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppStyles.space16),
                          AppButton(
                            label: AppStrings.signIn,
                            icon: Icons.login_rounded,
                            isLoading: auth.isLoading,
                            onPressed: _handleSignIn,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppStyles.space24),

                    // Navigation to Request Access
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppStrings.needToRegister,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        GestureDetector(
                          onTap: () => context.go('/request-access'),
                          child: const Text(
                            'Request Access',
                            style: TextStyle(
                              color: AppColors.primaryBrown,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppStyles.space16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
