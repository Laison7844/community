import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/widgets/member_avatar.dart';
import '../../../core/widgets/responsive_container.dart';
import '../../admin/providers/admin_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/anniversary_entry.dart';
import '../models/birthday_anniversary_week.dart';
import '../models/birthday_entry.dart';
import '../models/member_reminder.dart';
import '../providers/birthday_provider.dart';
import 'widgets/wish_confirmation_dialog.dart';
import '../../admin/presentation/widgets/manage_birthdays_dialog.dart';

/// Mobile-first parish view of weekly birthdays and wedding anniversaries.
class BirthdaysPage extends ConsumerWidget {
  const BirthdaysPage({super.key});

  void _openWishDialog(
    BuildContext context, {
    required String recipientUid,
    required String recipientName,
    required String type,
    required DateTime eventDate,
  }) {
    showDialog(
      context: context,
      builder: (_) => WishConfirmationDialog(
        recipientUid: recipientUid,
        recipientName: recipientName,
        type: type,
        eventDateStr: DateFormat('yyyy-MM-dd').format(eventDate),
      ),
    );
  }

  void _toggleReminder(
    BuildContext context,
    WidgetRef ref, {
    required String entryId,
    required String targetName,
    required DateTime targetDate,
    required String type,
    required bool isCurrentlyActive,
  }) async {
    final auth = ref.read(authProvider);
    final userUid = auth.uid;
    if (userUid == null) return;

    final weekId = ref.read(selectedWeekIdProvider);
    final reminderId = MemberReminder.generateId(
      userUid: userUid,
      weekId: weekId,
      entryId: entryId,
    );

    final repo = ref.read(birthdayRepositoryProvider);

    try {
      if (isCurrentlyActive) {
        await repo.removeReminder(reminderId);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reminder turned off for $targetName'),
            duration: const Duration(seconds: 2),
            backgroundColor: AppColors.primaryBrown,
          ),
        );
      } else {
        final reminder = MemberReminder(
          id: reminderId,
          userUid: userUid,
          weekId: weekId,
          entryId: entryId,
          targetName: targetName,
          targetDate: targetDate,
          type: type,
          isActive: true,
        );
        await repo.setReminder(reminder);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🔔 Reminder set for $targetName!'),
            duration: const Duration(seconds: 2),
            backgroundColor: AppColors.subtleOlive,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update reminder: $e'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isStaff = ref.watch(isStaffUserProvider);
    final weekBulletinAsync = ref.watch(weekBulletinStreamProvider);
    final selectedWeekId = ref.watch(selectedWeekIdProvider);
    final selectedMonday = DateTime.parse(selectedWeekId);
    final selectedSunday = BirthdayAnniversaryWeek.getSundayOf(selectedMonday);
    final weekLabel =
        '${DateFormat('MMM d').format(selectedMonday)} – ${DateFormat('MMM d, y').format(selectedSunday)}';

    final isCurrentWeek = selectedWeekId ==
        BirthdayAnniversaryWeek.generateWeekId(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.backgroundIvory,
      appBar: AppBar(
        title: const Text('Birthdays & Anniversaries'),
        actions: [
          if (isStaff)
            IconButton(
              tooltip: 'Manage Weekly Bulletin',
              icon: const Icon(Icons.edit_calendar_rounded,
                  color: AppColors.primaryBrown),
              onPressed: () {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => ManageBirthdaysDialog(
                    initialWeekId: selectedWeekId,
                  ),
                );
              },
            ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: 600,
          padding: const EdgeInsets.symmetric(horizontal: AppStyles.space16),
          child: Column(
            children: [
              const SizedBox(height: AppStyles.space12),

              // Week Selector Bar
              _buildWeekSelector(
                context,
                ref,
                weekLabel: weekLabel,
                isCurrentWeek: isCurrentWeek,
              ),
              const SizedBox(height: AppStyles.space12),

              // Main Content
              Expanded(
                child: weekBulletinAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryBrown,
                    ),
                  ),
                  error: (err, stack) {
                    if (kDebugMode) {
                      debugPrint('[BirthdaysPage] Error loading week $selectedWeekId: $err\n$stack');
                    }
                    final isPermDenied = err.toString().contains('permission-denied');
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppStyles.space24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isPermDenied ? Icons.lock_outline_rounded : Icons.error_outline_rounded,
                              size: 48,
                              color: isPermDenied ? AppColors.mutedGold : AppColors.errorRed,
                            ),
                            const SizedBox(height: AppStyles.space12),
                            Text(
                              isPermDenied
                                  ? 'Membership Approval Required'
                                  : 'Could Not Load Bulletin',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryBrown,
                              ),
                            ),
                            const SizedBox(height: AppStyles.space8),
                            Text(
                              isPermDenied
                                  ? 'Approved church membership is required to access parish celebration bulletins. If your account was recently approved, please try refreshing your session.'
                                  : 'An error occurred while loading this week\'s bulletin: $err',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  data: (week) {
                    if (week == null) {
                      return _buildUnpublishedOrEmptyWeek(
                        context,
                        ref,
                        isStaff: isStaff,
                        weekId: selectedWeekId,
                      );
                    }

                    return ListView(
                      padding: const EdgeInsets.only(bottom: AppStyles.space32),
                      children: [
                        // Draft Notice for Staff
                        if (isStaff && !week.isPublished) ...[
                          Container(
                            margin: const EdgeInsets.only(
                                bottom: AppStyles.space16),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: AppStyles.roundedMedium,
                              border: Border.all(color: Colors.amber.shade600),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline_rounded,
                                    size: 18, color: Colors.amber.shade900),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Draft Bulletin — Only staff can view this week.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.amber.shade900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // 1. Birthdays Section
                        _buildSectionHeader(
                          icon: Icons.cake_rounded,
                          title: 'Birthdays',
                          count: week.birthdays.length,
                          color: AppColors.primaryBrown,
                        ),
                        const SizedBox(height: AppStyles.space8),
                        if (week.birthdays.isEmpty)
                          _buildEmptyPlaceholder(
                            message: 'No birthdays this week',
                            icon: Icons.cake_outlined,
                          )
                        else
                          ...week.birthdays.map((b) => _buildBirthdayRow(
                                context,
                                ref,
                                entry: b,
                              )),
                        const SizedBox(height: AppStyles.space24),

                        // 2. Wedding Anniversaries Section
                        _buildSectionHeader(
                          icon: Icons.favorite_rounded,
                          title: 'Wedding Anniversaries',
                          count: week.anniversaries.length,
                          color: AppColors.accentWine,
                        ),
                        const SizedBox(height: AppStyles.space8),
                        if (week.anniversaries.isEmpty)
                          _buildEmptyPlaceholder(
                            message: 'No anniversaries this week',
                            icon: Icons.favorite_border_rounded,
                          )
                        else
                          ...week.anniversaries.map((a) => _buildAnniversaryRow(
                                context,
                                ref,
                                entry: a,
                              )),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeekSelector(
    BuildContext context,
    WidgetRef ref, {
    required String weekLabel,
    required bool isCurrentWeek,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: AppStyles.roundedMedium,
        border: Border.all(color: AppColors.softBeige),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            tooltip: 'Previous Week',
            icon: const Icon(Icons.chevron_left_rounded,
                color: AppColors.primaryBrown),
            onPressed: () {
              ref.read(selectedWeekIdProvider.notifier).goToPreviousWeek();
            },
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  weekLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBrown,
                  ),
                ),
                if (!isCurrentWeek)
                  InkWell(
                    onTap: () {
                      ref
                          .read(selectedWeekIdProvider.notifier)
                          .resetToCurrentWeek();
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        'Jump to Current Week',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.mutedGoldDark,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  )
                else
                  const Text(
                    'Current Week',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Next Week',
            icon: const Icon(Icons.chevron_right_rounded,
                color: AppColors.primaryBrown),
            onPressed: () {
              ref.read(selectedWeekIdProvider.notifier).goToNextWeek();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required int count,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: AppStyles.space8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(width: AppStyles.space8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBirthdayRow(
    BuildContext context,
    WidgetRef ref, {
    required BirthdayEntry entry,
  }) {
    final dateStr = DateFormat('d MMM').format(entry.eventDate);
    final isReminderActive = ref.watch(isReminderActiveProvider(entry.id));

    return Container(
      margin: const EdgeInsets.only(bottom: AppStyles.space8),
      padding: const EdgeInsets.all(AppStyles.space12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: AppStyles.roundedMedium,
        border: Border.all(
          color: entry.isToday ? AppColors.mutedGold : AppColors.softBeige,
          width: entry.isToday ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          MemberAvatar(
            imageUrl: entry.profileImageUrl,
            radius: 22,
            backgroundColor: AppColors.surfaceCream,
            iconColor: AppColors.mutedGold,
          ),
          const SizedBox(width: AppStyles.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.memberName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryBrown,
                        ),
                      ),
                    ),
                    if (entry.isToday) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.mutedGold.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'TODAY',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryBrown,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '$dateStr • ${entry.calculatedAge} years${entry.place != null && entry.place!.isNotEmpty ? ' • ${entry.place}' : ''}${entry.familyNumber != null && entry.familyNumber!.isNotEmpty ? ' • #${entry.familyNumber}' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppStyles.space8),

          // Actions Row: Wish (on today, app users only) + Remind me
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (entry.isToday && entry.hasAppAccount) ...[
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.subtleOlive,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.celebration_rounded, size: 14),
                  label: const Text('Wish', style: TextStyle(fontSize: 11)),
                  onPressed: () => _openWishDialog(
                    context,
                    recipientUid: entry.memberUid!,
                    recipientName: entry.memberName,
                    type: 'birthday',
                    eventDate: entry.eventDate,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              IconButton(
                tooltip: isReminderActive
                    ? 'Reminder Active (tap to turn off)'
                    : 'Remind Me',
                icon: Icon(
                  isReminderActive
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_none_rounded,
                  color: isReminderActive
                      ? AppColors.mutedGoldDark
                      : AppColors.textSecondary,
                  size: 20,
                ),
                onPressed: () => _toggleReminder(
                  context,
                  ref,
                  entryId: entry.id,
                  targetName: entry.memberName,
                  targetDate: entry.eventDate,
                  type: 'birthday',
                  isCurrentlyActive: isReminderActive,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnniversaryRow(
    BuildContext context,
    WidgetRef ref, {
    required AnniversaryEntry entry,
  }) {
    final dateStr = DateFormat('d MMM').format(entry.eventDate);
    final isReminderActive = ref.watch(isReminderActiveProvider(entry.id));

    return Container(
      margin: const EdgeInsets.only(bottom: AppStyles.space8),
      padding: const EdgeInsets.all(AppStyles.space12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: AppStyles.roundedMedium,
        border: Border.all(
          color: entry.isToday ? AppColors.accentWine : AppColors.softBeige,
          width: entry.isToday ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          MemberAvatar(
            imageUrl: entry.profileImageUrl,
            radius: 22,
            backgroundColor: AppColors.surfaceCream,
            iconColor: AppColors.accentWine,
          ),
          const SizedBox(width: AppStyles.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.coupleName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryBrown,
                        ),
                      ),
                    ),
                    if (entry.isToday) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.accentWine.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'TODAY',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppColors.accentWine,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '$dateStr • ${entry.formattedAnniversaryOrdinal}${entry.place != null && entry.place!.isNotEmpty ? ' • ${entry.place}' : ''}${entry.familyNumber != null && entry.familyNumber!.isNotEmpty ? ' • #${entry.familyNumber}' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppStyles.space8),

          // Actions Row: Wish (on today, app users only) + Remind me
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (entry.isToday && entry.hasAppAccount) ...[
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentWine,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.favorite_rounded, size: 14),
                  label: const Text('Wish', style: TextStyle(fontSize: 11)),
                  onPressed: () => _openWishDialog(
                    context,
                    recipientUid: entry.primaryRecipientUid!,
                    recipientName: entry.coupleName,
                    type: 'anniversary',
                    eventDate: entry.eventDate,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              IconButton(
                tooltip: isReminderActive
                    ? 'Reminder Active (tap to turn off)'
                    : 'Remind Me',
                icon: Icon(
                  isReminderActive
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_none_rounded,
                  color: isReminderActive
                      ? AppColors.mutedGoldDark
                      : AppColors.textSecondary,
                  size: 20,
                ),
                onPressed: () => _toggleReminder(
                  context,
                  ref,
                  entryId: entry.id,
                  targetName: entry.coupleName,
                  targetDate: entry.eventDate,
                  type: 'anniversary',
                  isCurrentlyActive: isReminderActive,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPlaceholder({
    required String message,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: AppStyles.roundedMedium,
        border: Border.all(color: AppColors.softBeige),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: AppColors.softBeige),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnpublishedOrEmptyWeek(
    BuildContext context,
    WidgetRef ref, {
    required bool isStaff,
    required String weekId,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppStyles.space24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_busy_rounded,
                size: 56, color: AppColors.mutedGold),
            const SizedBox(height: AppStyles.space16),
            Text(
              isStaff
                  ? 'No birthdays or anniversaries have been added for this week yet.'
                  : 'No Published Bulletin For This Week',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryBrown,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isStaff
                  ? 'Click below to create and publish this week\'s parish bulletin.'
                  : 'The parish bulletin for this week has not been published yet.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            if (isStaff) ...[
              const SizedBox(height: AppStyles.space20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBrown,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.add_circle_outline_rounded),
                label: const Text('Create Bulletin For This Week'),
                onPressed: () {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => ManageBirthdaysDialog(
                      initialWeekId: weekId,
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
