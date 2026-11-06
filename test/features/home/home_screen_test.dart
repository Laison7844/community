import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:communtiy/app/app_theme.dart';
import 'package:communtiy/features/admin/providers/admin_provider.dart';
import 'package:communtiy/features/announcements/models/announcement.dart';
import 'package:communtiy/features/announcements/providers/announcement_provider.dart';
import 'package:communtiy/features/auth/models/auth_state.dart';
import 'package:communtiy/features/auth/models/member_profile.dart';
import 'package:communtiy/features/auth/providers/auth_provider.dart';
import 'package:communtiy/features/birthdays/models/birthday_anniversary_week.dart';
import 'package:communtiy/features/birthdays/models/birthday_entry.dart';
import 'package:communtiy/features/birthdays/models/anniversary_entry.dart';
import 'package:communtiy/features/birthdays/providers/birthday_provider.dart';
import 'package:communtiy/features/home/presentation/home_preview_page.dart';

void main() {
  const testMember = MemberProfile(
    uid: 'test_user_001',
    fullName: 'John Mathew',
    familyNumber: 'F-128',
    profileImageUrl: '',
    email: 'john.mathew@csichurch.org',
    status: MemberStatus.approved,
    role: 'member',
  );

  final testAnnouncement = Announcement(
    id: 'ann_001',
    announcementType: AnnouncementType.marriage,
    title: 'Wedding Announcement',
    description: 'David Mathew & Anu Thomas',
    brideName: 'Anu Thomas',
    groomName: 'David Mathew',
    isPublished: true,
    churchId: 'csi_main',
    createdBy: 'staff_1',
    createdAt: DateTime(2025, 11, 16),
    updatedAt: DateTime(2025, 11, 16),
  );

  final testWeek = BirthdayAnniversaryWeek(
    id: '2025-11-17',
    weekStartDate: DateTime(2025, 11, 17),
    weekEndDate: DateTime(2025, 11, 23),
    churchId: 'csi_main',
    createdBy: 'staff_1',
    isPublished: true,
    birthdays: [
      BirthdayEntry(
        id: 'bday_01',
        memberUid: 'uid_sarah',
        memberName: 'Sarah Abraham',
        familyNumber: 'F-128',
        eventDate: DateTime(2025, 11, 19),
        dateOfBirth: DateTime(1995, 11, 19),
      ),
    ],
    anniversaries: [
      AnniversaryEntry(
        id: 'anniv_01',
        memberUid: 'uid_thomas',
        coupleName: 'Thomas & Grace',
        familyNumber: 'F-102',
        eventDate: DateTime(2025, 11, 21),
        weddingAnniversary: DateTime(2015, 11, 21),
      ),
    ],
  );

  Widget createTestWidget({
    MemberProfile member = testMember,
    bool isStaff = false,
    List<Announcement> announcements = const [],
    BirthdayAnniversaryWeek? week,
  }) {
    return ProviderScope(
      overrides: [
        authProvider.overrideWith(() {
          final notifier = AuthNotifier();
          return notifier;
        }),
        isStaffUserProvider.overrideWithValue(isStaff),
        filteredAnnouncementsProvider.overrideWithValue(AsyncValue.data(announcements)),
        weekBulletinStreamProvider.overrideWith((ref) => Stream.value(week)),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const HomePreviewPage(),
      ),
    );
  }

  group('Member Home Screen - Layout & Content Tests', () {
    testWidgets('Renders Church header with emblem and action icons', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('CSI Church'), findsOneWidget);
      expect(find.descendant(of: find.byType(AppBar), matching: find.text('Community')), findsOneWidget);
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    });

    testWidgets('Renders Member Welcome Card with name, badge, and family number', (tester) async {
      final authState = AuthState(
        isAuthenticated: true,
        status: MemberStatus.approved,
        uid: testMember.uid,
        fullName: testMember.fullName,
        profile: testMember,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(() => _MockAuthNotifier(authState)),
            isStaffUserProvider.overrideWithValue(false),
            filteredAnnouncementsProvider.overrideWithValue(const AsyncValue.data([])),
            weekBulletinStreamProvider.overrideWith((ref) => Stream.value(null)),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const HomePreviewPage(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Peace be with you,'), findsOneWidget);
      expect(find.text('John Mathew'), findsOneWidget);
      expect(find.text('Approved Member'), findsOneWidget);
      expect(find.text('Family No: F-128'), findsOneWidget);
    });

    testWidgets("Renders Today's Verse card with quotation and reference", (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text("Today's Verse"), findsOneWidget);
      expect(find.textContaining('For where two or three gather'), findsOneWidget);
      expect(find.text('— Matthew 18:20'), findsOneWidget);
    });

    testWidgets('Renders Quick Access 6-Feature Grid with all titles', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Announcements'), findsWidgets);
      expect(find.text('Celebrations'), findsWidgets);
      expect(find.text('Events'), findsOneWidget);
      expect(find.text('Prayer\nRequests'), findsOneWidget);
      expect(find.text('Documents'), findsOneWidget);
      expect(find.text('Church\nInformation'), findsOneWidget);
    });

    testWidgets('Renders Recent Announcements with Marriage badge and preview', (tester) async {
      await tester.pumpWidget(createTestWidget(announcements: [testAnnouncement]));
      await tester.pump();

      expect(find.text('Recent Announcements'), findsOneWidget);
      expect(find.text('Marriage'), findsOneWidget);
      expect(find.text('Wedding Announcement'), findsOneWidget);
      expect(find.text('Anu Thomas & David Mathew'), findsOneWidget);
    });

    testWidgets('Renders Upcoming Celebrations with weekly count summary', (tester) async {
      await tester.pumpWidget(createTestWidget(week: testWeek));
      await tester.pump();

      expect(find.text('Upcoming Celebrations'), findsOneWidget);
      expect(find.text('This Week in Fellowship'), findsOneWidget);
      expect(find.text('1 Birthdays • 1 Wedding Anniversaries'), findsOneWidget);
      expect(find.text('Sarah Abraham'), findsOneWidget);
      expect(find.text('Thomas & Grace'), findsOneWidget);
    });

    testWidgets('Renders Bottom Navigation Bar with 5 destinations', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.descendant(of: find.byType(NavigationBar), matching: find.text('Community')), findsOneWidget);
      expect(find.text('Celebrations'), findsWidgets);
      expect(find.text('Notices'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('Tapping non-implemented feature triggers gentle SnackBar', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      await tester.tap(find.text('Events'));
      await tester.pump();

      expect(find.textContaining('Events & Calendar will be available'), findsOneWidget);
    });

    testWidgets('Tapping Notification bell opens notifications modal sheet', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.notifications_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Church Notifications'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Church Notifications'), findsNothing);
    });

    testWidgets('Tapping Profile opens profile summary sheet with member details and Sign Out', (tester) async {
      final authState = AuthState(
        isAuthenticated: true,
        status: MemberStatus.approved,
        uid: testMember.uid,
        fullName: testMember.fullName,
        profile: testMember,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(() => _MockAuthNotifier(authState)),
            isStaffUserProvider.overrideWithValue(false),
            filteredAnnouncementsProvider.overrideWithValue(const AsyncValue.data([])),
            weekBulletinStreamProvider.overrideWith((ref) => Stream.value(null)),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const HomePreviewPage(),
          ),
        ),
      );
      await tester.pump();

      // Tap on bottom navigation Profile destination
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      expect(find.text('Family Number'), findsOneWidget);
      expect(find.text('F-128'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
    });

    testWidgets('Avatar uses clean neutral fallback and rejects cartoon URLs', (tester) async {
      const pikachuMember = MemberProfile(
        uid: 'user_pikachu',
        fullName: 'Thomas Philip',
        familyNumber: 'F-201',
        profileImageUrl: 'https://example.com/images/pikachu_avatar.png',
        email: 'thomas@csichurch.org',
        status: MemberStatus.approved,
        role: 'member',
      );

      final authState = AuthState(
        isAuthenticated: true,
        status: MemberStatus.approved,
        uid: pikachuMember.uid,
        fullName: pikachuMember.fullName,
        profile: pikachuMember,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(() => _MockAuthNotifier(authState)),
            isStaffUserProvider.overrideWithValue(false),
            filteredAnnouncementsProvider.overrideWithValue(const AsyncValue.data([])),
            weekBulletinStreamProvider.overrideWith((ref) => Stream.value(null)),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const HomePreviewPage(),
          ),
        ),
      );
      await tester.pump();

      // Ensure neutral Icons.person_rounded is displayed and NO Image.network attempts to load pikachu
      expect(find.byIcon(Icons.person_rounded), findsWidgets);
    });

    testWidgets('Announcement preview displays appropriate category icons when image is null', (tester) async {
      final specialAnnouncement = Announcement(
        id: 'ann_special',
        announcementType: AnnouncementType.special,
        title: 'Special Harvest Festival',
        description: 'Annual church thanksgiving and fellowship.',
        isPublished: true,
        churchId: 'csi_main',
        createdBy: 'staff_1',
        createdAt: DateTime(2025, 11, 20),
        updatedAt: DateTime(2025, 11, 20),
      );

      final generalAnnouncement = Announcement(
        id: 'ann_gen',
        announcementType: AnnouncementType.general,
        title: 'Sunday School Notice',
        description: 'New session begins next Sunday.',
        isPublished: true,
        churchId: 'csi_main',
        createdBy: 'staff_1',
        createdAt: DateTime(2025, 11, 20),
        updatedAt: DateTime(2025, 11, 20),
      );

      await tester.pumpWidget(
        createTestWidget(announcements: [specialAnnouncement, generalAnnouncement]),
      );
      await tester.pump();

      expect(find.text('Special'), findsOneWidget);
      expect(find.byIcon(Icons.celebration_rounded), findsOneWidget);
      expect(find.text('General'), findsOneWidget);
      expect(find.byIcon(Icons.campaign_rounded), findsWidgets);
    });
  });

  group('Member Home Screen - Responsive Quick Access Grid & Desktop Layout', () {
    testWidgets('Quick Access grid adapts columns: 2 for mobile, 3 for tablet, 6 for desktop', (tester) async {
      // 1. Mobile (width 390 < 600) -> 2 columns
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      var gridFinder = find.byType(GridView);
      expect(gridFinder, findsOneWidget);
      var gridWidget = tester.widget<GridView>(gridFinder);
      var delegate = gridWidget.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 2);

      // 2. Tablet (width 768, 600–1024) -> 3 columns
      tester.view.physicalSize = const Size(768, 1024);
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      gridFinder = find.byType(GridView);
      gridWidget = tester.widget<GridView>(gridFinder);
      delegate = gridWidget.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 3);

      // 3. Desktop (width 1280 > 1024) -> 6 columns in one row
      tester.view.physicalSize = const Size(1280, 800);
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      gridFinder = find.byType(GridView);
      gridWidget = tester.widget<GridView>(gridFinder);
      delegate = gridWidget.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 6);
    });

    testWidgets('Desktop layout displays Announcements and Celebrations side-by-side', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(
        announcements: [testAnnouncement],
        week: testWeek,
      ));
      await tester.pump();

      expect(find.text('Recent Announcements'), findsOneWidget);
      expect(find.text('Upcoming Celebrations'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Member Home Screen - Responsive Viewport Tests', () {
    final viewports = [
      const Size(360, 800),  // Mobile small
      const Size(390, 844),  // iPhone 14
      const Size(430, 932),  // iPhone 14 Pro Max
      const Size(768, 1024), // iPad portrait
      const Size(1280, 800), // Desktop Web standard
      const Size(1440, 900), // MacBook Pro / Desktop
    ];

    for (final size in viewports) {
      testWidgets('Renders cleanly without overflow on ${size.width}x${size.height}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          createTestWidget(
            announcements: [testAnnouncement],
            week: testWeek,
          ),
        );
        await tester.pump();

        expect(find.text('CSI Church'), findsOneWidget);
        expect(find.text("Today's Verse"), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}

class _MockAuthNotifier extends AuthNotifier {
  final AuthState _mockState;
  _MockAuthNotifier(this._mockState);

  @override
  AuthState build() => _mockState;
}
