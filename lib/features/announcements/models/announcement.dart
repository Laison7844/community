import 'package:cloud_firestore/cloud_firestore.dart';

/// Announcement types for CSI Church Community
enum AnnouncementType {
  marriage,
  general,
  special;

  static AnnouncementType fromString(String? val) {
    switch (val?.toLowerCase().trim()) {
      case 'marriage':
        return AnnouncementType.marriage;
      case 'special':
        return AnnouncementType.special;
      case 'general':
      default:
        return AnnouncementType.general;
    }
  }

  String toDbString() => name;

  String get displayName {
    switch (this) {
      case AnnouncementType.marriage:
        return 'Marriage Announcement';
      case AnnouncementType.general:
        return 'General Announcement';
      case AnnouncementType.special:
        return 'Special Announcement';
    }
  }
}

/// Announcement stages specifically for marriage banns/announcements
enum AnnouncementStage {
  first,
  second,
  third;

  static AnnouncementStage fromString(String? val) {
    switch (val?.toLowerCase().trim()) {
      case 'second':
      case '2nd':
      case '2nd announcement':
        return AnnouncementStage.second;
      case 'third':
      case '3rd':
      case '3rd announcement':
        return AnnouncementStage.third;
      case 'first':
      case '1st':
      case '1st announcement':
      default:
        return AnnouncementStage.first;
    }
  }

  static AnnouncementStage fromValue(String? val) => fromString(val);

  String toDbString() {
    switch (this) {
      case AnnouncementStage.first:
        return '1st Announcement';
      case AnnouncementStage.second:
        return '2nd Announcement';
      case AnnouncementStage.third:
        return '3rd Announcement';
    }
  }

  String get displayName => toDbString();
}

/// Legacy priority levels retained strictly for backward compatibility
@Deprecated('Priority is replaced by AnnouncementType')
enum AnnouncementPriority {
  normal,
  high,
  urgent;

  static AnnouncementPriority fromString(String? val) {
    switch (val?.toLowerCase().trim()) {
      case 'urgent':
        return AnnouncementPriority.urgent;
      case 'high':
        return AnnouncementPriority.high;
      case 'normal':
      default:
        return AnnouncementPriority.normal;
    }
  }

  String toDbString() {
    switch (this) {
      case AnnouncementPriority.urgent:
        return 'urgent';
      case AnnouncementPriority.high:
        return 'high';
      case AnnouncementPriority.normal:
        return 'normal';
    }
  }

  String get displayName {
    switch (this) {
      case AnnouncementPriority.urgent:
        return 'Urgent';
      case AnnouncementPriority.high:
        return 'High Priority';
      case AnnouncementPriority.normal:
        return 'General';
    }
  }
}

/// Announcement entity representing church news, marriage banns, and celebrations.
class Announcement {
  final String id;
  final AnnouncementType announcementType;
  final String title;
  final String description;
  final String? imageUrl;
  final bool isPublished;
  final String churchId;
  final String createdBy;
  final String? createdByName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Marriage announcement specific fields
  final String? brideName;
  final String? brideDetails;
  final String? groomName;
  final String? groomDetails;
  final AnnouncementStage? announcementStage;
  final DateTime? marriageDate;

  // General & Special announcement specific fields
  final DateTime? scheduledDate;
  final String? scheduledTime;

  // Retained for backward compatibility
  @Deprecated('Use announcementType instead')
  final AnnouncementPriority priority;

  const Announcement({
    required this.id,
    this.announcementType = AnnouncementType.general,
    required this.title,
    this.description = '',
    this.imageUrl,
    this.isPublished = true,
    this.churchId = 'csi_main',
    required this.createdBy,
    this.createdByName,
    this.createdAt,
    this.updatedAt,
    this.brideName,
    this.brideDetails,
    this.groomName,
    this.groomDetails,
    this.announcementStage,
    this.marriageDate,
    this.scheduledDate,
    this.scheduledTime,
    @Deprecated('Use announcementType instead')
    this.priority = AnnouncementPriority.normal,
  });

  /// Factory from Map and doc ID with safe timestamp parsing
  factory Announcement.fromMap(Map<String, dynamic> data, String docId) {
    DateTime? parseTimestamp(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    final typeStr = data['announcementType'] as String?;
    final resolvedType = typeStr != null
        ? AnnouncementType.fromString(typeStr)
        : (data['marriageDate'] != null
            ? AnnouncementType.marriage
            : AnnouncementType.general);

    final stageStr = data['announcementStage'] as String?;

    return Announcement(
      id: docId,
      announcementType: resolvedType,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      isPublished: data['isPublished'] as bool? ?? true,
      churchId: data['churchId'] as String? ?? 'csi_main',
      createdBy: data['createdBy'] as String? ?? '',
      createdByName: data['createdByName'] as String?,
      createdAt: parseTimestamp(data['createdAt']),
      updatedAt: parseTimestamp(data['updatedAt']),
      brideName: data['brideName'] as String?,
      brideDetails: data['brideDetails'] as String?,
      groomName: data['groomName'] as String?,
      groomDetails: data['groomDetails'] as String?,
      announcementStage: stageStr != null ? AnnouncementStage.fromString(stageStr) : null,
      marriageDate: parseTimestamp(data['marriageDate']),
      scheduledDate: parseTimestamp(data['scheduledDate']),
      scheduledTime: data['scheduledTime'] as String?,
      priority: AnnouncementPriority.fromString(data['priority'] as String?),
    );
  }

  /// Factory from Firestore DocumentSnapshot
  factory Announcement.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Announcement.fromMap(doc.data() ?? {}, doc.id);
  }

