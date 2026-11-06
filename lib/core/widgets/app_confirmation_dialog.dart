import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import 'app_button.dart';

/// A standardized confirmation dialog conforming to the CSI Church Design System.
///
/// Features distinct title emphasis, optional mandatory reason input,
/// and clear Cancel/Confirm actions.
class AppConfirmationDialog extends StatefulWidget {
  final String title;
  final String prompt;
  final String confirmLabel;
  final String cancelLabel;
  final AppButtonVariant confirmVariant;
  final bool isDestructive;
  final bool showReasonField;
  final bool isReasonMandatory;
  final String? reasonLabel;
  final String? reasonHint;

  const AppConfirmationDialog({
    super.key,
    required this.title,
    required this.prompt,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.confirmVariant = AppButtonVariant.primary,
    this.isDestructive = false,
    this.showReasonField = false,
    this.isReasonMandatory = false,
    this.reasonLabel,
    this.reasonHint,
  });

  /// Static helper to display the dialog and return confirmed status or reason string
  static Future<String?> show(
    BuildContext context, {
    required String title,
    required String prompt,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    AppButtonVariant confirmVariant = AppButtonVariant.primary,
    bool isDestructive = false,
    bool showReasonField = false,
    bool isReasonMandatory = false,
    String? reasonLabel,
    String? reasonHint,
  }) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => AppConfirmationDialog(
        title: title,
        prompt: prompt,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        confirmVariant: confirmVariant,
        isDestructive: isDestructive,
        showReasonField: showReasonField,
        isReasonMandatory: isReasonMandatory,
        reasonLabel: reasonLabel,
        reasonHint: reasonHint,
      ),
    );
  }

  @override
  State<AppConfirmationDialog> createState() => _AppConfirmationDialogState();
}

class _AppConfirmationDialogState extends State<AppConfirmationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _handleConfirm() {
    if (widget.showReasonField && widget.isReasonMandatory) {
      if (!_formKey.currentState!.validate()) return;
    }
    final reasonText = _reasonController.text.trim();
    Navigator.of(context).pop(reasonText.isNotEmpty ? reasonText : 'confirmed');
  }

  @override
  Widget build(BuildContext context) {
    final titleColor = widget.isDestructive ? AppColors.errorRed : AppColors.primaryBrown;
    final effectiveVariant = widget.isDestructive
        ? AppButtonVariant.destructive
        : widget.confirmVariant;

    return AlertDialog(
      backgroundColor: AppColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: AppStyles.roundedLarge,
      ),
      titlePadding: const EdgeInsets.fromLTRB(AppStyles.space24, AppStyles.space24, AppStyles.space24, AppStyles.space12),
      contentPadding: const EdgeInsets.symmetric(horizontal: AppStyles.space24),
      actionsPadding: const EdgeInsets.all(AppStyles.space16),
      title: Text(
        widget.title,
        style: TextStyle(
          color: titleColor,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.prompt,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              if (widget.showReasonField) ...[
                const SizedBox(height: AppStyles.space16),
                TextFormField(
                  controller: _reasonController,
                  validator: (val) {
                    if (widget.isReasonMandatory && (val == null || val.trim().isEmpty)) {
                      return 'A reason is required to proceed';
                    }
                    return null;
                  },
                  maxLines: 2,
                  style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: widget.reasonLabel ??
                        (widget.isReasonMandatory ? 'Reason (Mandatory)' : 'Notes / Reason (Optional)'),
                    hintText: widget.reasonHint ?? 'e.g. Verified with parish register',
                    filled: true,
                    fillColor: AppColors.surfaceCream,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        AppButton(
          label: widget.cancelLabel,
          variant: AppButtonVariant.ghost,
          size: AppButtonSize.regular,
          width: null,
          onPressed: () => Navigator.of(context).pop(null),
        ),
        const SizedBox(width: AppStyles.space8),
        AppButton(
          label: widget.confirmLabel,
          variant: effectiveVariant,
          size: AppButtonSize.regular,
          width: null,
          onPressed: _handleConfirm,
        ),
      ],
    );
  }
}

