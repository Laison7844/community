import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents an immutable audit record for administrative actions on announcements.
class AnnouncementAuditLog {
  final String id;
  final String announcementId;
  final String announcementTitle;
  final String action; // 'create', 'edit', 'publish', 'unpublish', 'delete'
  final String performedByUid;
  final String performedByRole;
  final String? reason;
  final DateTime? timestamp;

  const AnnouncementAuditLog({
    required this.id,
    required this.announcementId,
    required this.announcementTitle,
    required this.action,
    required this.performedByUid,
    required this.performedByRole,
    this.reason,
    this.timestamp,
  });

  /// Factory from Map and doc ID with safe timestamp parsing
  factory AnnouncementAuditLog.fromMap(Map<String, dynamic> data, String docId) {
    DateTime? parseTimestamp(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return AnnouncementAuditLog(
      id: docId,
      announcementId: data['announcementId'] as String? ?? '',
      announcementTitle: data['announcementTitle'] as String? ?? '',
      action: data['action'] as String? ?? '',
      performedByUid: data['performedByUid'] as String? ?? '',
      performedByRole: data['performedByRole'] as String? ?? 'committee',
      reason: data['reason'] as String?,
      timestamp: parseTimestamp(data['timestamp']),
    );
  }

  /// Factory from Firestore DocumentSnapshot
  factory AnnouncementAuditLog.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return AnnouncementAuditLog.fromMap(doc.data() ?? {}, doc.id);
  }

  /// Convert to Map for Firestore append-only write
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'announcementId': announcementId,
      'announcementTitle': announcementTitle,
      'action': action,
      'performedByUid': performedByUid,
      'performedByRole': performedByRole,
      if (reason != null && reason!.trim().isNotEmpty) 'reason': reason!.trim(),
      'timestamp': timestamp != null
          ? Timestamp.fromDate(timestamp!)
          : FieldValue.serverTimestamp(),
    };
  }
}
