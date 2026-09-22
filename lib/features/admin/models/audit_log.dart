import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a verification audit trail record stored in `verification_audit_logs/{logId}`.
class AuditLog {
  final String id;
  final String targetUid;
  final String targetFullName;
  final String targetFamilyNumber;
  final String previousStatus;
  final String newStatus;
  final String action;
  final String reason;
  final String performedByUid;
  final String performedByRole;
  final DateTime? timestamp;

  const AuditLog({
    required this.id,
    required this.targetUid,
    required this.targetFullName,
    required this.targetFamilyNumber,
    required this.previousStatus,
    required this.newStatus,
    required this.action,
    required this.reason,
    required this.performedByUid,
    required this.performedByRole,
    this.timestamp,
  });

  /// Factory from Map and doc ID
  factory AuditLog.fromMap(Map<String, dynamic> data, String docId) {
    DateTime? parseTimestamp(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return AuditLog(
      id: docId,
      targetUid: data['targetUid'] as String? ?? '',
      targetFullName: data['targetFullName'] as String? ?? '',
      targetFamilyNumber: data['targetFamilyNumber'] as String? ?? '',
      previousStatus: data['previousStatus'] as String? ?? '',
      newStatus: data['newStatus'] as String? ?? '',
      action: data['action'] as String? ?? '',
      reason: data['reason'] as String? ?? '',
      performedByUid: data['performedByUid'] as String? ?? '',
      performedByRole: data['performedByRole'] as String? ?? 'committee',
      timestamp: parseTimestamp(data['timestamp']),
    );
  }

  /// Factory from Firestore document snapshot
  factory AuditLog.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return AuditLog.fromMap(doc.data() ?? {}, doc.id);
  }

  /// Convert to Map for Firestore document insertion
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'targetUid': targetUid,
      'targetFullName': targetFullName,
      'targetFamilyNumber': targetFamilyNumber,
      'previousStatus': previousStatus,
      'newStatus': newStatus,
      'action': action,
      'reason': reason,
      'performedByUid': performedByUid,
      'performedByRole': performedByRole,
      'timestamp': timestamp != null
          ? Timestamp.fromDate(timestamp!)
          : FieldValue.serverTimestamp(),
    };
  }
}
