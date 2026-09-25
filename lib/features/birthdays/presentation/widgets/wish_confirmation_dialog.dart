import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_styles.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/birthday_provider.dart';

/// Modal dialog showing non-editable static church wish template with confirmation.
class WishConfirmationDialog extends ConsumerStatefulWidget {
  final String recipientUid;
  final String recipientName;
  final String type; // 'birthday' or 'anniversary'
  final String eventDateStr;

  const WishConfirmationDialog({
    super.key,
    required this.recipientUid,
    required this.recipientName,
    required this.type,
    required this.eventDateStr,
  });

  /// Static church templates: non-editable by sender
  static String birthdayMessage(String name) =>
      'Happy Birthday, $name! May God bless you with good health, joy and happiness. Have a blessed and wonderful year ahead!';

  static String anniversaryMessage(String coupleName) =>
      'Happy Wedding Anniversary, $coupleName! May God continue to bless your marriage with love, joy and togetherness. Have a blessed anniversary!';

  @override
  ConsumerState<WishConfirmationDialog> createState() =>
      _WishConfirmationDialogState();
}

class _WishConfirmationDialogState
    extends ConsumerState<WishConfirmationDialog> {
  bool _isSending = false;

  bool get isBirthday => widget.type == 'birthday';

  String get formattedMessage => isBirthday
      ? WishConfirmationDialog.birthdayMessage(widget.recipientName)
      : WishConfirmationDialog.anniversaryMessage(widget.recipientName);

  Future<void> _handleSend() async {
    setState(() {
      _isSending = true;
    });

    final auth = ref.read(authProvider);
    final senderUid = auth.uid ?? '';
    final senderName = auth.fullName ?? 'Church Member';

    try {
      final repo = ref.read(birthdayRepositoryProvider);
      final idToken =
          await ref.read(authRepositoryProvider).currentUser?.getIdToken();

      await repo.sendWish(
        senderUid: senderUid,
        senderName: senderName,
        recipientUid: widget.recipientUid,
        recipientName: widget.recipientName,
        type: widget.type,
        eventDateStr: widget.eventDateStr,
        idToken: idToken,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isBirthday
                ? 'Birthday wish sent to ${widget.recipientName}! 🎉'
                : 'Anniversary wish sent to ${widget.recipientName}! 💍',
          ),
          backgroundColor: AppColors.subtleOlive,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not send wish: $e'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(AppStyles.space20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isBirthday
                          ? AppColors.mutedGoldLight
                          : AppColors.surfaceCream,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isBirthday ? Icons.cake_rounded : Icons.favorite_rounded,
                      color: isBirthday
                          ? AppColors.primaryBrown
                          : AppColors.accentWine,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppStyles.space12),
                  Expanded(
                    child: Text(
                      isBirthday
                          ? 'Send Birthday Wish?'
                          : 'Send Anniversary Wish?',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryBrown,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppStyles.space16),

              // Fixed Static Template Container (Non-editable)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppStyles.space16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCream,
                  borderRadius: AppStyles.roundedMedium,
                  border: Border.all(color: AppColors.softBeige),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.format_quote_rounded,
                          size: 16,
                          color: AppColors.mutedGoldDark,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Church Parish Greeting',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary.withValues(alpha: 0.8),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formattedMessage,
                      style: const TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: AppColors.primaryBrown,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppStyles.space20),

              // Action Buttons
              Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppStyles.space8,
                runSpacing: AppStyles.space8,
                children: [
                  TextButton(
                    onPressed: _isSending ? null : () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  SizedBox(
                    height: 40,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBrown,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppStyles.roundedMedium,
                        ),
                      ),
                      icon: _isSending
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded, size: 14),
                      label: Text(_isSending ? 'Sending...' : 'Send Wish'),
                      onPressed: _isSending ? null : _handleSend,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