  /// Convert to Map for Firestore writes
  Map<String, dynamic> toMap({bool isNew = false}) {
    final map = <String, dynamic>{
      'id': id,
      'announcementType': announcementType.toDbString(),
      'title': title.trim(),
      'description': description.trim(),
      'isPublished': isPublished,
      'churchId': churchId,
      'createdBy': createdBy,
      'updatedAt': FieldValue.serverTimestamp(),
      'priority': priority.toDbString(), // kept for rule validation compatibility
    };

    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      map['imageUrl'] = imageUrl!.trim();
    } else {
      map['imageUrl'] = null;
    }

    if (createdByName != null && createdByName!.trim().isNotEmpty) {
      map['createdByName'] = createdByName!.trim();
    }

    if (isNew) {
      map['createdAt'] = FieldValue.serverTimestamp();
    }

    // Marriage fields
    if (announcementType == AnnouncementType.marriage) {
      map['brideName'] = brideName?.trim();
      map['brideDetails'] = brideDetails?.trim();
      map['groomName'] = groomName?.trim();
      map['groomDetails'] = groomDetails?.trim();
      map['announcementStage'] = announcementStage?.toDbString();
      if (marriageDate != null) {
        map['marriageDate'] = Timestamp.fromDate(marriageDate!);
      }
    }

    // General & Special fields
    if (scheduledDate != null) {
      map['scheduledDate'] = Timestamp.fromDate(scheduledDate!);
    }
    if (scheduledTime != null && scheduledTime!.trim().isNotEmpty) {
      map['scheduledTime'] = scheduledTime!.trim();
    }

    return map;
  }

  /// Determines member-facing visibility based on project requirements:
  /// - Marriage: Disappears ONE DAY BEFORE the marriage date (currentDate < marriageDate - 1 day)
  /// - General & Special: Visible until scheduled date/time has passed
  bool isVisibleForMembers([DateTime? now]) {
    if (!isPublished) return false;
    final current = now ?? DateTime.now();

    if (announcementType == AnnouncementType.marriage) {
      if (marriageDate == null) return true;
      // Start of marriage day in local date terms
      final marriageDayStart = DateTime(
        marriageDate!.year,
        marriageDate!.month,
        marriageDate!.day,
      );
      // Cutoff is strictly one day before the marriage date
      // Example: Marriage Sept 30 -> Cutoff Sept 29 00:00:00.
      // Sept 28 is before Sept 29 00:00:00 -> Visible.
      // Sept 29 and Sept 30 are not before cutoff -> Disappears.
      final cutoffDate = marriageDayStart.subtract(const Duration(days: 1));
      return current.isBefore(cutoffDate);
    } else {
      // General and Special: visible until scheduled date/time has passed
      if (scheduledDate == null) return true;

      DateTime expirationTime;
      if (scheduledTime != null && scheduledTime!.trim().isNotEmpty) {
        expirationTime = _combineDateAndTime(scheduledDate!, scheduledTime!.trim());
      } else {
        // Until the end of the scheduled day
        expirationTime = DateTime(
          scheduledDate!.year,
          scheduledDate!.month,
          scheduledDate!.day,
          23,
          59,
          59,
        );
      }
      return current.isBefore(expirationTime);
    }
  }

  bool get isMarriage => announcementType == AnnouncementType.marriage;
  bool get isSpecial => announcementType == AnnouncementType.special;
  bool get isGeneral => announcementType == AnnouncementType.general;

  static DateTime _combineDateAndTime(DateTime date, String timeStr) {
    try {
      final parts = timeStr.trim().split(' ');
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      final int minute = timeParts.length > 1 ? int.parse(timeParts[1]) : 0;

      if (parts.length > 1) {
        final period = parts[1].toUpperCase();
        if (period == 'PM' && hour < 12) hour += 12;
        if (period == 'AM' && hour == 12) hour = 0;
      }

      return DateTime(date.year, date.month, date.day, hour, minute);
    } catch (_) {
      return DateTime(date.year, date.month, date.day, 23, 59, 59);
    }
  }

  /// Copy with updated fields
  Announcement copyWith({
    String? id,
    AnnouncementType? announcementType,
    String? title,
    String? description,
    String? imageUrl,
    bool? isPublished,
    String? churchId,
    String? createdBy,
    String? createdByName,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? brideName,
    String? brideDetails,
    String? groomName,
    String? groomDetails,
    AnnouncementStage? announcementStage,
    DateTime? marriageDate,
    DateTime? scheduledDate,
    String? scheduledTime,
    AnnouncementPriority? priority,
  }) {
    return Announcement(
      id: id ?? this.id,
      announcementType: announcementType ?? this.announcementType,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      isPublished: isPublished ?? this.isPublished,
      churchId: churchId ?? this.churchId,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      brideName: brideName ?? this.brideName,
      brideDetails: brideDetails ?? this.brideDetails,
      groomName: groomName ?? this.groomName,
      groomDetails: groomDetails ?? this.groomDetails,
      announcementStage: announcementStage ?? this.announcementStage,
      marriageDate: marriageDate ?? this.marriageDate,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      priority: priority ?? this.priority,
    );
  }
}
