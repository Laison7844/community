import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../admin/providers/admin_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/birthday_repository.dart';
import '../models/birthday_anniversary_week.dart';
import '../models/member_reminder.dart';

/// Repository Provider for Phase 5 Birthday and Anniversary features
final birthdayRepositoryProvider = Provider<BirthdayRepository>((ref) {
  return BirthdayRepository();
});

/// Tracks the weekId currently being viewed (defaults to current week's Monday)
class SelectedWeekIdNotifier extends Notifier<String> {
  @override
  String build() {
    return BirthdayAnniversaryWeek.generateWeekId(DateTime.now());
  }

  void selectWeek(String weekId) {
    state = weekId;
  }

  void goToNextWeek() {
    final currentMonday = DateTime.parse(state);
    final nextMonday = currentMonday.add(const Duration(days: 7));
    state = BirthdayAnniversaryWeek.generateWeekId(nextMonday);
  }

  void goToPreviousWeek() {
    final currentMonday = DateTime.parse(state);
    final prevMonday = currentMonday.subtract(const Duration(days: 7));
    state = BirthdayAnniversaryWeek.generateWeekId(prevMonday);
  }

  void resetToCurrentWeek() {
    state = BirthdayAnniversaryWeek.generateWeekId(DateTime.now());
  }
}

final selectedWeekIdProvider =
    NotifierProvider<SelectedWeekIdNotifier, String>(SelectedWeekIdNotifier.new);

/// Streams the weekly bulletin for the currently selected weekId.
/// Members only receive the week if it is published; staff receive drafts as well.
final weekBulletinStreamProvider =
    StreamProvider.autoDispose<BirthdayAnniversaryWeek?>((ref) {
  final weekId = ref.watch(selectedWeekIdProvider);
  final isStaff = ref.watch(isStaffUserProvider);
  final repo = ref.watch(birthdayRepositoryProvider);
  return repo.streamWeek(weekId, isStaff: isStaff);
});

/// Streams historical weeks for navigation dropdown / archive.
final historicalWeeksStreamProvider =
    StreamProvider.autoDispose<List<BirthdayAnniversaryWeek>>((ref) {
  final isStaff = ref.watch(isStaffUserProvider);
  final repo = ref.watch(birthdayRepositoryProvider);
  return repo.streamHistoricalWeeks(limit: 12, isStaff: isStaff);
});

/// Streams active personal reminders for the current member and selected week
final memberRemindersStreamProvider =
    StreamProvider.autoDispose<List<MemberReminder>>((ref) {
  final auth = ref.watch(authProvider);
  final userUid = auth.uid;
  if (userUid == null || userUid.isEmpty) {
    return Stream.value([]);
  }
  final weekId = ref.watch(selectedWeekIdProvider);
  final repo = ref.watch(birthdayRepositoryProvider);
  return repo.streamMemberReminders(userUid: userUid, weekId: weekId);
});

/// Derived selector: checks if a reminder is active for a given entryId
final isReminderActiveProvider = Provider.family<bool, String>((ref, entryId) {
  final remindersAsync = ref.watch(memberRemindersStreamProvider);
  return remindersAsync.when(
    data: (list) => list.any((r) => r.entryId == entryId && r.isActive),
    loading: () => false,
    error: (_, _) => false,
  );
});
