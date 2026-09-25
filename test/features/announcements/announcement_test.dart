import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:communtiy/features/announcements/models/announcement.dart';
import 'package:communtiy/features/announcements/models/announcement_audit_log.dart';
import 'package:communtiy/features/announcements/presentation/widgets/announcement_card.dart';
import 'package:communtiy/features/announcements/providers/announcement_provider.dart';
import 'package:communtiy/features/auth/models/auth_state.dart';
import 'package:communtiy/features/auth/models/member_profile.dart';
import 'package:communtiy/core/utils/validators.dart';
import 'package:communtiy/core/widgets/member_avatar.dart';

void main() {
  group('Announcement Model Tests', () {
    test('Announcement serialization and deserialization', () {
      final now = DateTime(2026, 9, 21, 10, 30);
      final announcement = Announcement(
        id: 'ann_001',
        title: 'Harvest Thanksgiving Service 2026',
        description: 'Join us for our annual Harvest festival service and auction.',
        imageUrl: 'https://firebasestorage.googleapis.com/.../banner.jpg',
        priority: AnnouncementPriority.urgent,
        isPublished: true,
        churchId: 'csi_main',
        createdBy: 'staff_uid_1',
        createdByName: 'Rev. Samuel',
        createdAt: now,
        updatedAt: now,
      );

      final map = announcement.toMap(isNew: true);
      expect(map['id'], 'ann_001');
      expect(map['title'], 'Harvest Thanksgiving Service 2026');
      expect(map['priority'], 'urgent');
      expect(map['isPublished'], isTrue);
      expect(map['churchId'], 'csi_main');
      expect(map['createdBy'], 'staff_uid_1');
      expect(map['createdByName'], 'Rev. Samuel');

      final reconstructed = Announcement.fromMap(map, 'ann_001');
      expect(reconstructed.id, 'ann_001');
      expect(reconstructed.title, 'Harvest Thanksgiving Service 2026');
      expect(reconstructed.priority, AnnouncementPriority.urgent);
      expect(reconstructed.isPublished, isTrue);
      expect(reconstructed.churchId, 'csi_main');
      expect(reconstructed.createdBy, 'staff_uid_1');
    });

    test('AnnouncementPriority parsing and display names', () {
      expect(AnnouncementPriority.fromString('urgent'), AnnouncementPriority.urgent);
      expect(AnnouncementPriority.fromString('high'), AnnouncementPriority.high);
      expect(AnnouncementPriority.fromString('normal'), AnnouncementPriority.normal);
      expect(AnnouncementPriority.fromString('unknown'), AnnouncementPriority.normal);
      expect(AnnouncementPriority.fromString(null), AnnouncementPriority.normal);

      expect(AnnouncementPriority.urgent.displayName, 'Urgent');
      expect(AnnouncementPriority.high.displayName, 'High Priority');
      expect(AnnouncementPriority.normal.displayName, 'General');

      expect(AnnouncementPriority.urgent.toDbString(), 'urgent');
      expect(AnnouncementPriority.high.toDbString(), 'high');
      expect(AnnouncementPriority.normal.toDbString(), 'normal');
    });

    test('Announcement copyWith preserves fields properly', () {
      const original = Announcement(
        id: 'ann_002',
        title: 'Original Title',
        description: 'Original Description',
        priority: AnnouncementPriority.normal,
        isPublished: false,
        createdBy: 'staff_1',
      );

      final updated = original.copyWith(
        title: 'Updated Title',
        isPublished: true,
      );

      expect(updated.id, 'ann_002');
      expect(updated.title, 'Updated Title');
      expect(updated.description, 'Original Description');
      expect(updated.isPublished, isTrue);
      expect(updated.priority, AnnouncementPriority.normal);
    });
  });

  group('Announcement Audit Log Tests', () {
    test('AnnouncementAuditLog serialization and action tracking', () {
      final now = DateTime.now();
      final log = AnnouncementAuditLog(
        id: 'audit_ann_101',
        announcementId: 'ann_001',
        announcementTitle: 'Special Youth Fellowship',
        action: 'publish',
        performedByUid: 'staff_uid_99',
        performedByRole: 'pastor',
        reason: 'Authorized for public congregation view',
        timestamp: now,
      );

      final map = log.toMap();
      expect(map['id'], 'audit_ann_101');
      expect(map['announcementId'], 'ann_001');
      expect(map['announcementTitle'], 'Special Youth Fellowship');
      expect(map['action'], 'publish');
      expect(map['performedByUid'], 'staff_uid_99');
      expect(map['performedByRole'], 'pastor');
      expect(map['reason'], 'Authorized for public congregation view');

      final reconstructed = AnnouncementAuditLog.fromMap(map, 'audit_ann_101');
      expect(reconstructed.id, 'audit_ann_101');
      expect(reconstructed.action, 'publish');
      expect(reconstructed.performedByRole, 'pastor');
    });
  });

  group('Announcement Filter & In-Memory Priority Ordering Tests', () {
    final announcements = [
      Announcement(
        id: '1',
        title: 'General Maintenance',
        description: 'Clean up work',
        priority: AnnouncementPriority.normal,
        isPublished: true,
        createdBy: 'staff',
        createdAt: DateTime(2026, 9, 10),
      ),
      Announcement(
        id: '2',
        title: 'Emergency Relief Appeal',
        description: 'Floods assistance prayer',
        priority: AnnouncementPriority.urgent,
        isPublished: true,
        createdBy: 'staff',
        createdAt: DateTime(2026, 9, 12),
      ),
      Announcement(
        id: '3',
        title: 'Presbytery Meeting Notice',
        description: 'Council gathering',
        priority: AnnouncementPriority.high,
        isPublished: true,
        createdBy: 'staff',
        createdAt: DateTime(2026, 9, 15),
      ),
      Announcement(
        id: '4',
        title: 'Unpublished Committee Draft',
        description: 'Draft budget discussion',
        priority: AnnouncementPriority.normal,
        isPublished: false,
        createdBy: 'staff',
        createdAt: DateTime(2026, 9, 20),
      ),
    ];

    test('Member feed filters out unpublished drafts', () {
      final memberFeed = announcements.where((a) => a.isPublished).toList();
      expect(memberFeed.length, 3);
      expect(memberFeed.any((a) => a.id == '4'), isFalse);
    });

    test('Priority sorting places Urgent first, then High, then Normal', () {
      final list = List<Announcement>.from(announcements);
      list.sort((a, b) {
        final pCompare = b.priority.index.compareTo(a.priority.index);
        if (pCompare != 0) return pCompare;
        return (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0));
      });

      expect(list[0].priority, AnnouncementPriority.urgent);
      expect(list[1].priority, AnnouncementPriority.high);
      expect(list[2].priority, AnnouncementPriority.normal);
      expect(list[3].priority, AnnouncementPriority.normal);
    });

    test('Search filter matches title and description', () {
      final results = announcements.where((a) {
        final query = 'floods';
        return a.title.toLowerCase().contains(query) ||
            a.description.toLowerCase().contains(query);
      }).toList();

      expect(results.length, 1);
      expect(results.first.id, '2');
    });
  });

  group('Announcement Card Widget Tests', () {
    testWidgets('Renders announcement card with type and title', (tester) async {
      final item = Announcement(
        id: 'test_card_1',
        title: 'Sunday Worship Service Schedule',
        description: 'English service at 7:30 AM, Tamil service at 9:30 AM.',
        announcementType: AnnouncementType.general,
        isPublished: true,
        createdBy: 'staff',
        createdAt: DateTime(2026, 9, 21),
      );

      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnnouncementCard(
              announcement: item,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Sunday Worship Service Schedule'), findsOneWidget);
      expect(find.text('GENERAL'), findsOneWidget);
      expect(find.text('Read Details'), findsOneWidget);

      await tester.tap(find.byType(AnnouncementCard));
      expect(tapped, isTrue);
    });
  });

  group('Phase 4 — Announcement Lifecycle & Draft/Publish State Tests', () {
    test('create announcement enforces required fields and church scope', () {
      final newNotice = Announcement(
        id: 'ann_life_1',
        title: 'Easter Sunday Sunrise Service',
        description: 'Join us at 5:30 AM for the dawn resurrection celebration.',
        priority: AnnouncementPriority.high,
        isPublished: true,
        churchId: 'csi_main',
        createdBy: 'staff_pastor_uid',
        createdByName: 'Rev. Emmanuel',
      );

      final map = newNotice.toMap(isNew: true);
      expect(map['id'], 'ann_life_1');
      expect(map['title'], 'Easter Sunday Sunrise Service');
      expect(map['priority'], 'high');
      expect(map['isPublished'], isTrue);
      expect(map['churchId'], 'csi_main');
      expect(map['createdBy'], 'staff_pastor_uid');
      expect(map['createdAt'], isNotNull);
      expect(map['updatedAt'], isNotNull);
    });

    test('draft announcement initializes with isPublished as false', () {
      final draftNotice = Announcement(
        id: 'ann_draft_1',
        title: 'Draft Annual Budget Report',
        description: 'Preliminary financial report awaiting committee review.',
        priority: AnnouncementPriority.normal,
        isPublished: false,
        churchId: 'csi_main',
        createdBy: 'staff_comm_uid',
      );

      expect(draftNotice.isPublished, isFalse);

      final map = draftNotice.toMap(isNew: true);
      expect(map['isPublished'], isFalse);
    });

    test('publish announcement transitions isPublished from false to true', () {
      final draft = Announcement(
        id: 'ann_pub_1',
        title: 'Parish Convention 2026',
        description: 'Speakers and schedule for three-day annual convention.',
        isPublished: false,
        createdBy: 'staff_1',
      );

      expect(draft.isPublished, isFalse);

      // Staff publishes the announcement
      final published = draft.copyWith(isPublished: true);
      expect(published.isPublished, isTrue);
      expect(published.id, draft.id);
      expect(published.title, draft.title);
      expect(published.createdBy, draft.createdBy);
    });

    test('unpublish announcement moves published notice back to draft state', () {
      final published = Announcement(
        id: 'ann_unpub_1',
        title: 'Temporary Notice',
        description: 'Notice that needs temporary retraction for revision.',
        isPublished: true,
        createdBy: 'staff_1',
      );

      expect(published.isPublished, isTrue);

      // Staff unpublishes the announcement
      final unpublished = published.copyWith(isPublished: false);
      expect(unpublished.isPublished, isFalse);
      expect(unpublished.id, published.id);
    });
  });

  group('Phase 4 — Announcement Member Visibility & Staff Filtering Tests', () {
    final sampleAnnouncements = [
      Announcement(
        id: 'pub_1',
        title: 'Published Notice One',
        description: 'Visible to congregation',
        isPublished: true,
        priority: AnnouncementPriority.normal,
        createdBy: 'staff',
      ),
      Announcement(
        id: 'pub_2',
        title: 'Published Notice Two',
        description: 'Urgent prayer bulletin',
        isPublished: true,
        priority: AnnouncementPriority.urgent,
        createdBy: 'staff',
      ),
      Announcement(
        id: 'draft_1',
        title: 'Unpublished Committee Notes',
        description: 'Draft not ready for public release',
        isPublished: false,
        priority: AnnouncementPriority.normal,
        createdBy: 'staff',
      ),
    ];

    test('member only sees published announcements', () {
      // Ordinary member view query simulation: isPublished == true
      final memberVisibleList = sampleAnnouncements
          .where((a) => a.isPublished == true)
          .toList();

      expect(memberVisibleList.length, 2);
      expect(memberVisibleList.any((a) => a.id == 'pub_1'), isTrue);
      expect(memberVisibleList.any((a) => a.id == 'pub_2'), isTrue);
      expect(memberVisibleList.any((a) => a.id == 'draft_1'), isFalse);
    });

    test('staff can manage announcements including drafts', () {
      // Staff view: streamAllAnnouncements includes both drafts and published
      expect(sampleAnnouncements.length, 3);
      expect(sampleAnnouncements.any((a) => a.id == 'draft_1'), isTrue);
    });

    test('staff can filter by AnnouncementStatusFilter', () {
      List<Announcement> applyFilter(AnnouncementStatusFilter filter) {
        return sampleAnnouncements.where((a) {
          if (filter == AnnouncementStatusFilter.published && !a.isPublished) {
            return false;
          }
          if (filter == AnnouncementStatusFilter.draft && a.isPublished) {
            return false;
          }
          return true;
        }).toList();
      }

      expect(applyFilter(AnnouncementStatusFilter.all).length, 3);
      expect(applyFilter(AnnouncementStatusFilter.published).length, 2);
      expect(applyFilter(AnnouncementStatusFilter.draft).length, 1);
      expect(applyFilter(AnnouncementStatusFilter.draft).first.id, 'draft_1');
    });
  });

  group('Phase 4 — Staff Authorization & Access Control Logic Tests', () {
    // Helper replicating isStaffUser authorization rule in Dart with MemberProfile
    bool isAuthorizedStaff({
      required bool isAuthenticated,
      required MemberProfile? profile,
    }) {
      if (!isAuthenticated || profile == null) return false;
      if (profile.status != MemberStatus.approved) return false;
      return ['admin', 'committee', 'pastor'].contains(profile.role.toLowerCase());
    }

    MemberProfile createTestProfile({
      required String role,
      required MemberStatus status,
    }) {
      return MemberProfile(
        uid: 'test_uid',
        fullName: 'Test User',
        familyNumber: 'FAM-001',
        profileImageUrl: 'https://firebasestorage.googleapis.com/.../photo.jpg',
        email: 'test@csichurch.org',
        role: role,
        status: status,
      );
    }

    test('staff roles (admin, committee, pastor) with approved status can manage announcements', () {
      expect(
        isAuthorizedStaff(
          isAuthenticated: true,
          profile: createTestProfile(role: 'admin', status: MemberStatus.approved),
        ),
        isTrue,
      );
      expect(
        isAuthorizedStaff(
          isAuthenticated: true,
          profile: createTestProfile(role: 'committee', status: MemberStatus.approved),
        ),
        isTrue,
      );
      expect(
        isAuthorizedStaff(
          isAuthenticated: true,
          profile: createTestProfile(role: 'pastor', status: MemberStatus.approved),
        ),
        isTrue,
      );
      expect(
        isAuthorizedStaff(
          isAuthenticated: true,
          profile: createTestProfile(role: 'PASTOR', status: MemberStatus.approved),
        ),
        isTrue,
      );
    });

    test('unauthorized member cannot manage announcements', () {
      expect(
        isAuthorizedStaff(
          isAuthenticated: true,
          profile: createTestProfile(role: 'member', status: MemberStatus.approved),
        ),
        isFalse,
      );
      expect(
        isAuthorizedStaff(
          isAuthenticated: true,
          profile: createTestProfile(role: 'guest', status: MemberStatus.approved),
        ),
        isFalse,
      );
    });

    test('pending member with staff role cannot manage announcements until approved', () {
      expect(
        isAuthorizedStaff(
          isAuthenticated: true,
          profile: createTestProfile(role: 'admin', status: MemberStatus.pending),
        ),
        isFalse,
      );
      expect(
        isAuthorizedStaff(
          isAuthenticated: true,
          profile: createTestProfile(role: 'committee', status: MemberStatus.pending),
        ),
        isFalse,
      );
    });

    test('suspended or rejected staff member cannot manage announcements', () {
      expect(
        isAuthorizedStaff(
          isAuthenticated: true,
          profile: createTestProfile(role: 'admin', status: MemberStatus.suspended),
        ),
        isFalse,
      );
      expect(
        isAuthorizedStaff(
          isAuthenticated: true,
          profile: createTestProfile(role: 'pastor', status: MemberStatus.rejected),
        ),
        isFalse,
      );
    });

    test('unauthenticated caller cannot manage announcements', () {
      expect(
        isAuthorizedStaff(isAuthenticated: false, profile: null),
        isFalse,
      );
    });
  });

  group('Phase 4.6 — Usage & Storage Optimization Tests', () {
    test('Image file validator rejects files exceeding 5MB', () {
      final oversizedBytes = 6 * 1024 * 1024;
      final error = Validators.validateImageFile(
        sizeInBytes: oversizedBytes,
        fileName: 'banner.jpg',
      );
      expect(error, contains('5MB'));
    });

    test('Image file validator rejects empty files', () {
      final error = Validators.validateImageFile(
        sizeInBytes: 0,
        fileName: 'photo.png',
      );
      expect(error, contains('empty'));
    });

    test('Image file validator rejects non-image extensions', () {
      final errorPdf = Validators.validateImageFile(
        sizeInBytes: 1024,
        fileName: 'document.pdf',
      );
      expect(errorPdf, contains('supported'));

      final errorExe = Validators.validateImageFile(
        sizeInBytes: 1024,
        fileName: 'script.sh',
      );
      expect(errorExe, contains('supported'));
    });

    test('Image file validator accepts valid JPG, PNG, WEBP within size', () {
      expect(
        Validators.validateImageFile(sizeInBytes: 500000, fileName: 'church.jpg'),
        isNull,
      );
      expect(
        Validators.validateImageFile(sizeInBytes: 500000, fileName: 'pastor.jpeg'),
        isNull,
      );
      expect(
        Validators.validateImageFile(sizeInBytes: 500000, fileName: 'avatar.png'),
        isNull,
      );
      expect(
        Validators.validateImageFile(sizeInBytes: 500000, fileName: 'banner.webp'),
        isNull,
      );
    });

    test('No-op write prevention detects unchanged announcement details', () {
      const existing = Announcement(
        id: 'ann_noop_1',
        title: 'Sunday Service',
        description: 'Join us at 9am',
        priority: AnnouncementPriority.normal,
        isPublished: true,
        imageUrl: 'https://example.com/banner.jpg',
        createdBy: 'staff_1',
      );

      // Simulating edit form state where user changed nothing
      final newTitle = 'Sunday Service';
      final newDescription = 'Join us at 9am';
      final newPriority = AnnouncementPriority.normal;
      final newPublished = true;
      final imageChanged = false;

      final hasChanges = newTitle != existing.title ||
          newDescription != existing.description ||
          newPriority != existing.priority ||
          newPublished != existing.isPublished ||
          imageChanged;

      expect(hasChanges, isFalse);
    });

    test('No-op write prevention detects changed fields', () {
      const existing = Announcement(
        id: 'ann_noop_2',
        title: 'Sunday Service',
        description: 'Join us at 9am',
        priority: AnnouncementPriority.normal,
        isPublished: true,
        imageUrl: 'https://example.com/banner.jpg',
        createdBy: 'staff_1',
      );

      // Changing only title
      final titleChanged = 'Sunday Divine Service' != existing.title;
      expect(titleChanged, isTrue);

      // Changing priority
      final priorityChanged = AnnouncementPriority.urgent != existing.priority;
      expect(priorityChanged, isTrue);

      // Removing image
      final imageRemoved = null != existing.imageUrl;
      expect(imageRemoved, isTrue);
    });

    testWidgets('MemberAvatar renders fallback placeholder when URL is null',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MemberAvatar(imageUrl: null, radius: 24),
          ),
        ),
      );

      expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    });
  });

  group('Phase 4 Update — Announcement Types, Stages & Visibility Expiration Tests', () {
    test('Marriage announcement model serialization with bride/groom and stages', () {
      final marriageDate = DateTime(2026, 9, 30);
      final marriageAnn = Announcement(
        id: 'ann_marr_1',
        announcementType: AnnouncementType.marriage,
        title: 'Marriage Announcement — John & Sarah',
        brideName: 'Sarah Thomas',
        brideDetails: 'D/o Mr. & Mrs. Thomas, Kowdiar Parish',
        groomName: 'John Mathew',
        groomDetails: 'S/o Mr. & Mrs. Mathew, Pattom Parish',
        announcementStage: AnnouncementStage.first,
        marriageDate: marriageDate,
        isPublished: true,
        createdBy: 'staff_uid',
      );

      expect(marriageAnn.isMarriage, isTrue);
      expect(marriageAnn.announcementStage?.displayName, '1st Announcement');
      expect(marriageAnn.brideName, 'Sarah Thomas');
      expect(marriageAnn.groomName, 'John Mathew');

      final map = marriageAnn.toMap(isNew: true);
      expect(map['announcementType'], 'marriage');
      expect(map['brideName'], 'Sarah Thomas');
      expect(map['groomName'], 'John Mathew');
      expect(map['announcementStage'], '1st Announcement');
      expect(map['marriageDate'], isNotNull);

      final reconstructed = Announcement.fromMap(map, 'ann_marr_1');
      expect(reconstructed.announcementType, AnnouncementType.marriage);
      expect(reconstructed.brideName, 'Sarah Thomas');
      expect(reconstructed.groomName, 'John Mathew');
      expect(reconstructed.announcementStage, AnnouncementStage.first);
    });

    test('Marriage announcement stages format correctly (1st, 2nd, 3rd)', () {
      expect(AnnouncementStage.first.displayName, '1st Announcement');
      expect(AnnouncementStage.second.displayName, '2nd Announcement');
      expect(AnnouncementStage.third.displayName, '3rd Announcement');
      expect(AnnouncementStage.fromValue('first'), AnnouncementStage.first);
      expect(AnnouncementStage.fromValue('second'), AnnouncementStage.second);
      expect(AnnouncementStage.fromValue('third'), AnnouncementStage.third);
    });

    test('Marriage announcement visibility: disappears exactly 1 day before marriage', () {
      // Marriage Date: September 30, 2026
      final marriageDate = DateTime(2026, 9, 30);
      final marriageAnn = Announcement(
        id: 'ann_marr_vis',
        announcementType: AnnouncementType.marriage,
        title: 'Marriage Announcement',
        marriageDate: marriageDate,
        isPublished: true,
        createdBy: 'staff_uid',
      );

      // Sept 28 at 23:59:59 (2 days before) -> VISIBLE
      final sept28 = DateTime(2026, 9, 28, 23, 59, 59);
      expect(marriageAnn.isVisibleForMembers(sept28), isTrue);

      // Sept 29 at 00:00:00 (1 day before) -> NOT VISIBLE
      final sept29Start = DateTime(2026, 9, 29, 0, 0, 0);
      expect(marriageAnn.isVisibleForMembers(sept29Start), isFalse);

      // Sept 29 at 14:00:00 (1 day before afternoon) -> NOT VISIBLE
      final sept29Mid = DateTime(2026, 9, 29, 14, 0, 0);
      expect(marriageAnn.isVisibleForMembers(sept29Mid), isFalse);

      // Sept 30 (Marriage Day) -> NOT VISIBLE
      final sept30 = DateTime(2026, 9, 30, 10, 0, 0);
      expect(marriageAnn.isVisibleForMembers(sept30), isFalse);

      // Oct 1 (After Marriage) -> NOT VISIBLE
      final oct1 = DateTime(2026, 10, 1, 9, 0, 0);
      expect(marriageAnn.isVisibleForMembers(oct1), isFalse);
    });

    test('General announcement visibility: disappears after scheduled date/time', () {
      final scheduledDate = DateTime(2026, 9, 25);
      const scheduledTime = '10:00 AM';

      final generalAnn = Announcement(
        id: 'ann_gen_1',
        announcementType: AnnouncementType.general,
        title: 'Youth Fellowship Meeting',
        scheduledDate: scheduledDate,
        scheduledTime: scheduledTime,
        isPublished: true,
        createdBy: 'staff_uid',
      );

      // 9:30 AM before event -> VISIBLE
      final beforeTime = DateTime(2026, 9, 25, 9, 30);
      expect(generalAnn.isVisibleForMembers(beforeTime), isTrue);

      // 10:30 AM after event -> NOT VISIBLE
      final afterTime = DateTime(2026, 9, 25, 10, 30);
      expect(generalAnn.isVisibleForMembers(afterTime), isFalse);
    });

    test('Special announcement visibility: disappears after scheduled date/time', () {
      final scheduledDate = DateTime(2026, 12, 25);
      const scheduledTime = '06:00 PM';

      final specialAnn = Announcement(
        id: 'ann_spec_1',
        announcementType: AnnouncementType.special,
        title: 'Christmas Eve Carol Service',
        scheduledDate: scheduledDate,
        scheduledTime: scheduledTime,
        isPublished: true,
        createdBy: 'staff_uid',
      );

      expect(specialAnn.isSpecial, isTrue);

      // Dec 24 -> VISIBLE
      final dayBefore = DateTime(2026, 12, 24, 18, 0);
      expect(specialAnn.isVisibleForMembers(dayBefore), isTrue);

      // Dec 26 -> NOT VISIBLE
      final dayAfter = DateTime(2026, 12, 26, 9, 0);
      expect(specialAnn.isVisibleForMembers(dayAfter), isFalse);
    });

    test('Unpublished announcements are never visible to members', () {
      final draft = Announcement(
        id: 'ann_draft_vis',
        announcementType: AnnouncementType.general,
        title: 'Draft Notice',
        isPublished: false,
        createdBy: 'staff_uid',
      );

      expect(draft.isVisibleForMembers(DateTime(2026, 9, 25)), isFalse);
    });

    testWidgets('Marriage announcement card renders bride, groom and stage badge',
        (tester) async {
      final marriageItem = Announcement(
        id: 'card_marriage_1',
        announcementType: AnnouncementType.marriage,
        title: 'Marriage Announcement — George & Hannah',
        brideName: 'Hannah Jacob',
        groomName: 'George Kurian',
        announcementStage: AnnouncementStage.first,
        marriageDate: DateTime(2026, 10, 15),
        isPublished: true,
        createdBy: 'staff',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnnouncementCard(
              announcement: marriageItem,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Marriage Announcement'), findsOneWidget);
      expect(find.text('1st Announcement'), findsOneWidget);
      expect(find.text('Bride: Hannah Jacob'), findsOneWidget);
      expect(find.text('Groom: George Kurian'), findsOneWidget);
      expect(find.text('Marriage Date: 15 Oct 2026'), findsOneWidget);
    });
  });
}
