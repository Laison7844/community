import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/data/storage_repository.dart';
import '../models/announcement.dart';
import '../models/announcement_audit_log.dart';

/// Repository for Firestore announcement queries, staff mutations, and atomic audit trails.
class AnnouncementRepository {
  final FirebaseFirestore? _customFirestore;
  static const String collectionName = 'announcements';
  static const String auditCollectionName = 'announcement_audit_logs';

  AnnouncementRepository({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _announcements =>
      _firestore.collection(collectionName);

  CollectionReference<Map<String, dynamic>> get _auditLogs =>
      _firestore.collection(auditCollectionName);

  /// Streams published announcements for church members (sorted newest first, bounded by limit).
  /// Required by security rules: members can only read docs where isPublished == true.
  /// Automatically excludes expired marriage, general, and special announcements.
  Stream<List<Announcement>> streamPublishedAnnouncements({int limit = 50}) {
    return _announcements
        .where('isPublished', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();
      final list = snapshot.docs
          .map((doc) => Announcement.fromMap(doc.data(), doc.id))
          .where((a) => a.isVisibleForMembers(now))
          .toList();

      // Sort: Special celebrations highlighted first, then chronological newest first
      list.sort((a, b) {
        if (a.announcementType == AnnouncementType.special &&
            b.announcementType != AnnouncementType.special) {
          return -1;
        }
        if (b.announcementType == AnnouncementType.special &&
            a.announcementType != AnnouncementType.special) {
          return 1;
        }
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

      return list;
    });
  }

  /// Streams announcements including drafts for Staff view (bounded by limit).
  Stream<List<Announcement>> streamAllAnnouncements({int limit = 100}) {
    return _announcements
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => Announcement.fromMap(doc.data(), doc.id))
          .toList();

      list.sort((a, b) {
        final pCompare = b.priority.index.compareTo(a.priority.index);
        if (pCompare != 0) return pCompare;
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

      return list;
    });
  }

  /// Fetches a single announcement by ID
  Future<Announcement?> getAnnouncementById(String id) async {
    final doc = await _announcements.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return Announcement.fromMap(doc.data()!, doc.id);
  }

  /// Generates a new unique announcement ID
  String generateAnnouncementId() {
    return _announcements.doc().id;
  }

  /// Atomically creates an announcement and its audit log record
  Future<void> createAnnouncement({
    required Announcement announcement,
    required String performedByUid,
    required String performedByRole,
    String? reason,
  }) async {
    final batch = _firestore.batch();

    // 1. Create announcement document
    final docRef = _announcements.doc(announcement.id);
    batch.set(docRef, announcement.toMap(isNew: true));

    // 2. Create audit log record
    final auditRef = _auditLogs.doc();
    final auditLog = AnnouncementAuditLog(
      id: auditRef.id,
      announcementId: announcement.id,
      announcementTitle: announcement.title,
      action: 'create',
      performedByUid: performedByUid,
      performedByRole: performedByRole,
      reason: reason ?? 'Created new announcement: "${announcement.title}"',
    );
    batch.set(auditRef, auditLog.toMap());

    try {
      await batch.commit();
    } on FirebaseException catch (e) {
      throw 'Failed to create announcement: ${e.message ?? e.code}';
    } catch (e) {
      throw 'An unexpected error occurred while creating the announcement.';
    }
  }

  /// Atomically updates an announcement and creates an audit log record
  Future<void> updateAnnouncement({
    required Announcement announcement,
    required String performedByUid,
    required String performedByRole,
    String? reason,
  }) async {
    final batch = _firestore.batch();

    // 1. Update announcement document
    final docRef = _announcements.doc(announcement.id);
    batch.update(docRef, announcement.toMap(isNew: false));

    // 2. Create audit log record
    final auditRef = _auditLogs.doc();
    final auditLog = AnnouncementAuditLog(
      id: auditRef.id,
      announcementId: announcement.id,
      announcementTitle: announcement.title,
      action: 'edit',
      performedByUid: performedByUid,
      performedByRole: performedByRole,
      reason: reason ?? 'Updated announcement: "${announcement.title}"',
    );
    batch.set(auditRef, auditLog.toMap());

    try {
      await batch.commit();
    } on FirebaseException catch (e) {
      throw 'Failed to update announcement: ${e.message ?? e.code}';
    } catch (e) {
      throw 'An unexpected error occurred while updating the announcement.';
    }
  }

  /// Atomically toggles publish status and records an audit log entry
  Future<void> togglePublishStatus({
    required String announcementId,
    required String announcementTitle,
    required bool isPublished,
    required String performedByUid,
    required String performedByRole,
  }) async {
    final batch = _firestore.batch();

    // 1. Update publish flag
    final docRef = _announcements.doc(announcementId);
    batch.update(docRef, {
      'isPublished': isPublished,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 2. Create audit log record
    final auditRef = _auditLogs.doc();
    final action = isPublished ? 'publish' : 'unpublish';
    final auditLog = AnnouncementAuditLog(
      id: auditRef.id,
      announcementId: announcementId,
      announcementTitle: announcementTitle,
      action: action,
      performedByUid: performedByUid,
      performedByRole: performedByRole,
      reason: '${action.toUpperCase()} announcement: "$announcementTitle"',
    );
    batch.set(auditRef, auditLog.toMap());

    try {
      await batch.commit();
    } on FirebaseException catch (e) {
      throw 'Failed to update publication status: ${e.message ?? e.code}';
    } catch (e) {
      throw 'An unexpected error occurred while changing publication status.';
    }
  }

  /// Deletes an announcement, cleans up Storage banner image safely, and records an audit log
  Future<void> deleteAnnouncement({
    required String announcementId,
    required String announcementTitle,
    required String performedByUid,
    required String performedByRole,
    String? reason,
    StorageRepository? storageRepo,
  }) async {
    // 1. Best-effort Storage cleanup: safely delete banner image if it exists
    if (storageRepo != null) {
      await storageRepo.deleteAnnouncementImage(announcementId);
    }

    // 2. Atomically delete announcement doc and write audit log
    final batch = _firestore.batch();
    final docRef = _announcements.doc(announcementId);
    batch.delete(docRef);

    final auditRef = _auditLogs.doc();
    final auditLog = AnnouncementAuditLog(
      id: auditRef.id,
      announcementId: announcementId,
      announcementTitle: announcementTitle,
      action: 'delete',
      performedByUid: performedByUid,
      performedByRole: performedByRole,
      reason: reason ?? 'Deleted announcement: "$announcementTitle"',
    );
    batch.set(auditRef, auditLog.toMap());

    try {
      await batch.commit();
    } on FirebaseException catch (e) {
      throw 'Failed to delete announcement: ${e.message ?? e.code}';
    } catch (e) {
      throw 'An unexpected error occurred while deleting the announcement.';
    }
  }

  /// Streams announcement audit logs (for authorized staff inspection)
  Stream<List<AnnouncementAuditLog>> streamAuditLogs({int limit = 50}) {
    return _auditLogs
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AnnouncementAuditLog.fromFirestore(doc))
          .toList();
    });
  }
}
