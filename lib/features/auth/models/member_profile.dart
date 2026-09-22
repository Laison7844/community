import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_state.dart';

/// Represents a church member profile stored in Cloud Firestore (`member_profiles/{uid}`).
class MemberProfile {
  final String uid;
  final String fullName;          // Official name matching church registry
  final String familyNumber;       // Shared family number (e.g. F-104)
  final String profileImageUrl;   // Storage URL for mandatory member photo
  final String email;
  final String? phone;
  final String? familyInfo;        // Additional unit / parish notes
  final MemberStatus status;
  final String role;
  final String churchId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MemberProfile({
    required this.uid,
    required this.fullName,
    required this.familyNumber,
    required this.profileImageUrl,
    required this.email,
    this.phone,
    this.familyInfo,
    this.status = MemberStatus.pending,
    this.role = 'member',
    this.churchId = 'csi_main',
    this.createdAt,
    this.updatedAt,
  });

  bool get isApproved => status == MemberStatus.approved;
  bool get isPending => status == MemberStatus.pending;
  bool get isSuspended => status == MemberStatus.suspended;
  bool get isRejected => status == MemberStatus.rejected;

  /// Helper to convert Firestore string representation to MemberStatus enum
  static MemberStatus statusFromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'approved':
        return MemberStatus.approved;
      case 'rejected':
        return MemberStatus.rejected;
      case 'suspended':
        return MemberStatus.suspended;
      case 'pending':
      default:
        return MemberStatus.pending;
    }
  }

  /// Helper to convert MemberStatus enum to Firestore string
  static String statusToString(MemberStatus status) {
    switch (status) {
      case MemberStatus.approved:
        return 'approved';
      case MemberStatus.rejected:
        return 'rejected';
      case MemberStatus.suspended:
        return 'suspended';
      case MemberStatus.pending:
      case MemberStatus.none:
        return 'pending';
    }
  }

  /// Create a MemberProfile from Firestore document snapshot/map
  factory MemberProfile.fromMap(Map<String, dynamic> map, {required String uid}) {
    DateTime? parseTimestamp(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return MemberProfile(
      uid: uid,
      fullName: (map['fullName'] as String?)?.trim() ?? '',
      familyNumber: (map['familyNumber'] as String?)?.trim() ?? '',
      profileImageUrl: (map['profileImageUrl'] as String?)?.trim() ?? '',
      email: (map['email'] as String?)?.trim() ?? '',
      phone: map['phone'] as String?,
      familyInfo: map['familyInfo'] as String?,
      status: statusFromString(map['status'] as String?),
      role: (map['role'] as String?) ?? 'member',
      churchId: (map['churchId'] as String?) ?? 'csi_main',
      createdAt: parseTimestamp(map['createdAt']),
      updatedAt: parseTimestamp(map['updatedAt']),
    );
  }

  /// Convert MemberProfile to a Map for Firestore write operations.
  Map<String, dynamic> toMap({bool isNew = false}) {
    final map = <String, dynamic>{
      'uid': uid,
      'fullName': fullName,
      'familyNumber': familyNumber,
      'profileImageUrl': profileImageUrl,
      'email': email,
      'phone': phone,
      'familyInfo': familyInfo,
      'status': statusToString(status),
      'role': role,
      'churchId': churchId,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (isNew) {
      map['createdAt'] = FieldValue.serverTimestamp();
    }

    return map;
  }

  /// Copy with updated fields
  MemberProfile copyWith({
    String? fullName,
    String? familyNumber,
    String? profileImageUrl,
    String? email,
    String? phone,
    String? familyInfo,
    MemberStatus? status,
    String? role,
    String? churchId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MemberProfile(
      uid: uid,
      fullName: fullName ?? this.fullName,
      familyNumber: familyNumber ?? this.familyNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      familyInfo: familyInfo ?? this.familyInfo,
      status: status ?? this.status,
      role: role ?? this.role,
      churchId: churchId ?? this.churchId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
