import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:communtiy/app/app_theme.dart';
import 'package:communtiy/features/admin/models/audit_log.dart';
import 'package:communtiy/features/admin/presentation/admin_dashboard_page.dart';
import 'package:communtiy/features/admin/presentation/widgets/member_verification_dialog.dart';
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

void main() {
  const adminProfile = MemberProfile(
    uid: 'admin_001',
    fullName: 'Church Administrator',
    familyNumber: 'F-001',
    profileImageUrl: '',
    email: 'admin@csichurch.org',
    status: MemberStatus.approved,
    role: 'admin',
  );

  const committeeProfile = MemberProfile(
    uid: 'committee_001',
    fullName: 'David Secretary',
    familyNumber: 'F-042',
    profileImageUrl: '',
    email: 'secretary@csichurch.org',
    status: MemberStatus.approved,
    role: 'committee',
  );

  const regularMemberProfile = MemberProfile(
    uid: 'member_001',
    fullName: 'Regular Member',
    familyNumber: 'F-100',
    profileImageUrl: '',
    email: 'member@csichurch.org',
    status: MemberStatus.approved,
    role: 'member',
  );

  final testPendingMember = MemberProfile(
    uid: 'applicant_001',
    fullName: 'Abel Thomas',
    familyNumber: 'F-105',
    profileImageUrl: '',
    email: 'abel.thomas@gmail.com',
    status: MemberStatus.pending,
    role: 'member',
    createdAt: DateTime(2025, 11, 6, 10, 0),
  );

  final testApprovedMember = MemberProfile(
    uid: 'approved_001',
    fullName: 'John Mathew',
    familyNumber: 'F-128',
    profileImageUrl: '',
    email: 'john.mathew@csichurch.org',
    status: MemberStatus.approved,
    role: 'member',
    createdAt: DateTime(2025, 10, 1),
  );

  final testAnnouncement = Announcement(
    id: 'ann_wedding_01',
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

  final testAuditLog = AuditLog(
    id: 'log_01',
    targetUid: 'applicant_001',
    targetFullName: 'Abel Thomas',
    targetFamilyNumber: 'F-105',
    previousStatus: 'pending',
    newStatus: 'approved',
    action: 'approved',
    reason: 'Verified parish baptism record',
    performedByUid: 'admin_001',
    performedByRole: 'admin',
    timestamp: DateTime(2025, 11, 6, 11, 30),
  );

  Widget createAdminTestWidget({
    MemberProfile userProfile = adminProfile,
    List<MemberProfile> members = const [],
    List<Announcement> announcements = const [],
    BirthdayAnniversaryWeek? week,
    List<AuditLog> auditLogs = const [],
  }) {
    final authState = AuthState(
      isAuthenticated: true,
      status: userProfile.status,
      uid: userProfile.uid,
      fullName: userProfile.fullName,
      profile: userProfile,
    );

    final isStaff = ['admin', 'committee', 'pastor'].contains(userProfile.role.toLowerCase());

    return ProviderScope(
      overrides: [
        authProvider.overrideWith(() => _MockAuthNotifier(authState)),
        isStaffUserProvider.overrideWithValue(isStaff),
        allMembersStreamProvider.overrideWith((ref) => Stream.value(members)),
        allAnnouncementsStreamProvider.overrideWith((ref) => Stream.value(announcements)),
        weekBulletinStreamProvider.overrideWith((ref) => Stream.value(week)),
        auditLogsStreamProvider.overrideWith((ref) => Stream.value(auditLogs)),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const AdminDashboardPage(),
      ),
    );
  }

  group('Staff / Admin Portal - Security & Access Control Tests', () {
    testWidgets('Denies access to non-staff regular church members with Sign Out option', (tester) async {
      await tester.pumpWidget(createAdminTestWidget(userProfile: regularMemberProfile));
      await tester.pump();

      expect(find.text('Access Denied: Staff Portal'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
      expect(find.text('Return to Church Home'), findsNothing);
    });

    testWidgets('Grants access to authorized administrator', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createAdminTestWidget(userProfile: adminProfile));
      await tester.pump();

      expect(find.text('Access Denied: Staff Portal'), findsNothing);
      expect(find.text('Staff Portal'), findsOneWidget);
      expect(find.text('Dashboard'), findsWidgets);
    });

    testWidgets('Restricts Staff & Roles from non-admin committee role', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createAdminTestWidget(userProfile: committeeProfile));
      await tester.pump();

      await tester.tap(find.text('Staff & Roles'));
      await tester.pumpAndSettle();

      expect(find.text('Restricted to Administrators'), findsOneWidget);
      expect(find.text('Understood'), findsOneWidget);
    });

    testWidgets('Allows administrator to view Staff & Role management info', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createAdminTestWidget(userProfile: adminProfile));
      await tester.pump();

      await tester.tap(find.text('Staff & Roles'));
      await tester.pumpAndSettle();

      expect(find.text('Staff & Role Management'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
    });
  });

  group('Staff / Admin Portal - UI & Structure Tests', () {
    testWidgets('Renders Sidebar with Branding, Staff Portal pill, and Navigation items', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createAdminTestWidget(
        userProfile: adminProfile,
        members: [testPendingMember, testApprovedMember],
      ));
      await tester.pump();

      expect(find.text('CSI Church'), findsOneWidget);
      expect(find.text('Community'), findsOneWidget);
      expect(find.text('Staff Portal'), findsOneWidget);
      expect(find.text('Dashboard'), findsWidgets);
      expect(find.text('Members'), findsOneWidget);
      expect(find.text('Member Verification'), findsOneWidget);
      expect(find.text('Announcements'), findsWidgets);
      expect(find.text('Celebrations'), findsWidgets);
      expect(find.text('Audit & Activity'), findsOneWidget);
      expect(find.text('Sign Out'), findsWidgets);
      expect(find.text('Member View'), findsNothing);
      expect(find.text('Church Member View'), findsNothing);
    });

    testWidgets('Renders Welcome Banner with staff name, role and decorative artwork', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createAdminTestWidget(userProfile: adminProfile));
      await tester.pump();

      expect(find.text('Church Administrator'), findsWidgets);
      expect(find.textContaining('Manage members, announcements and parish activities'), findsOneWidget);
    });

    testWidgets('Renders real Dashboard Statistics cards with real counts', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createAdminTestWidget(
        userProfile: adminProfile,
        members: [testPendingMember, testApprovedMember],
        announcements: [testAnnouncement],
        week: testWeek,
      ));
      await tester.pump();

      expect(find.text('Total Members'), findsOneWidget);
      expect(find.text('Pending Approvals'), findsOneWidget);
      expect(find.text('Approved Members'), findsOneWidget);
      expect(find.text('Awaiting Review'), findsOneWidget);
    });

    testWidgets('Renders Pending Approvals and Recent Announcements cards in Left Column', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createAdminTestWidget(
        userProfile: adminProfile,
        members: [testPendingMember],
        announcements: [testAnnouncement],
      ));
      await tester.pump();

      expect(find.text('Pending Member Approvals'), findsOneWidget);
      expect(find.text('Abel Thomas'), findsOneWidget);
      expect(find.text('Recent Announcements'), findsOneWidget);
      expect(find.text('Wedding Announcement'), findsOneWidget);
      expect(find.text('Anu Thomas & David Mathew'), findsOneWidget);
    });

    testWidgets('Renders Celebrations and Staff Quick Actions in Right Column', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createAdminTestWidget(
        userProfile: adminProfile,
        week: testWeek,
        auditLogs: [testAuditLog],
      ));
      await tester.pump();

      expect(find.text('This Week in Celebrations'), findsOneWidget);
      expect(find.textContaining('1 Birthdays'), findsOneWidget);
      expect(find.textContaining('1 Wedding Anniversaries'), findsOneWidget);
      expect(find.text('Staff Quick Actions'), findsOneWidget);
      expect(find.text('Review Pending Applications'), findsOneWidget);
      expect(find.text('Recent Verification Activity'), findsOneWidget);
    });

    testWidgets('Tapping notification bell opens summary sheet', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createAdminTestWidget(
        userProfile: adminProfile,
        members: [testPendingMember],
      ));
      await tester.pump();

      await tester.tap(find.byTooltip('Church Notifications'));
      await tester.pumpAndSettle();

      expect(find.text('Administrative Notifications'), findsOneWidget);
      expect(find.descendant(of: find.byType(BottomSheet), matching: find.textContaining('Awaiting Review')), findsOneWidget);
    });

    testWidgets('Sidebar navigation switches between Dashboard, Members and Audit Trail views', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createAdminTestWidget(
        userProfile: adminProfile,
        members: [testPendingMember, testApprovedMember],
        auditLogs: [testAuditLog],
      ));
      await tester.pump();

      // 1. Initially on Dashboard
      expect(find.text('Pending Member Approvals'), findsOneWidget);

      // 2. Switch to Members Registry
      await tester.tap(find.text('Members'));
      await tester.pumpAndSettle();

      expect(find.text('Member Management & Verification'), findsOneWidget);
      expect(find.text('MEMBER'), findsOneWidget);
      expect(find.text('Abel Thomas'), findsOneWidget);
      expect(find.text('John Mathew'), findsOneWidget);

      // 3. Switch to Audit & Activity
      await tester.tap(find.text('Audit & Activity'));
      await tester.pumpAndSettle();

      expect(find.text('Verification Audit Trail'), findsOneWidget);
      expect(find.text('Target: Abel Thomas'), findsOneWidget);

      // 4. Switch back to Dashboard
      await tester.tap(find.text('Dashboard'));
      await tester.pumpAndSettle();

      expect(find.text('Pending Member Approvals'), findsOneWidget);
    });
  });

  group('Staff / Admin Portal - Responsive Layout Viewports', () {
    final viewports = [
      const Size(390, 844),   // Mobile iPhone
      const Size(768, 1024),  // iPad portrait
      const Size(1024, 768),  // Tablet landscape
      const Size(1280, 800),  // Standard desktop web
      const Size(1440, 900),  // Large desktop web
    ];

    for (final size in viewports) {
      testWidgets('Renders cleanly without overflow on ${size.width}x${size.height}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          createAdminTestWidget(
            userProfile: adminProfile,
            members: [testPendingMember, testApprovedMember],
            announcements: [testAnnouncement],
            week: testWeek,
            auditLogs: [testAuditLog],
          ),
        );
        await tester.pump();

        if (size.width >= 1024) {
          expect(find.text('Staff Portal'), findsOneWidget);
        } else {
          // On mobile/tablet, drawer button is present
          expect(find.byIcon(Icons.menu_rounded), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Staff / Admin Portal - Member Management & Verification Tests', () {
    testWidgets('Renders Church Members banner, 5 KPI cards, and segmented tabs', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createAdminTestWidget(
        userProfile: adminProfile,
        members: [testPendingMember, testApprovedMember],
      ));
      await tester.pump();

      // Navigate to Members
      await tester.tap(find.text('Members'));
      await tester.pumpAndSettle();

      // Banner
      expect(find.text('Church Members'), findsOneWidget);
      expect(find.textContaining('Manage member registry'), findsOneWidget);

      // 5 KPI Statistics Cards
      expect(find.text('Total Members'), findsWidgets);
      expect(find.text('Pending Review'), findsWidgets);
      expect(find.text('Approved'), findsWidgets);
      expect(find.text('Suspended'), findsWidgets);
      expect(find.text('Rejected'), findsWidgets);

      // Segmented Tabs
      expect(find.text('Member Registry (All)'), findsOneWidget);
      expect(find.text('Pending Verification'), findsWidgets);

      // Table Columns
      expect(find.text('MEMBER'), findsOneWidget);
      expect(find.text('FAMILY NO.'), findsOneWidget);
      expect(find.text('CONTACT INFORMATION'), findsOneWidget);
      expect(find.text('DATE REGISTERED'), findsOneWidget);
      expect(find.text('STATUS'), findsOneWidget);
      expect(find.text('ACTIONS'), findsOneWidget);
    });

    testWidgets('Tapping Pending Verification tab filters to pending applicants only', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createAdminTestWidget(
        userProfile: adminProfile,
        members: [testPendingMember, testApprovedMember],
      ));
      await tester.pump();

      await tester.tap(find.text('Members'));
      await tester.pumpAndSettle();

      // Tap Pending Verification tab
      await tester.tap(find.widgetWithText(InkWell, 'Pending Verification'));
      await tester.pumpAndSettle();

      expect(find.text('Abel Thomas'), findsOneWidget);
      expect(find.text('Review Application'), findsOneWidget);
      expect(find.text('John Mathew'), findsNothing);
    });

    testWidgets('Tapping Review Application opens MemberVerificationDialog', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createAdminTestWidget(
        userProfile: adminProfile,
        members: [testPendingMember],
      ));
      await tester.pump();

      await tester.tap(find.text('Members'));
      await tester.pumpAndSettle();

      // Tap Review Application
      final reviewButtonFinder = find.widgetWithText(ElevatedButton, 'Review Application');
      await tester.ensureVisible(reviewButtonFinder);
      await tester.pumpAndSettle();
      await tester.tap(reviewButtonFinder);
      await tester.pumpAndSettle();

      expect(find.byType(MemberVerificationDialog), findsOneWidget);
      expect(find.text('Applicant Verification Details'), findsOneWidget);
    });

    testWidgets('Displays All Caught Up empty state when no pending applications exist', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createAdminTestWidget(
        userProfile: adminProfile,
        members: [testApprovedMember], // No pending members
      ));
      await tester.pump();

      // Go directly to Member Verification
      await tester.tap(find.text('Member Verification'));
      await tester.pumpAndSettle();

      expect(find.text('All Caught Up!'), findsOneWidget);
      expect(find.text('There are no pending member applications awaiting verification.'), findsOneWidget);
    });
  });
}

class _MockAuthNotifier extends AuthNotifier {
  final AuthState _mockState;
  _MockAuthNotifier(this._mockState);

  @override
  AuthState build() => _mockState;
}
