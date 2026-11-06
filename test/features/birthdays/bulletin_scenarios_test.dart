import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:communtiy/features/auth/models/auth_state.dart';
import 'package:communtiy/features/auth/models/member_profile.dart';
import 'package:communtiy/features/auth/providers/auth_provider.dart';
import 'package:communtiy/features/admin/providers/admin_provider.dart';
import 'package:communtiy/features/birthdays/models/birthday_anniversary_week.dart';
import 'package:communtiy/features/birthdays/models/birthday_entry.dart';
import 'package:communtiy/features/birthdays/models/anniversary_entry.dart';
import 'package:communtiy/features/birthdays/providers/birthday_provider.dart';

void main() {
  group('Phase 6 — Birthday/Anniversary Bulletin Role & State Scenarios', () {
    MemberProfile createProfile({
      required String uid,
      required String role,
      required MemberStatus status,
    }) {
      return MemberProfile(
        uid: uid,
        fullName: 'Test User ($role)',
        familyNumber: 'F-100',
        profileImageUrl: 'https://firebasestorage.googleapis.com/v0/b/church-5d638.appspot.com/o/member_profiles%2F$uid%2Fphoto.jpg',
        email: '$role@csichurch.org',
        role: role,
        status: status,
      );
    }

    test('1. Approved Admin is identified as staff and approved member', () {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => FakeAuthNotifier(
                AuthState(
                  isAuthenticated: true,
                  uid: 'admin_1',
                  status: MemberStatus.approved,
                  profile: createProfile(uid: 'admin_1', role: 'admin', status: MemberStatus.approved),
                ),
              )),
        ],
      );

      expect(container.read(isStaffUserProvider), isTrue);
      expect(container.read(isApprovedMemberProvider), isTrue);
    });

    test('2. Approved Committee Member is identified as staff and approved member', () {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => FakeAuthNotifier(
                AuthState(
                  isAuthenticated: true,
                  uid: 'comm_1',
                  status: MemberStatus.approved,
                  profile: createProfile(uid: 'comm_1', role: 'committee', status: MemberStatus.approved),
                ),
              )),
        ],
      );

      expect(container.read(isStaffUserProvider), isTrue);
      expect(container.read(isApprovedMemberProvider), isTrue);
    });

    test('3. Approved Pastor is identified as staff and approved member', () {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => FakeAuthNotifier(
                AuthState(
                  isAuthenticated: true,
                  uid: 'pastor_1',
                  status: MemberStatus.approved,
                  profile: createProfile(uid: 'pastor_1', role: 'pastor', status: MemberStatus.approved),
                ),
              )),
        ],
      );

      expect(container.read(isStaffUserProvider), isTrue);
      expect(container.read(isApprovedMemberProvider), isTrue);
    });

    test('4. Approved Normal Member is NOT staff but is approved member', () {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => FakeAuthNotifier(
                AuthState(
                  isAuthenticated: true,
                  uid: 'member_1',
                  status: MemberStatus.approved,
                  profile: createProfile(uid: 'member_1', role: 'member', status: MemberStatus.approved),
                ),
              )),
        ],
      );

      expect(container.read(isStaffUserProvider), isFalse);
      expect(container.read(isApprovedMemberProvider), isTrue);
    });

    test('5. Pending Member is neither staff nor approved member and receives safe empty stream', () async {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => FakeAuthNotifier(
                AuthState(
                  isAuthenticated: true,
                  uid: 'pending_1',
                  status: MemberStatus.pending,
                  profile: createProfile(uid: 'pending_1', role: 'member', status: MemberStatus.pending),
                ),
              )),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(isStaffUserProvider), isFalse);
      expect(container.read(isApprovedMemberProvider), isFalse);

      // Keep active subscription to prevent premature auto-dispose
      final sub = container.listen(weekBulletinStreamProvider, (_, _) {});
      addTearDown(sub.close);

      final val = container.read(weekBulletinStreamProvider);
      expect(val.asData?.value, isNull);
    });

    test('6. Draft bulletin is visible to Staff with isPublished == false', () {
      final monday = BirthdayAnniversaryWeek.getMondayOf(DateTime.now());
      final sunday = BirthdayAnniversaryWeek.getSundayOf(monday);
      final draftWeek = BirthdayAnniversaryWeek(
        id: BirthdayAnniversaryWeek.generateWeekId(monday),
        weekStartDate: monday,
        weekEndDate: sunday,
        isPublished: false,
        createdBy: 'admin_1',
        birthdays: [
          BirthdayEntry(
            id: 'b1',
            memberName: 'Test Celebrant',
            eventDate: monday,
            dateOfBirth: DateTime(1990, monday.month, monday.day),
          ),
        ],
      );

      expect(draftWeek.isPublished, isFalse);
      expect(draftWeek.birthdays.length, 1);
    });

    test('7. Published bulletin contains birthdays and anniversaries', () {
      final monday = BirthdayAnniversaryWeek.getMondayOf(DateTime.now());
      final sunday = BirthdayAnniversaryWeek.getSundayOf(monday);
      final publishedWeek = BirthdayAnniversaryWeek(
        id: BirthdayAnniversaryWeek.generateWeekId(monday),
        weekStartDate: monday,
        weekEndDate: sunday,
        isPublished: true,
        createdBy: 'admin_1',
        birthdays: [
          BirthdayEntry(
            id: 'b1',
            memberName: 'Alice',
            eventDate: monday,
            dateOfBirth: DateTime(1995, monday.month, monday.day),
          ),
        ],
        anniversaries: [
          AnniversaryEntry(
            id: 'a1',
            coupleName: 'Bob & Carol',
            eventDate: monday.add(const Duration(days: 2)),
            weddingAnniversary: DateTime(2015, monday.month, monday.day + 2),
          ),
        ],
      );

      expect(publishedWeek.isPublished, isTrue);
      expect(publishedWeek.birthdays.length, 1);
      expect(publishedWeek.anniversaries.length, 1);
      expect(publishedWeek.anniversaries.first.calculatedYears, greaterThanOrEqualTo(0));
    });
  });
}

class FakeAuthNotifier extends AuthNotifier {
  final AuthState _initialState;
  FakeAuthNotifier(this._initialState);

  @override
  AuthState build() => _initialState;
}
