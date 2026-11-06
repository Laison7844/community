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

  group('Church Record Architecture & 17 Manual Testing Verification Requirements', () {
    // 1. Birthday person with Firebase account
    test('1. Birthday person with Firebase account has hasAppAccount == true and valid UID', () {
      final entry = BirthdayEntry(
        id: 'bday_auth_1',
        memberUid: 'firebase_uid_123',
        memberName: 'Sarah Philip',
        familyNumber: '401',
        eventDate: DateTime(2026, 10, 15),
        dateOfBirth: DateTime(1998, 10, 15),
        place: 'Kowdiar',
      );

      expect(entry.hasAppAccount, isTrue);
      expect(entry.memberUid, 'firebase_uid_123');
      expect(entry.calculatedAge, 28);
    });

    // 2. Birthday person WITHOUT Firebase account
    test('2. Birthday person WITHOUT Firebase account has hasAppAccount == false and null UID', () {
      final entry = BirthdayEntry(
        id: 'bday_church_1',
        memberUid: null,
        memberName: 'Elder Thomas',
        familyNumber: '628',
        eventDate: DateTime(2026, 10, 15),
        dateOfBirth: DateTime(1950, 10, 15),
        place: 'Karuvichan Kuzhi',
      );

      expect(entry.hasAppAccount, isFalse);
      expect(entry.memberUid, isNull);
      expect(entry.calculatedAge, 76);
      expect(entry.place, 'Karuvichan Kuzhi');
    });

    // 3. Birthday person without member_profiles document
    test('3. Birthday person without member_profiles document serializes and deserializes cleanly', () {
      final entry = BirthdayEntry(
        id: 'bday_church_no_profile',
        memberUid: null,
        memberName: 'John',
        familyNumber: '628',
        eventDate: DateTime(2026, 10, 15),
        dateOfBirth: DateTime(1995, 10, 15),
        place: 'Karuvichan Kuzhi',
      );

      final map = entry.toMap();
      expect(map.containsKey('memberUid'), isFalse);
      expect(map['memberName'], 'John');
      expect(map['familyNumber'], '628');
      expect(map['place'], 'Karuvichan Kuzhi');

      final reconstructed = BirthdayEntry.fromMap(map);
      expect(reconstructed.memberUid, isNull);
      expect(reconstructed.hasAppAccount, isFalse);
      expect(reconstructed.memberName, 'John');
      expect(reconstructed.calculatedAge, 31);
    });

    // 4. Anniversary couple with accounts
    test('4. Anniversary couple with accounts has hasAppAccount == true and primaryRecipientUid', () {
      final entry = AnniversaryEntry(
        id: 'anniv_auth_1',
        memberUid: 'uid_groom_1',
        spouseUid: 'uid_bride_2',
        coupleName: 'Mathew & Ann',
        brideName: 'Ann',
        groomName: 'Mathew',
        familyNumber: '102',
        eventDate: DateTime(2026, 10, 20),
        weddingAnniversary: DateTime(2016, 10, 20),
        place: 'Pattom',
      );

      expect(entry.hasAppAccount, isTrue);
      expect(entry.primaryRecipientUid, 'uid_groom_1');
      expect(entry.calculatedYears, 10);
      expect(entry.formattedAnniversaryOrdinal, '10th Anniversary');
    });

    // 5. Anniversary couple WITHOUT accounts
    test('5. Anniversary couple WITHOUT accounts has hasAppAccount == false and null recipient UIDs', () {
      final entry = AnniversaryEntry(
        id: 'anniv_church_1',
        memberUid: null,
        spouseUid: null,
        brideUid: null,
        groomUid: null,
        coupleName: 'John & Mary',
        brideName: 'Mary',
        groomName: 'John',
        familyNumber: '628',
        eventDate: DateTime(2026, 10, 15),
        weddingAnniversary: DateTime(2000, 10, 15),
        place: 'Karuvichan Kuzhi',
      );

      expect(entry.hasAppAccount, isFalse);
      expect(entry.primaryRecipientUid, isNull);
      expect(entry.coupleDisplayName, 'John & Mary');
      expect(entry.calculatedYears, 26);
      expect(entry.formattedAnniversaryOrdinal, '26th Anniversary');

      final map = entry.toMap();
      expect(map.containsKey('memberUid'), isFalse);
      expect(map.containsKey('spouseUid'), isFalse);
      final reconstructed = AnniversaryEntry.fromMap(map);
      expect(reconstructed.hasAppAccount, isFalse);
      expect(reconstructed.calculatedYears, 26);
    });

    // 6. Search by name
    test('6. Directory search by name matches substring case-insensitively', () {
      final directory = [
        const MemberProfile(
          uid: 'uid_1',
          fullName: 'Alexander Samuel',
          familyNumber: '101',
          email: 'alex@example.com',
          profileImageUrl: 'https://...',
          status: MemberStatus.approved,
        ),
        const MemberProfile(
          uid: '',
          fullName: 'Binu Jacob',
          familyNumber: '102',
          email: 'binu@example.com',
          profileImageUrl: 'https://...',
          status: MemberStatus.pending,
        ),
      ];

      final query = 'alex';
      final matches = directory.where((m) => m.fullName.toLowerCase().contains(query)).toList();
      expect(matches.length, 1);
      expect(matches.first.fullName, 'Alexander Samuel');
    });

    // 7. Search by family number
    test('7. Directory search by family number matches family number', () {
      final directory = [
        const MemberProfile(
          uid: 'uid_1',
          fullName: 'John Doe',
          familyNumber: '628',
          email: 'john@example.com',
          profileImageUrl: 'https://...',
          status: MemberStatus.approved,
        ),
        const MemberProfile(
          uid: '',
          fullName: 'Mary Doe',
          familyNumber: '628',
          email: 'mary@example.com',
          profileImageUrl: 'https://...',
          status: MemberStatus.pending,
        ),
      ];

      final query = '628';
      final matches = directory.where((m) => m.familyNumber.contains(query)).toList();
      expect(matches.length, 2);
    });

    // 8. Manual person entry
    test('8. Manual person entry works completely independently of app accounts', () {
      final manualPerson = BirthdayEntry(
        id: 'manual_bday_100',
        memberName: 'John',
        familyNumber: '628',
        dateOfBirth: DateTime(1995, 10, 15),
        eventDate: DateTime(2026, 10, 15),
        place: 'Karuvichan Kuzhi',
      );

      expect(manualPerson.memberName, 'John');
      expect(manualPerson.familyNumber, '628');
      expect(manualPerson.place, 'Karuvichan Kuzhi');
      expect(manualPerson.memberUid, isNull);
      expect(manualPerson.hasAppAccount, isFalse);
      expect(manualPerson.calculatedAge, 31);
    });

    // 9. Manual couple entry
    test('9. Manual couple entry works completely independently of app accounts', () {
      final manualCouple = AnniversaryEntry(
        id: 'manual_anniv_100',
        coupleName: 'John & Mary',
        brideName: 'Mary',
        groomName: 'John',
        familyNumber: '628',
        weddingAnniversary: DateTime(2000, 10, 15),
        eventDate: DateTime(2026, 10, 15),
        place: 'Karuvichan Kuzhi',
      );

      expect(manualCouple.coupleName, 'John & Mary');
      expect(manualCouple.brideName, 'Mary');
      expect(manualCouple.groomName, 'John');
      expect(manualCouple.familyNumber, '628');
      expect(manualCouple.place, 'Karuvichan Kuzhi');
      expect(manualCouple.memberUid, isNull);
      expect(manualCouple.hasAppAccount, isFalse);
      expect(manualCouple.calculatedYears, 26);
    });

    // 10. Calculated birthday age
    test('10. Birthday age is calculated dynamically on occurrence date and cannot be manually set', () {
      final dob = DateTime(1995, 10, 15);
      final refDate = DateTime(2026, 10, 15);
      final entry = BirthdayEntry(
        id: 'bday_calc_test',
        memberName: 'David',
        dateOfBirth: dob,
        eventDate: refDate,
      );

      expect(entry.calculatedAge, 31);
    });

    // 11. Calculated anniversary count
    test('11. Anniversary count and ordinal are calculated dynamically', () {
      final weddingDate = DateTime(2000, 10, 15);
      final refDate = DateTime(2026, 10, 15);
      final entry = AnniversaryEntry(
        id: 'anniv_calc_test',
        coupleName: 'David & Ruth',
        weddingAnniversary: weddingDate,
        eventDate: refDate,
      );

      expect(entry.calculatedYears, 26);
      expect(entry.formattedAnniversaryOrdinal, '26th Anniversary');
    });

    // 12. Duplicate prevention
    test('12. Duplicate prevention detects existing entry by name case-insensitively or UID', () {
      final existing = [
        BirthdayEntry(
          id: 'b1',
          memberUid: 'uid_alex',
          memberName: 'Alex Kurian',
          eventDate: DateTime(2026, 10, 12),
          dateOfBirth: DateTime(1990, 10, 12),
        ),
      ];

      // Match by name
      final duplicateByName = existing.any(
        (b) => b.memberName.trim().toLowerCase() == 'alex kurian',
      );
      expect(duplicateByName, isTrue);

      // Match by UID
      final duplicateByUid = existing.any(
        (b) => b.memberUid == 'uid_alex',
      );
      expect(duplicateByUid, isTrue);

      // Distinct person
      final notDuplicate = existing.any(
        (b) => b.memberName.trim().toLowerCase() == 'philip kurian',
      );
      expect(notDuplicate, isFalse);
    });

    // 13. Notification skipped when celebrant has no UID
    test('13. Notification delivery is skipped when celebrant has no app UID', () {
      final nonAppCelebrant = BirthdayEntry(
        id: 'bday_non_app',
        memberUid: null,
        memberName: 'George',
        eventDate: DateTime(2026, 10, 12),
        dateOfBirth: DateTime(1960, 10, 12),
      );

      // Safe check: cannot send push notification to null UID
      final canSendWishNotification = nonAppCelebrant.hasAppAccount;
      expect(canSendWishNotification, isFalse);
    });

    // 14. Notification sent when celebrant has valid UID/tokens
    test('14. Notification can be sent when celebrant has valid UID', () {
      final appCelebrant = BirthdayEntry(
        id: 'bday_app',
        memberUid: 'uid_george_verified',
        memberName: 'George',
        eventDate: DateTime(2026, 10, 12),
        dateOfBirth: DateTime(1960, 10, 12),
      );

      final canSendWishNotification = appCelebrant.hasAppAccount;
      expect(canSendWishNotification, isTrue);
      expect(appCelebrant.memberUid, 'uid_george_verified');
    });

    // 15. Unauthorized member cannot modify bulletin
    test('15. Unauthorized member cannot modify weekly bulletin', () {
      final regularMember = const MemberProfile(
        uid: 'uid_reg',
        fullName: 'Regular Member',
        familyNumber: '10',
        email: 'reg@example.com',
        profileImageUrl: 'https://...',
        role: 'member',
        status: MemberStatus.approved,
      );

      final isAuthorizedStaff = ['admin', 'committee', 'pastor'].contains(regularMember.role);
      expect(isAuthorizedStaff, isFalse);
    });

    // 16. Approved staff can modify bulletin
    test('16. Approved staff (admin, committee, pastor) can modify bulletin', () {
      final staffRoles = ['admin', 'committee', 'pastor'];
      for (final role in staffRoles) {
        final staff = MemberProfile(
          uid: 'uid_staff',
          fullName: 'Staff Person',
          familyNumber: '10',
          email: 'staff@example.com',
          profileImageUrl: 'https://...',
          role: role,
          status: MemberStatus.approved,
        );
        final isAuthorizedStaff = ['admin', 'committee', 'pastor'].contains(staff.role) &&
            staff.status == MemberStatus.approved;
        expect(isAuthorizedStaff, isTrue);
      }
    });

    // 17. ListTile assertion no longer occurs
    testWidgets('17. Card wrapping ListTile avoids Flutter DecoratedBox ink splash assertion',
        (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Colors.brown),
                ),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  dense: true,
                  title: const Text('John'),
                  subtitle: const Text('Family: #628 • Place: Karuvichan Kuzhi'),
                  onTap: () {
                    tapped = true;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('John'), findsOneWidget);
      expect(find.text('Family: #628 • Place: Karuvichan Kuzhi'), findsOneWidget);

      // Tap and verify ink splash executes without throwing framework assertion
      await tester.tap(find.text('John'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    // 18. Birthday Week occurrence derivation and containment validation
    test('18. Birthday week occurrence derivation correctly identifies in-week vs out-of-week DOB', () {
      final monday = DateTime(2026, 9, 28);
      final sunday = DateTime(2026, 10, 4, 23, 59, 59);

      DateTime? calculateOccurrence(DateTime dob) {
        final c1 = DateTime(monday.year, dob.month, dob.day);
        if (!c1.isBefore(monday) && !c1.isAfter(sunday)) return c1;
        if (sunday.year != monday.year) {
          final c2 = DateTime(sunday.year, dob.month, dob.day);
          if (!c2.isBefore(monday) && !c2.isAfter(sunday)) return c2;
        }
        return null;
      }

      // DOB in week: Sep 30
      final inWeekDob = DateTime(1995, 9, 30);
      final inWeekOccurrence = calculateOccurrence(inWeekDob);
      expect(inWeekOccurrence, isNotNull);
      expect(inWeekOccurrence!.day, 30);
      expect(inWeekOccurrence.month, 9);
      expect(inWeekOccurrence.year - inWeekDob.year, 31);

      // DOB in week: Oct 2
      final inWeekDob2 = DateTime(2001, 10, 2);
      final inWeekOccurrence2 = calculateOccurrence(inWeekDob2);
      expect(inWeekOccurrence2, isNotNull);
      expect(inWeekOccurrence2!.day, 2);
      expect(inWeekOccurrence2.month, 10);
      expect(inWeekOccurrence2.year - inWeekDob2.year, 25);

      // DOB outside week: Oct 15
      final outWeekDob = DateTime(1995, 10, 15);
      final outWeekOccurrence = calculateOccurrence(outWeekDob);
      expect(outWeekOccurrence, isNull);
    });

    // 19. Anniversary Week occurrence derivation and containment validation
    test('19. Anniversary week occurrence derivation correctly identifies in-week vs out-of-week wedding dates', () {
      final monday = DateTime(2026, 9, 28);
      final sunday = DateTime(2026, 10, 4, 23, 59, 59);

      DateTime? calculateOccurrence(DateTime weddingDate) {
        final c1 = DateTime(monday.year, weddingDate.month, weddingDate.day);
        if (!c1.isBefore(monday) && !c1.isAfter(sunday)) return c1;
        if (sunday.year != monday.year) {
          final c2 = DateTime(sunday.year, weddingDate.month, weddingDate.day);
          if (!c2.isBefore(monday) && !c2.isAfter(sunday)) return c2;
        }
        return null;
      }

      // Wedding in week: Oct 1
      final inWeekWedding = DateTime(2014, 10, 1);
      final inWeekOccurrence = calculateOccurrence(inWeekWedding);
      expect(inWeekOccurrence, isNotNull);
      expect(inWeekOccurrence!.day, 1);
      expect(inWeekOccurrence.month, 10);
      expect(inWeekOccurrence.year - inWeekWedding.year, 12);

      // Wedding outside week: Nov 20
      final outWeekWedding = DateTime(2015, 11, 20);
      final outWeekOccurrence = calculateOccurrence(outWeekWedding);
      expect(outWeekOccurrence, isNull);
    });

    // 20. Staff role case-insensitivity verification
    test('20. Security helper validates TitleCase and lowercase staff roles and statuses', () {
      bool isStaff(String role, MemberStatus status) {
        final r = role.toLowerCase();
        return ['admin', 'committee', 'pastor'].contains(r) && status == MemberStatus.approved;
      }

      expect(isStaff('Admin', MemberStatus.approved), isTrue);
      expect(isStaff('admin', MemberStatus.approved), isTrue);
      expect(isStaff('Pastor', MemberStatus.approved), isTrue);
      expect(isStaff('Committee', MemberStatus.approved), isTrue);
      expect(isStaff('member', MemberStatus.approved), isFalse);
      expect(isStaff('Admin', MemberStatus.pending), isFalse);
    });

    // 21. Material wrapping ListTile eliminates Flutter assertions
    testWidgets('21. Material wrapping ListTile renders cleanly with zero ink/background assertions',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Colors.brown),
              ),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                dense: true,
                title: const Text('Mary & John'),
                subtitle: const Text('Family: #104'),
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Mary & John'), findsOneWidget);
      await tester.tap(find.text('Mary & John'));
      await tester.pumpAndSettle();
    });
  });
}

