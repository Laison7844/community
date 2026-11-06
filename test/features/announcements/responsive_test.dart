import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:communtiy/features/announcements/models/announcement.dart';
import 'package:communtiy/features/announcements/presentation/widgets/announcement_card.dart';
import 'package:communtiy/features/announcements/presentation/announcement_detail_page.dart';
import 'package:communtiy/features/auth/models/auth_state.dart';
import 'package:communtiy/features/auth/models/member_profile.dart';
import 'package:communtiy/features/auth/providers/auth_provider.dart';

class _MockAuthNotifier extends AuthNotifier {
  final AuthState _initial;
  _MockAuthNotifier(this._initial);

  @override
  AuthState build() => _initial;
}

void main() {
  final marriageItem = Announcement(
    id: 'resp_marr_1',
    announcementType: AnnouncementType.marriage,
    title: 'Marriage Announcement — George & Hannah',
    brideName: 'Hannah Jacob',
    brideDetails: 'D/o Mr. & Mrs. Jacob, Kowdiar Parish',
    groomName: 'George Kurian',
    groomDetails: 'S/o Mr. & Mrs. Kurian, Pattom Parish',
    announcementStage: AnnouncementStage.first,
    marriageDate: DateTime(2026, 10, 15),
    isPublished: true,
    createdBy: 'staff',
  );

  final specialItem = Announcement(
    id: 'resp_spec_1',
    announcementType: AnnouncementType.special,
    title: 'Easter Sunday Sunrise Celebration',
    description: 'Join us for dawn worship at 5:30 AM with full parish choir and festive breakfast.',
    scheduledDate: DateTime(2026, 4, 5),
    scheduledTime: '05:30 AM',
    isPublished: true,
    createdBy: 'staff',
  );

  final generalItem = Announcement(
    id: 'resp_gen_1',
    announcementType: AnnouncementType.general,
    title: 'Midweek Bible Study & Intercessory Prayer',
    description: 'Every Wednesday at 6:30 PM in the church fellowship hall.',
    scheduledDate: DateTime(2026, 9, 30),
    scheduledTime: '06:30 PM',
    isPublished: true,
    createdBy: 'staff',
  );

  const resolutions = [
    Size(360, 800),   // Small Mobile
    Size(390, 844),   // Standard Mobile
    Size(430, 932),   // Large Mobile
    Size(768, 1024),  // Tablet
    Size(1280, 800),  // Desktop
    Size(1440, 900),  // Large Desktop
  ];

  for (final size in resolutions) {
    testWidgets('Responsive AnnouncementCard renders without overflow at ${size.width}x${size.height}',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  AnnouncementCard(announcement: marriageItem, onTap: () {}),
                  AnnouncementCard(announcement: specialItem, onTap: () {}),
                  AnnouncementCard(announcement: generalItem, onTap: () {}),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Marriage Announcement'), findsOneWidget);
      expect(find.text('Easter Sunday Sunrise Celebration'), findsOneWidget);
      expect(find.text('Midweek Bible Study & Intercessory Prayer'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Responsive AnnouncementDetailPage renders without overflow at ${size.width}x${size.height}',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(
              () => _MockAuthNotifier(
                const AuthState(
                  isAuthenticated: true,
                  uid: 'test_user_uid',
                  email: 'member@example.com',
                  profile: MemberProfile(
                    uid: 'test_user_uid',
                    fullName: 'Approved Member',
                    familyNumber: '628',
                    profileImageUrl: 'https://example.com/avatar.jpg',
                    email: 'member@example.com',
                    status: MemberStatus.approved,
                  ),
                ),
              ),
            ),
          ],
          child: MaterialApp(
            home: AnnouncementDetailPage(
              announcementId: marriageItem.id,
              preloadedAnnouncement: marriageItem,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Hannah Jacob'), findsOneWidget);
      expect(find.text('George Kurian'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
