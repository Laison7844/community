import 'package:cloud_firestore/cloud_firestore.dart';

/// Personal reminder document stored in `member_reminders/{reminderId}`.
///
/// An approved church member can toggle reminders for specific weekly birthday or anniversary entries.
class MemberReminder {
  final String id;              // Standard format: `${userUid}_${weekId}_${entryId}`
  final String userUid;         // Owner UID (member who requested reminder)
  final String weekId;          // Associated bulletin week ID
  final String entryId;         // Target birthday or anniversary entry ID
  final String targetName;      // Name of birthday celebrant or couple
  final DateTime targetDate;    // Date of event
  final String type;            // 'birthday' or 'anniversary'
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MemberReminder({
    required this.id,
    required this.userUid,
    required this.weekId,
    required this.entryId,
    required this.targetName,
    required this.targetDate,
    required this.type,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  static String generateId({
    required String userUid,
    required String weekId,
    required String entryId,
  }) {
    return '${userUid}_${weekId}_$entryId';
  }

  factory MemberReminder.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic val, DateTime fallback) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? fallback;
      return fallback;
    }

    final now = DateTime.now();
    return MemberReminder(
      id: id,
      userUid: map['userUid'] as String? ?? '',
      weekId: map['weekId'] as String? ?? '',
      entryId: map['entryId'] as String? ?? '',
      targetName: map['targetName'] as String? ?? '',
      targetDate: parseDate(map['targetDate'], now),
      type: map['type'] as String? ?? 'birthday',
      isActive: (map['isActive'] as bool?) ?? true,
      createdAt: parseDate(map['createdAt'], now),
      updatedAt: parseDate(map['updatedAt'], now),
    );
  }

  Map<String, dynamic> toMap({bool isNew = false}) {
    final map = <String, dynamic>{
      'id': id,
      'userUid': userUid,
      'weekId': weekId,
      'entryId': entryId,
      'targetName': targetName,
      'targetDate': Timestamp.fromDate(targetDate),
      'type': type,
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (isNew) {
      map['createdAt'] = FieldValue.serverTimestamp();
    }

    return map;
  }

  MemberReminder copyWith({
    String? id,
    String? userUid,
    String? weekId,
    String? entryId,
    String? targetName,
    DateTime? targetDate,
    String? type,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MemberReminder(
      id: id ?? this.id,
      userUid: userUid ?? this.userUid,
      weekId: weekId ?? this.weekId,
      entryId: entryId ?? this.entryId,
      targetName: targetName ?? this.targetName,
      targetDate: targetDate ?? this.targetDate,
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
