import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/models/auth_state.dart';
import '../../auth/models/member_profile.dart';
import '../models/audit_log.dart';

/// Repository for staff administrative verification operations:
/// - Viewing applicants
/// - Searching shared family numbers
/// - Executing status transitions with atomic audit trails
class AdminRepository {
  final FirebaseFirestore? _customFirestore;
  static const String profilesCollection = 'member_profiles';
  static const String auditCollection = 'verification_audit_logs';

  AdminRepository({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _profiles =>
      _firestore.collection(profilesCollection);

  CollectionReference<Map<String, dynamic>> get _auditLogs =>
      _firestore.collection(auditCollection);

  /// Streams member profiles filtered by approval status
  Stream<List<MemberProfile>> streamMembersByStatus(MemberStatus status) {
    final statusStr = MemberProfile.statusToString(status);
    return _profiles
        .where('status', isEqualTo: statusStr)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => MemberProfile.fromMap(doc.data(), uid: doc.id))
          .toList();
      // Sort newest first
      list.sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      return list;
    });
  }

  /// Streams all member profiles for dashboard counts and search
  Stream<List<MemberProfile>> streamAllMembers() {
    return _profiles.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => MemberProfile.fromMap(doc.data(), uid: doc.id))
          .toList();
      list.sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      return list;
    });
  }

  /// Validates whether a status transition is permitted by policy
  static bool isValidStatusTransition(MemberStatus current, MemberStatus target) {
    if (current == target) return false;

    switch (current) {
      case MemberStatus.pending:
        // Pending can be Approved or Rejected
        return target == MemberStatus.approved || target == MemberStatus.rejected;
      case MemberStatus.approved:
        // Approved member can be Suspended
        return target == MemberStatus.suspended;
      case MemberStatus.suspended:
        // Suspended member can be Re-approved (restored)
        return target == MemberStatus.approved;
      case MemberStatus.rejected:
        // Rejected applicant can be reconsidered to pending or approved
        return target == MemberStatus.pending || target == MemberStatus.approved;
      case MemberStatus.none:
        return false;
    }
  }

  /// Executes an atomic status transition on a member profile and creates an append-only audit log
  Future<void> executeStatusTransition({
    required MemberProfile targetMember,
    required MemberStatus newStatus,
    required String reason,
    required String performedByUid,
    required String performedByRole,
  }) async {
    if (!isValidStatusTransition(targetMember.status, newStatus)) {
      throw 'Invalid status transition from ${MemberProfile.statusToString(targetMember.status)} to ${MemberProfile.statusToString(newStatus)}.';
    }

    final batch = _firestore.batch();

    // 1. Update member profile status
    final memberRef = _profiles.doc(targetMember.uid);
    batch.update(memberRef, {
      'status': MemberProfile.statusToString(newStatus),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 2. Create append-only verification audit log record
    final auditRef = _auditLogs.doc();
    final actionName = newStatus == MemberStatus.approved
        ? (targetMember.status == MemberStatus.suspended ? 'restore' : 'approve')
        : (newStatus == MemberStatus.suspended
            ? 'suspend'
            : (newStatus == MemberStatus.pending ? 'reconsider' : 'reject'));

    final auditEntry = AuditLog(
      id: auditRef.id,
      targetUid: targetMember.uid,
      targetFullName: targetMember.fullName,
      targetFamilyNumber: targetMember.familyNumber,
      previousStatus: MemberProfile.statusToString(targetMember.status),
      newStatus: MemberProfile.statusToString(newStatus),
      action: actionName,
      reason: reason.trim().isEmpty ? 'Committee review verification' : reason.trim(),
      performedByUid: performedByUid,
      performedByRole: performedByRole,
    );

    batch.set(auditRef, auditEntry.toMap());

    // Commit both operations atomically
    try {
      await batch.commit();
    } on FirebaseException catch (e) {
      throw 'Failed to execute status update: ${e.message ?? e.code}';
    } catch (e) {
      throw 'An error occurred while updating member approval status.';
    }
  }

  /// Streams recent verification audit logs
  Stream<List<AuditLog>> streamAuditLogs({int limit = 50}) {
    return _auditLogs
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => AuditLog.fromFirestore(doc)).toList();
    });
  }
}
