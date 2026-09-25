import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/responsive_container.dart';
import '../providers/auth_provider.dart';

/// Screen allowing new church members to register with:
/// - Mandatory official full name (matching church registry)
/// - Mandatory church family number (shared by family unit)
/// - Mandatory profile photo upload
class RequestAccessPage extends ConsumerStatefulWidget {
  const RequestAccessPage({super.key});

  @override
  ConsumerState<RequestAccessPage> createState() => _RequestAccessPageState();
}

class _RequestAccessPageState extends ConsumerState<RequestAccessPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _familyNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _familyInfoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  Uint8List? _photoBytes;
  String? _photoFileName;
  String? _photoError;

  @override
  void dispose() {
    _nameController.dispose();
    _familyNumberController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _familyInfoController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      final sizeInBytes = bytes.lengthInBytes;
      final fileName = picked.name;

      final validationError = Validators.validateImageFile(
        sizeInBytes: sizeInBytes,
        fileName: fileName,
      );

      if (validationError != null) {
        if (!mounted) return;
        setState(() {
          _photoError = validationError;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(validationError),
            backgroundColor: AppColors.errorRed,
          ),
        );
        return;
      }

      setState(() {
        _photoBytes = bytes;
        _photoFileName = fileName;
        _photoError = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not access selected image. Please try again.'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppStyles.space20,
            horizontal: AppStyles.space24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Profile Photo',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryBrown,
                    ),
              ),
              const SizedBox(height: AppStyles.space8),
              Text(
                AppStrings.profilePhotoHelp,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppStyles.space20),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.primaryBrown),
                title: const Text(AppStrings.chooseFromGallery),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primaryBrown),
                title: const Text(AppStrings.takePhoto),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _pickImage(ImageSource.camera);
                },
              ),
              if (_photoBytes != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: AppColors.errorRed),
                  title: const Text(
                    AppStrings.removePhoto,
                    style: TextStyle(color: AppColors.errorRed),
                  ),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    setState(() {
                      _photoBytes = null;
                      _photoFileName = null;
                      _photoError = AppStrings.photoRequired;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleRequestAccess() async {
    // Validate form fields
    final isFormValid = _formKey.currentState!.validate();

    // Validate mandatory profile photo
    if (_photoBytes == null) {
      setState(() {
        _photoError = AppStrings.photoRequired;
      });
    }

    if (!isFormValid || _photoBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _photoBytes == null
                ? AppStrings.photoRequired
                : 'Please correct highlighted errors before submitting.',
          ),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    final success = await ref.read(authProvider.notifier).requestAccess(
          fullName: _nameController.text,
          familyNumber: _familyNumberController.text,
          photoBytes: _photoBytes!,
          photoFileName: _photoFileName ?? 'profile_photo.jpg',
          email: _emailController.text,
          phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
          familyInfo:
              _familyInfoController.text.isNotEmpty ? _familyInfoController.text : null,
          password: _passwordController.text,
        );

    if (!mounted) return;

    if (success) {
      context.go('/pending-approval');
    } else {
      final err = ref.read(authProvider).errorMessage;
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
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
                    const SizedBox(height: AppStyles.space8),
                    const AppLogo(size: 64),
                    const SizedBox(height: AppStyles.space16),
                    Text(
                      AppStrings.requestAccessTitle,
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppStyles.space8),
                    Text(
                      AppStrings.requestAccessSubtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppStyles.space20),

                    // Security / Approval Notice Banner
                    Container(
                      padding: const EdgeInsets.all(AppStyles.space16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCream,
                        borderRadius: AppStyles.roundedMedium,
                        border: Border.all(
                          color: AppColors.mutedGold.withValues(alpha: 0.5),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.verified_user_outlined,
                            color: AppColors.subtleOlive,
                            size: 22,
                          ),
                          const SizedBox(width: AppStyles.space12),
                          Expanded(
                            child: Text(
                              'Official records and photo are verified by the church committee. Multiple family members share the same family number, with independent approvals.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textPrimary,
                                    height: 1.4,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppStyles.space24),

                    // Mandatory Profile Photo Upload Section
                    AppCard(
                      child: Column(
                        children: [
                          Text(
                            AppStrings.profilePhoto,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryBrown,
                                ),
                          ),
                          const SizedBox(height: AppStyles.space8),
                          Text(
                            AppStrings.profilePhotoHelp,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: AppStyles.space16),

                          // Circular Photo Avatar with Badge
                          GestureDetector(
                            onTap: _showImageSourceDialog,
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Container(
                                  width: 110,
                                  height: 110,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.surfaceCream,
                                    border: Border.all(
                                      color: _photoError != null
                                          ? AppColors.errorRed
                                          : AppColors.mutedGold,
                                      width: 2.5,
                                    ),
                                    boxShadow: AppStyles.softCardShadow,
                                  ),
                                  child: ClipOval(
                                    child: _photoBytes != null
                                        ? Image.memory(
                                            _photoBytes!,
                                            width: 110,
                                            height: 110,
                                            fit: BoxFit.cover,
                                          )
                                        : const Icon(
                                            Icons.person_rounded,
                                            size: 64,
                                            color: AppColors.mutedGoldDark,
                                          ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryBrown,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppStyles.space12),

                          // Action link below photo
                          TextButton.icon(
                            onPressed: _showImageSourceDialog,
                            icon: Icon(
                              _photoBytes != null
                                  ? Icons.cached_rounded
                                  : Icons.add_photo_alternate_outlined,
                              size: 18,
                            ),
                            label: Text(
                              _photoBytes != null
                                  ? AppStrings.changePhoto
                                  : 'Upload Member Photo',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),

                          if (_photoError != null) ...[
                            const SizedBox(height: AppStyles.space4),
                            Text(
                              _photoError!,
                              style: const TextStyle(
                                color: AppColors.errorRed,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppStyles.space20),

                    // Registration Form Card
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Official Full Name (Mandatory)
                          AppTextField(
                            label: AppStrings.officialFullName,
                            hint: AppStrings.fullNameHint,
                            controller: _nameController,
                            validator: Validators.officialFullName,
                            prefixIcon: Icons.badge_outlined,
                          ),
                          const SizedBox(height: AppStyles.space16),

                          // 2. Church Family Number (Mandatory, Shared per family)
                          AppTextField(
                            label: AppStrings.familyNumber,
                            hint: AppStrings.familyNumberHint,
                            controller: _familyNumberController,
                            validator: Validators.familyNumber,
                            prefixIcon: Icons.groups_outlined,
                          ),
                          const SizedBox(height: AppStyles.space4),
                          Text(
                            AppStrings.familyNumberHelp,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textLight,
                                  fontSize: 11,
                                ),
                          ),
                          const SizedBox(height: AppStyles.space16),

                          // 3. Email (Mandatory)
                          AppTextField(
                            label: AppStrings.email,
                            hint: AppStrings.emailHint,
                            controller: _emailController,
                            validator: Validators.email,
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: Icons.email_outlined,
                          ),
                          const SizedBox(height: AppStyles.space16),

                          // 4. Phone (Optional)
                          AppTextField(
                            label: AppStrings.phone,
                            hint: AppStrings.phoneHint,
                            controller: _phoneController,
                            validator: Validators.optionalPhone,
                            keyboardType: TextInputType.phone,
                            prefixIcon: Icons.phone_outlined,
                          ),
                          const SizedBox(height: AppStyles.space16),

                          // 5. Parish Unit / Ward (Optional)
                          AppTextField(
                            label: AppStrings.familyInfo,
                            hint: AppStrings.familyInfoHint,
                            controller: _familyInfoController,
                            prefixIcon: Icons.home_outlined,
                          ),
                          const SizedBox(height: AppStyles.space16),

                          // 6. Password
                          AppTextField(
                            label: AppStrings.password,
                            hint: AppStrings.passwordHint,
                            controller: _passwordController,
                            validator: Validators.password,
                            isPassword: true,
                            prefixIcon: Icons.lock_outline_rounded,
                          ),
                          const SizedBox(height: AppStyles.space16),

                          // 7. Confirm Password
                          AppTextField(
                            label: AppStrings.confirmPassword,
                            hint: AppStrings.confirmPasswordHint,
                            controller: _confirmPasswordController,
                            validator: (v) =>
                                Validators.confirmPassword(v, _passwordController.text),
                            isPassword: true,
                            textInputAction: TextInputAction.done,
                            prefixIcon: Icons.lock_outline_rounded,
                            onFieldSubmitted: (_) => _handleRequestAccess(),
                          ),
                          const SizedBox(height: AppStyles.space24),

                          // Submit Button
                          AppButton(
                            label: AppStrings.requestAccess,
                            icon: Icons.send_rounded,
                            isLoading: auth.isLoading,
                            onPressed: _handleRequestAccess,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppStyles.space24),

                    // Navigation to Sign In
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppStrings.alreadyHaveAccount,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        GestureDetector(
                          onTap: () => context.go('/login'),
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              color: AppColors.primaryBrown,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
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
