import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';

/// A customized, accessible text form field with CSI Church palette borders and labels.
class AppTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final String? helperText;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool isPassword;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool showClearButton;
  final VoidCallback? onClear;
  final int maxLines;
  final bool readOnly;
  final bool enabled;
  final bool isRequired;
  final VoidCallback? onTap;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.helperText,
    this.controller,
    this.validator,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.prefixIcon,
    this.suffixIcon,
    this.showClearButton = false,
    this.onClear,
    this.maxLines = 1,
    this.readOnly = false,
    this.enabled = true,
    this.isRequired = false,
    this.onTap,
    this.onChanged,
    this.onFieldSubmitted,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Build suffix icon: password toggle or clear button or custom suffix
    Widget? effectiveSuffixIcon;
    if (widget.isPassword) {
      effectiveSuffixIcon = IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: AppColors.textSecondary,
          size: 20,
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      );
    } else if (widget.showClearButton &&
        widget.controller != null &&
        widget.controller!.text.isNotEmpty) {
      effectiveSuffixIcon = IconButton(
        icon: const Icon(Icons.clear_rounded, color: AppColors.textLight, size: 18),
        onPressed: () {
          widget.controller!.clear();
          if (widget.onChanged != null) widget.onChanged!('');
          if (widget.onClear != null) widget.onClear!();
          setState(() {});
        },
      );
    } else if (widget.suffixIcon != null) {
      effectiveSuffixIcon = widget.suffixIcon;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label with optional required asterisk
        Row(
          children: [
            Text(
              widget.label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: widget.enabled ? AppColors.textPrimary : AppColors.textMuted,
              ),
            ),
            if (widget.isRequired) ...[
              const SizedBox(width: AppStyles.space4),
              const Text(
                '*',
                style: TextStyle(
                  color: AppColors.accentBurgundy,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppStyles.space8),
        TextFormField(
          controller: widget.controller,
          validator: widget.validator,
          obscureText: widget.isPassword ? _obscureText : false,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          readOnly: widget.readOnly,
          enabled: widget.enabled,
          onTap: widget.onTap,
          onChanged: (val) {
            if (widget.showClearButton) setState(() {});
            if (widget.onChanged != null) widget.onChanged!(val);
          },
          onFieldSubmitted: widget.onFieldSubmitted,
          maxLines: widget.maxLines,
          style: TextStyle(
            fontSize: 15,
            color: widget.enabled ? AppColors.textPrimary : AppColors.textMuted,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            helperText: widget.helperText,
            helperStyle: const TextStyle(
              color: AppColors.textLight,
              fontSize: 12,
            ),
            hintStyle: const TextStyle(
              color: AppColors.textLight,
              fontSize: 14,
            ),
            filled: true,
            fillColor: widget.enabled
                ? (widget.readOnly ? AppColors.surfaceCream : AppColors.cardSurface)
                : AppColors.surfaceCream,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppStyles.space16,
              vertical: AppStyles.space14,
            ),
            prefixIcon: widget.prefixIcon != null
                ? Icon(widget.prefixIcon, color: AppColors.textSecondary, size: 20)
                : null,
            suffixIcon: effectiveSuffixIcon,
            enabledBorder: const OutlineInputBorder(
              borderRadius: AppStyles.roundedSmall,
              borderSide: BorderSide(color: AppColors.borderDefault, width: 1.2),
            ),
            disabledBorder: const OutlineInputBorder(
              borderRadius: AppStyles.roundedSmall,
              borderSide: BorderSide(color: AppColors.borderSubtle, width: 1.0),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: AppStyles.roundedSmall,
              borderSide: BorderSide(color: AppColors.primaryBrown, width: 1.8),
            ),
            errorBorder: const OutlineInputBorder(
              borderRadius: AppStyles.roundedSmall,
              borderSide: BorderSide(color: AppColors.errorRed, width: 1.2),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderRadius: AppStyles.roundedSmall,
              borderSide: BorderSide(color: AppColors.errorRed, width: 1.8),
            ),
          ),
        ),
      ],
    );
  }
}
