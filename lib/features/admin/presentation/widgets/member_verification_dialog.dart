import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../auth/models/auth_state.dart';
import '../../../auth/models/member_profile.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/admin_provider.dart';

/// Modal dialog showing full applicant verification details and actionable approval buttons.
class MemberVerificationDialog extends ConsumerStatefulWidget {
  final MemberProfile member;

  const MemberVerificationDialog({
    super.key,
    required this.member,
  });

  @override
  ConsumerState<MemberVerificationDialog> createState() =>
      _MemberVerificationDialogState();
}

class _MemberVerificationDialogState
    extends ConsumerState<MemberVerificationDialog> {
  bool _isProcessing = false;

  void _showActionConfirmDialog({
    required MemberStatus targetStatus,
    required String actionTitle,
    required String actionPrompt,
    required bool isReasonMandatory,
    required Color actionColor,
  }) {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        shape: const RoundedRectangleBorder(
          borderRadius: AppStyles.roundedLarge,
        ),
        title: Text(
          actionTitle,
          style: TextStyle(
            color: actionColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                actionPrompt,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: AppStyles.space16),
              TextFormField(
                controller: reasonController,
                validator: (val) {
                  if (isReasonMandatory && (val == null || val.trim().isEmpty)) {
                    return 'A reason is mandatory for this action';
                  }
                  return null;
                },
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: isReasonMandatory
                      ? 'Reason (Mandatory)'
                      : 'Committee Notes / Reason (Optional)',
                  hintText: 'e.g. Verified with Ward Elder / Register page 42',
                  filled: true,
                  fillColor: AppColors.surfaceCream,
                  border: const OutlineInputBorder(
                    borderRadius: AppStyles.roundedMedium,
                    borderSide: BorderSide(color: AppColors.softBeige),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: actionColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final reason = reasonController.text.trim();
              Navigator.pop(dialogContext); // close confirm dialog
              await _executeAction(targetStatus, reason);
            },
            child: Text(actionTitle),
          ),
        ],
      ),
    );
  }

  Future<void> _executeAction(MemberStatus newStatus, String reason) async {
    final staffAuth = ref.read(authProvider);
    final staffUid = staffAuth.uid ?? '';
    final staffRole = staffAuth.profile?.role ?? 'committee';

    setState(() {
      _isProcessing = true;
    });

    try {
      await ref.read(adminRepositoryProvider).executeStatusTransition(
            targetMember: widget.member,
            newStatus: newStatus,
            reason: reason,
            performedByUid: staffUid,
            performedByRole: staffRole,
          );

      if (!mounted) return;
      Navigator.pop(context); // close verification dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Member status successfully updated to ${MemberProfile.statusToString(newStatus).toUpperCase()}.',
          ),
          backgroundColor: AppColors.subtleOlive,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.member;
    final formattedDate = m.createdAt != null
        ? DateFormat('MMMM d, y · h:mm a').format(m.createdAt!)
        : 'Unknown';

    return Dialog(
      backgroundColor: AppColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: AppStyles.roundedXLarge,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 760),
        child: Padding(
          padding: const EdgeInsets.all(AppStyles.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Title and Close Button
              Row(
                children: [
                  const Icon(
                    Icons.how_to_reg_rounded,
                    color: AppColors.primaryBrown,
                    size: 26,
                  ),
                  const SizedBox(width: AppStyles.space12),
                  Expanded(
                    child: Text(
                      'Applicant Verification Details',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryBrown,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: AppStyles.space20),

              // Scrollable Details Body
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Official Registry Warning Disclaimer
                      Container(
                        padding: const EdgeInsets.all(AppStyles.space12),
                        decoration: BoxDecoration(
                          color: AppColors.warningAmberLight,
                          borderRadius: AppStyles.roundedMedium,
                          border: Border.all(
                            color: AppColors.warningAmber.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.fact_check_outlined,
                              color: AppColors.warningAmber,
                              size: 20,
                            ),
                            const SizedBox(width: AppStyles.space12),
                            Expanded(
                              child: Text(
                                'Important: The details and photo below were submitted by the applicant. Authorized committee staff must verify these against official church census & baptism records before approval.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textPrimary.withValues(alpha: 0.9),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppStyles.space20),

                      // Profile Photo & Core Info Header Card
                      AppCard(
                        color: AppColors.surfaceCream,
                        padding: const EdgeInsets.all(AppStyles.space16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Circular Profile Photo
                            ClipRRect(
                              borderRadius: BorderRadius.circular(40),
                              child: Container(
                                width: 80,
                                height: 80,
                                color: AppColors.cardSurface,
                                child: m.profileImageUrl.isNotEmpty
                                    ? Image.network(
                                        m.profileImageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, error, stack) => const Icon(
                                          Icons.person_rounded,
                                          size: 48,
                                          color: AppColors.mutedGold,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.person_rounded,
                                        size: 48,
                                        color: AppColors.mutedGold,
                                      ),
                              ),
                            ),
                            const SizedBox(width: AppStyles.space16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    m.fullName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryBrown,
                                    ),
                                  ),
                                  const SizedBox(height: AppStyles.space4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.mutedGold.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: AppColors.mutedGoldDark,
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          'Family No: ${m.familyNumber}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primaryBrown,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: AppStyles.space8),
                                      _buildStatusBadge(m.status),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Registered: $formattedDate',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppStyles.space16),

                      // Contact & Registration Details Grid
                      AppCard(
                        padding: const EdgeInsets.all(AppStyles.space16),
                        child: Column(
                          children: [
                            _buildInfoRow('Email Address', m.email, Icons.email_outlined),
                            const Divider(height: AppStyles.space16),
                            _buildInfoRow(
                              'Phone Number',
                              m.phone?.isNotEmpty == true ? m.phone! : 'Not provided',
                              Icons.phone_outlined,
                            ),
                            const Divider(height: AppStyles.space16),
                            _buildInfoRow(
                              'Family / Ward Unit',
                              m.familyInfo?.isNotEmpty == true ? m.familyInfo! : 'Not specified',
                              Icons.home_outlined,
                            ),
                            const Divider(height: AppStyles.space16),
                            _buildInfoRow('System UID', m.uid, Icons.fingerprint_rounded),
                            const Divider(height: AppStyles.space16),
                            _buildInfoRow('Assigned Role', m.role.toUpperCase(), Icons.badge_outlined),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: AppStyles.space20),

              // Action Buttons Based on Status
              if (_isProcessing)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                _buildActionButtons(m),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(MemberStatus status) {
    Color bg;
    Color fg;
    String text;

    switch (status) {
      case MemberStatus.approved:
        bg = AppColors.successGreenLight;
        fg = AppColors.successGreen;
        text = 'Approved';
        break;
      case MemberStatus.pending:
        bg = AppColors.warningAmberLight;
        fg = AppColors.warningAmber;
        text = 'Pending Review';
        break;
      case MemberStatus.suspended:
        bg = AppColors.errorRedLight;
        fg = AppColors.errorRed;
        text = 'Suspended';
        break;
      case MemberStatus.rejected:
        bg = Colors.grey.shade200;
        fg = Colors.grey.shade800;
        text = 'Rejected';
        break;
      case MemberStatus.none:
        bg = Colors.grey.shade200;
        fg = Colors.grey.shade600;
        text = 'None';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: AppStyles.space8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        SelectableText(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(MemberProfile m) {
    switch (m.status) {
      case MemberStatus.pending:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.errorRed,
                  side: const BorderSide(color: AppColors.errorRed),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.close_rounded, size: 18),
                label: const Text('Reject Applicant'),
                onPressed: () => _showActionConfirmDialog(
                  targetStatus: MemberStatus.rejected,
                  actionTitle: 'Reject Application',
                  actionPrompt:
                      'Are you sure you want to reject this applicant? A reason is mandatory and will be recorded in the audit log.',
                  isReasonMandatory: true,
                  actionColor: AppColors.errorRed,
                ),
              ),
            ),
            const SizedBox(width: AppStyles.space16),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.subtleOlive,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: const Text('Approve Member'),
                onPressed: () => _showActionConfirmDialog(
                  targetStatus: MemberStatus.approved,
                  actionTitle: 'Approve Membership',
                  actionPrompt:
                      'Confirm approval of ${m.fullName} under Family No. ${m.familyNumber}.',
                  isReasonMandatory: false,
                  actionColor: AppColors.subtleOlive,
                ),
              ),
            ),
          ],
        );

      case MemberStatus.approved:
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.errorRed,
              side: const BorderSide(color: AppColors.errorRed),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.block_rounded, size: 18),
            label: const Text('Suspend Member Account'),
            onPressed: () => _showActionConfirmDialog(
              targetStatus: MemberStatus.suspended,
              actionTitle: 'Suspend Member',
              actionPrompt:
                  'Suspending ${m.fullName} will immediately revoke their application access. A reason is mandatory.',
              isReasonMandatory: true,
              actionColor: AppColors.errorRed,
            ),
          ),
        );

      case MemberStatus.suspended:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.subtleOlive,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Restore / Re-activate Member'),
            onPressed: () => _showActionConfirmDialog(
              targetStatus: MemberStatus.approved,
              actionTitle: 'Restore Member',
              actionPrompt: 'Re-activate ${m.fullName} back to Approved status.',
              isReasonMandatory: false,
              actionColor: AppColors.subtleOlive,
            ),
          ),
        );

      case MemberStatus.rejected:
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryBrown,
              side: const BorderSide(color: AppColors.primaryBrown),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.replay_rounded, size: 18),
            label: const Text('Reconsider Application'),
            onPressed: () => _showActionConfirmDialog(
              targetStatus: MemberStatus.pending,
              actionTitle: 'Move to Pending Review',
              actionPrompt:
                  'Move ${m.fullName} back to Pending status for committee reconsideration.',
              isReasonMandatory: false,
              actionColor: AppColors.primaryBrown,
            ),
          ),
        );

      case MemberStatus.none:
        return const SizedBox.shrink();
    }
  }
}
