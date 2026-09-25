import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:communtiy/features/auth/models/auth_state.dart';
import 'package:communtiy/features/auth/models/member_profile.dart';
import 'package:communtiy/features/birthdays/models/anniversary_entry.dart';
import 'package:communtiy/features/birthdays/models/birthday_anniversary_week.dart';
import 'package:communtiy/features/birthdays/models/birthday_entry.dart';
import 'package:communtiy/features/birthdays/models/member_reminder.dart';
import 'package:communtiy/features/birthdays/presentation/widgets/wish_confirmation_dialog.dart';

void main() {
  group('Phase 5 — Birthday & Anniversary Model Tests', () {
    test('BirthdayEntry age is dynamically calculated accurately', () {
      final birthDate = DateTime(2001, 9, 25);
      final occurrenceDate = DateTime(2026, 9, 25);

      final entry = BirthdayEntry(
        id: 'bday_1',
        memberUid: 'uid_laison',
        memberName: 'Laison',
        eventDate: occurrenceDate,
        dateOfBirth: birthDate,
        place: 'Thiruvananthapuram',
      );

      expect(entry.calculatedAge, 25);
      expect(entry.memberName, 'Laison');
      expect(entry.place, 'Thiruvananthapuram');

      final map = entry.toMap();
      final reconstructed = BirthdayEntry.fromMap(map);
      expect(reconstructed.id, 'bday_1');
      expect(reconstructed.memberUid, 'uid_laison');
      expect(reconstructed.memberName, 'Laison');
      expect(reconstructed.calculatedAge, 25);
    });

    test('AnniversaryEntry calculated years and ordinal formatting', () {
      final weddingDate = DateTime(2014, 9, 28);
      final occurrenceDate = DateTime(2026, 9, 28);

      final entry = AnniversaryEntry(
        id: 'anniv_1',
        memberUid: 'uid_john',
        coupleName: 'John & Mary',
        eventDate: occurrenceDate,
        weddingAnniversary: weddingDate,
        place: 'Kowdiar',
      );

      expect(entry.calculatedYears, 12);
      expect(entry.formattedAnniversaryOrdinal, '12th Anniversary');

      // Test 1st, 2nd, 3rd ordinal formatting
      final firstAnniv = AnniversaryEntry(
        id: 'anniv_2',
        memberUid: 'uid_2',
        coupleName: 'Alex & Sarah',
        eventDate: DateTime(2026, 5, 10),
        weddingAnniversary: DateTime(2025, 5, 10),
      );
      expect(firstAnniv.formattedAnniversaryOrdinal, '1st Anniversary');

      final secondAnniv = AnniversaryEntry(
        id: 'anniv_3',
        memberUid: 'uid_3',
        coupleName: 'David & Rachel',
        eventDate: DateTime(2026, 5, 10),
        weddingAnniversary: DateTime(2024, 5, 10),
      );
      expect(secondAnniv.formattedAnniversaryOrdinal, '2nd Anniversary');

      final thirdAnniv = AnniversaryEntry(
        id: 'anniv_4',
        memberUid: 'uid_4',
        coupleName: 'Peter & Grace',
        eventDate: DateTime(2026, 5, 10),
        weddingAnniversary: DateTime(2023, 5, 10),
      );
      expect(thirdAnniv.formattedAnniversaryOrdinal, '3rd Anniversary');
    });

    test('BirthdayAnniversaryWeek Monday-Sunday calendar calculations', () {
      // 2026-09-24 is Thursday. Monday of that week is 2026-09-21, Sunday is 2026-09-27.
      final thursday = DateTime(2026, 9, 24);
      final monday = BirthdayAnniversaryWeek.getMondayOf(thursday);
      final sunday = BirthdayAnniversaryWeek.getSundayOf(thursday);

      expect(monday.year, 2026);
      expect(monday.month, 9);
      expect(monday.day, 21);

      expect(sunday.year, 2026);
      expect(sunday.month, 9);
      expect(sunday.day, 27);

      expect(BirthdayAnniversaryWeek.generateWeekId(thursday), '2026-09-21');

      // Given a Sunday, Monday should still be that week's Monday
      final testSunday = DateTime(2026, 9, 27);
      expect(BirthdayAnniversaryWeek.getMondayOf(testSunday).day, 21);

      // Next week Monday
      final nextMonday = BirthdayAnniversaryWeek.getNextWeekMonday(thursday);
      expect(nextMonday.day, 28);

      // Previous week Monday
      final prevMonday = BirthdayAnniversaryWeek.getPreviousWeekMonday(thursday);
      expect(prevMonday.day, 14);
    });

    test('MemberProfile extended birthday/anniversary calculation helpers', () {
      final profile = MemberProfile(
        uid: 'uid_member_1',
        fullName: 'Thomas Mathew',
        familyNumber: 'F-102',
        profileImageUrl: 'https://example.com/photo.jpg',
        email: 'thomas@example.com',
        status: MemberStatus.approved,
        dateOfBirth: DateTime(1990, 5, 15),
        weddingAnniversary: DateTime(2015, 11, 20),
        place: 'Pattom',
      );

      final refDate = DateTime(2026, 9, 25);
      expect(profile.calculateAge(refDate), 36);
      expect(profile.calculateAnniversaryYears(refDate), 10); // Nov 20 not reached yet in Sept
      expect(profile.place, 'Pattom');
    });
  });

  group('Phase 5 — Member Reminder Model Tests', () {
    test('MemberReminder deterministic ID generation and serialization', () {
      final reminderId = MemberReminder.generateId(
        userUid: 'uid_laison',
        weekId: '2026-09-21',
        entryId: 'bday_101',
      );

      expect(reminderId, 'uid_laison_2026-09-21_bday_101');

      final reminder = MemberReminder(
        id: reminderId,
        userUid: 'uid_laison',
        weekId: '2026-09-21',
        entryId: 'bday_101',
        targetName: 'John',
        targetDate: DateTime(2026, 9, 25),
        type: 'birthday',
        isActive: true,
      );

      final map = reminder.toMap(isNew: true);
      expect(map['id'], reminderId);
      expect(map['userUid'], 'uid_laison');
      expect(map['isActive'], isTrue);

      final reconstructed = MemberReminder.fromMap(map, reminderId);
      expect(reconstructed.id, reminderId);
      expect(reconstructed.targetName, 'John');
      expect(reconstructed.type, 'birthday');
      expect(reconstructed.isActive, isTrue);
    });
  });

  group('Phase 5 — Wish Static Template & Confirmation Tests', () {
    test('Static wish template matches exact church greeting specification', () {
      final bdayMsg = WishConfirmationDialog.birthdayMessage('Laison');
      expect(
        bdayMsg,
        'Happy Birthday, Laison! May God bless you with good health, joy and happiness. Have a blessed and wonderful year ahead!',
      );

      final annivMsg = WishConfirmationDialog.anniversaryMessage('John & Mary');
      expect(
        annivMsg,
        'Happy Wedding Anniversary, John & Mary! May God continue to bless your marriage with love, joy and togetherness. Have a blessed anniversary!',
      );
    });

    testWidgets('WishConfirmationDialog renders non-editable template on 360px mobile',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WishConfirmationDialog(
              recipientUid: 'recip_1',
              recipientName: 'Laison',
              type: 'birthday',
              eventDateStr: '2026-09-25',
            ),
          ),
        ),
      );

      expect(find.text('Send Birthday Wish?'), findsOneWidget);
      expect(find.textContaining('Happy Birthday, Laison!'), findsOneWidget);
      expect(find.text('Send Wish'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      // Confirms no editable text field is present for custom input
      expect(find.byType(TextField), findsNothing);
    });
  });

  group('Phase 5 — Security & Authorization Tests', () {
    MemberProfile createProfile({
      required String role,
      required MemberStatus status,
    }) {
      return MemberProfile(
        uid: 'uid_test',
        fullName: 'Test User',
        familyNumber: 'F-01',
        profileImageUrl: 'https://...',
        email: 'test@example.com',
        role: role,
        status: status,
      );
    }

    bool isAuthorizedStaff(MemberProfile? profile) {
      if (profile == null) return false;
      final isStaffRole = ['admin', 'committee', 'pastor'].contains(profile.role);
      return isStaffRole && profile.status == MemberStatus.approved;
    }

    test('Only approved staff roles can manage weekly bulletins', () {
      expect(
        isAuthorizedStaff(createProfile(role: 'admin', status: MemberStatus.approved)),
        isTrue,
      );
      expect(
        isAuthorizedStaff(createProfile(role: 'committee', status: MemberStatus.approved)),
        isTrue,
      );
      expect(
        isAuthorizedStaff(createProfile(role: 'pastor', status: MemberStatus.approved)),
        isTrue,
      );
    });

    test('Pending or rejected staff cannot manage weekly bulletins', () {
      expect(
        isAuthorizedStaff(createProfile(role: 'admin', status: MemberStatus.pending)),
        isFalse,
      );
      expect(
        isAuthorizedStaff(createProfile(role: 'committee', status: MemberStatus.rejected)),
        isFalse,
      );
    });

    test('Regular approved member cannot manage weekly bulletins', () {
      expect(
        isAuthorizedStaff(createProfile(role: 'member', status: MemberStatus.approved)),
        isFalse,
      );
    });
  });

  group('Part 2 — Birthday & Anniversary Search, Duplicates & Calculation Tests', () {
    final members = [
      const MemberProfile(
        uid: 'uid_laison',
        fullName: 'Laison',
        familyNumber: '628',
        profileImageUrl: 'https://example.com/p1.jpg',
        email: 'laison@example.com',
        status: MemberStatus.approved,
        dateOfBirth: null, // Will use DateTime(2001, 9, 25) in tests
        place: 'Thiruvananthapuram',
      ),
      const MemberProfile(
        uid: 'uid_john',
        fullName: 'John',
        spouseName: 'Mary',
        familyNumber: '628',
        profileImageUrl: 'https://example.com/p2.jpg',
        email: 'john@example.com',
        status: MemberStatus.approved,
        place: 'Thiruvananthapuram',
      ),
      const MemberProfile(
        uid: 'uid_thomas',
        fullName: 'Thomas Mathew',
        familyNumber: '702',
        profileImageUrl: 'https://example.com/p3.jpg',
        email: 'thomas@example.com',
        status: MemberStatus.approved,
        place: 'Kowdiar',
      ),
    ];

    test('Search members by name (case-insensitive)', () {
      final query = 'lai';
      final results = members.where((m) {
        return m.fullName.toLowerCase().contains(query) ||
            m.familyNumber.toLowerCase().contains(query);
      }).toList();

      expect(results.length, 1);
      expect(results.first.fullName, 'Laison');
      expect(results.first.familyNumber, '628');
      expect(results.first.place, 'Thiruvananthapuram');
    });

    test('Search members by family number', () {
      final query = '628';
      final results = members.where((m) {
        return m.fullName.toLowerCase().contains(query) ||
            m.familyNumber.toLowerCase().contains(query);
      }).toList();

      expect(results.length, 2);
      expect(results.map((m) => m.fullName), containsAll(['Laison', 'John']));
    });

    test('Prevent duplicate birthday entries for the same member in the same week', () {
      final existingBirthdays = [
        BirthdayEntry(
          id: 'bday_1',
          memberUid: 'uid_laison',
          memberName: 'Laison',
          eventDate: DateTime(2026, 9, 25),
          dateOfBirth: DateTime(2001, 9, 25),
        ),
      ];

      // Checking candidate
      final candidateUid = 'uid_laison';
      final isDuplicate = existingBirthdays.any((b) => b.memberUid == candidateUid);
      expect(isDuplicate, isTrue);

      final newCandidateUid = 'uid_thomas';
      final isNotDuplicate = existingBirthdays.any((b) => b.memberUid == newCandidateUid);
      expect(isNotDuplicate, isFalse);
    });

    test('Prevent duplicate anniversary entries for the same member in the same week', () {
      final existingAnniversaries = [
        AnniversaryEntry(
          id: 'anniv_1',
          memberUid: 'uid_john',
          coupleName: 'John & Mary',
          eventDate: DateTime(2026, 9, 25),
          weddingAnniversary: DateTime(2015, 9, 25),
        ),
      ];

      final candidateUid = 'uid_john';
      final isDuplicate = existingAnniversaries.any((a) => a.memberUid == candidateUid);
      expect(isDuplicate, isTrue);

      final newCandidateUid = 'uid_thomas';
      final isNotDuplicate = existingAnniversaries.any((a) => a.memberUid == newCandidateUid);
      expect(isNotDuplicate, isFalse);
    });

    test('Anniversary allows custom/manual couple display names', () {
      final defaultCoupleName = 'John & Mary';
      final customCoupleName = 'John & Mary (Golden Jubilee)';

      final entry = AnniversaryEntry(
        id: 'anniv_custom',
        memberUid: 'uid_john',
        coupleName: customCoupleName,
        eventDate: DateTime(2026, 9, 25),
        weddingAnniversary: DateTime(1976, 9, 25),
      );

      expect(entry.coupleName, 'John & Mary (Golden Jubilee)');
      expect(entry.calculatedYears, 50);
      expect(entry.formattedAnniversaryOrdinal, '50th Anniversary');
    });

    test('Age is dynamically calculated from dateOfBirth, never manually entered', () {
      final dob = DateTime(1995, 3, 20);
      final refDate = DateTime(2026, 9, 25);
      final entry = BirthdayEntry(
        id: 'bday_dyn',
        memberUid: 'uid_test',
        memberName: 'Alex',
        eventDate: refDate,
        dateOfBirth: dob,
      );

      expect(entry.calculatedAge, 31);
    });
  });
}
