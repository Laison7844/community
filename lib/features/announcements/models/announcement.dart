import 'package:cloud_firestore/cloud_firestore.dart';

/// Priority levels for church announcements
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

/// Announcement entity representing church news and bulletins.
class Announcement {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final AnnouncementPriority priority;
  final bool isPublished;
  final String churchId;
  final String createdBy;
  final String? createdByName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Announcement({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    this.priority = AnnouncementPriority.normal,
    this.isPublished = true,
    this.churchId = 'csi_main',
    required this.createdBy,
    this.createdByName,
    this.createdAt,
    this.updatedAt,
  });

  /// Factory from Map and doc ID with safe timestamp parsing
  factory Announcement.fromMap(Map<String, dynamic> data, String docId) {
    DateTime? parseTimestamp(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return Announcement(
      id: docId,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      priority: AnnouncementPriority.fromString(data['priority'] as String?),
      isPublished: data['isPublished'] as bool? ?? true,
      churchId: data['churchId'] as String? ?? 'csi_main',
      createdBy: data['createdBy'] as String? ?? '',
      createdByName: data['createdByName'] as String?,
      createdAt: parseTimestamp(data['createdAt']),
      updatedAt: parseTimestamp(data['updatedAt']),
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
      'title': title.trim(),
      'description': description.trim(),
      'priority': priority.toDbString(),
      'isPublished': isPublished,
      'churchId': churchId,
      'createdBy': createdBy,
      'updatedAt': FieldValue.serverTimestamp(),
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

    return map;
  }

  /// Copy with updated fields
  Announcement copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    AnnouncementPriority? priority,
    bool? isPublished,
    String? churchId,
    String? createdBy,
    String? createdByName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Announcement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      priority: priority ?? this.priority,
      isPublished: isPublished ?? this.isPublished,
      churchId: churchId ?? this.churchId,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
