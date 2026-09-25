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

  // Phase 5: Birthday & Wedding Anniversary fields
  final DateTime? dateOfBirth;
  final DateTime? weddingAnniversary;
  final String? maritalStatus;     // 'single', 'married', etc.
  final String? spouseUid;
  final String? spouseName;
  final String? place;             // e.g. 'Thiruvananthapuram', 'Kowdiar'
  final List<String> fcmTokens;

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
    this.dateOfBirth,
    this.weddingAnniversary,
    this.maritalStatus,
    this.spouseUid,
    this.spouseName,
    this.place,
    this.fcmTokens = const [],
  });

  bool get isApproved => status == MemberStatus.approved;
  bool get isPending => status == MemberStatus.pending;
  bool get isSuspended => status == MemberStatus.suspended;
  bool get isRejected => status == MemberStatus.rejected;

  /// Automatically calculates member age from dateOfBirth relative to referenceDate (or today)
  int? calculateAge([DateTime? referenceDate]) {
    if (dateOfBirth == null) return null;
    final ref = referenceDate ?? DateTime.now();
    int age = ref.year - dateOfBirth!.year;
    if (ref.month < dateOfBirth!.month ||
        (ref.month == dateOfBirth!.month && ref.day < dateOfBirth!.day)) {
      age--;
    }
    return age >= 0 ? age : 0;
  }

  /// Automatically calculates wedding anniversary year count relative to referenceDate (or today)
  int? calculateAnniversaryYears([DateTime? referenceDate]) {
    if (weddingAnniversary == null) return null;
    final ref = referenceDate ?? DateTime.now();
    int years = ref.year - weddingAnniversary!.year;
    if (ref.month < weddingAnniversary!.month ||
        (ref.month == weddingAnniversary!.month && ref.day < weddingAnniversary!.day)) {
      years--;
    }
    return years >= 0 ? years : 0;
  }

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

    final rawTokens = map['fcmTokens'];
    List<String> parsedTokens = [];
    if (rawTokens is List) {
      parsedTokens = rawTokens.map((e) => e.toString()).toList();
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
      dateOfBirth: parseTimestamp(map['dateOfBirth']),
      weddingAnniversary: parseTimestamp(map['weddingAnniversary']),
      maritalStatus: map['maritalStatus'] as String?,
      spouseUid: map['spouseUid'] as String?,
      spouseName: map['spouseName'] as String?,
      place: map['place'] as String?,
      fcmTokens: parsedTokens,
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

    if (dateOfBirth != null) {
      map['dateOfBirth'] = Timestamp.fromDate(dateOfBirth!);
    }
    if (weddingAnniversary != null) {
      map['weddingAnniversary'] = Timestamp.fromDate(weddingAnniversary!);
    }
    if (maritalStatus != null) {
      map['maritalStatus'] = maritalStatus;
    }
    if (spouseUid != null) {
      map['spouseUid'] = spouseUid;
    }
    if (spouseName != null) {
      map['spouseName'] = spouseName;
    }
    if (place != null) {
      map['place'] = place;
    }
    if (fcmTokens.isNotEmpty) {
      map['fcmTokens'] = fcmTokens;
    }

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
    DateTime? dateOfBirth,
    DateTime? weddingAnniversary,
    String? maritalStatus,
    String? spouseUid,
    String? spouseName,
    String? place,
    List<String>? fcmTokens,
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
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      weddingAnniversary: weddingAnniversary ?? this.weddingAnniversary,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      spouseUid: spouseUid ?? this.spouseUid,
      spouseName: spouseName ?? this.spouseName,
      place: place ?? this.place,
      fcmTokens: fcmTokens ?? this.fcmTokens,
    );
  }
}
