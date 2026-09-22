import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:communtiy/features/announcements/models/announcement.dart';
import 'package:communtiy/features/announcements/models/announcement_audit_log.dart';
import 'package:communtiy/features/announcements/presentation/widgets/announcement_card.dart';

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
    testWidgets('Renders announcement card with priority and title', (tester) async {
      final item = Announcement(
        id: 'test_card_1',
        title: 'Sunday Worship Service Schedule',
        description: 'English service at 7:30 AM, Tamil service at 9:30 AM.',
        priority: AnnouncementPriority.high,
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
      expect(find.text('HIGH PRIORITY'), findsOneWidget);
      expect(find.text('Read Details'), findsOneWidget);

      await tester.tap(find.byType(AnnouncementCard));
      expect(tapped, isTrue);
    });
  });
}
