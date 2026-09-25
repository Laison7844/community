import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'anniversary_entry.dart';
import 'birthday_entry.dart';

/// Weekly bulletin record in Firestore collection `birthday_anniversary_weeks/{weekId}`.
///
/// Each bulletin covers a strict Monday through Sunday week period.
class BirthdayAnniversaryWeek {
  final String id;                     // Formatted as YYYY-MM-DD of Monday (e.g. '2026-09-28')
  final DateTime weekStartDate;        // Monday 00:00:00
  final DateTime weekEndDate;          // Sunday 23:59:59
  final String churchId;
  final bool isPublished;
  final List<BirthdayEntry> birthdays;
  final List<AnniversaryEntry> anniversaries;
  final String createdBy;
  final String? createdByName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BirthdayAnniversaryWeek({
    required this.id,
    required this.weekStartDate,
    required this.weekEndDate,
    this.churchId = 'csi_main',
    this.isPublished = false,
    this.birthdays = const [],
    this.anniversaries = const [],
    required this.createdBy,
    this.createdByName,
    this.createdAt,
    this.updatedAt,
  });

  /// Human-readable date range label (e.g. "Sep 28 – Oct 4, 2026")
  String get weekRangeLabel {
    final startFmt = DateFormat('MMM d').format(weekStartDate);
    final endFmt = DateFormat('MMM d, y').format(weekEndDate);
    return '$startFmt – $endFmt';
  }

  /// Calculates the Monday (00:00:00) for any given date
  static DateTime getMondayOf(DateTime date) {
    final clean = DateTime(date.year, date.month, date.day);
    final daysToSubtract = clean.weekday - DateTime.monday;
    return clean.subtract(Duration(days: daysToSubtract));
  }

  /// Calculates the Sunday (23:59:59) for any given date
  static DateTime getSundayOf(DateTime date) {
    final monday = getMondayOf(date);
    return DateTime(monday.year, monday.month, monday.day + 6, 23, 59, 59);
  }

  /// Generates the standard weekId (e.g. '2026-09-28') from any date within that week
  static String generateWeekId(DateTime date) {
    final monday = getMondayOf(date);
    return DateFormat('yyyy-MM-dd').format(monday);
  }

  /// Next week's Monday
  static DateTime getNextWeekMonday([DateTime? referenceDate]) {
    final monday = getMondayOf(referenceDate ?? DateTime.now());
    return monday.add(const Duration(days: 7));
  }

  /// Previous week's Monday
  static DateTime getPreviousWeekMonday([DateTime? referenceDate]) {
    final monday = getMondayOf(referenceDate ?? DateTime.now());
    return monday.subtract(const Duration(days: 7));
  }

  factory BirthdayAnniversaryWeek.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic val, DateTime fallback) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? fallback;
      return fallback;
    }

    final now = DateTime.now();
    final start = parseDate(map['weekStartDate'], getMondayOf(now));
    final end = parseDate(map['weekEndDate'], getSundayOf(now));

    final rawBdays = map['birthdays'];
    List<BirthdayEntry> parsedBdays = [];
    if (rawBdays is List) {
      parsedBdays = rawBdays
          .whereType<Map<String, dynamic>>()
          .map((b) => BirthdayEntry.fromMap(b))
          .toList();
    }

    final rawAnnivs = map['anniversaries'];
    List<AnniversaryEntry> parsedAnnivs = [];
    if (rawAnnivs is List) {
      parsedAnnivs = rawAnnivs
          .whereType<Map<String, dynamic>>()
          .map((a) => AnniversaryEntry.fromMap(a))
          .toList();
    }

    // Sort entries chronologically by event date
    parsedBdays.sort((a, b) => a.eventDate.compareTo(b.eventDate));
    parsedAnnivs.sort((a, b) => a.eventDate.compareTo(b.eventDate));

    return BirthdayAnniversaryWeek(
      id: id,
      weekStartDate: start,
      weekEndDate: end,
      churchId: (map['churchId'] as String?) ?? 'csi_main',
      isPublished: (map['isPublished'] as bool?) ?? false,
      birthdays: parsedBdays,
      anniversaries: parsedAnnivs,
      createdBy: (map['createdBy'] as String?) ?? '',
      createdByName: map['createdByName'] as String?,
      createdAt: parseDate(map['createdAt'], now),
      updatedAt: parseDate(map['updatedAt'], now),
    );
  }

  Map<String, dynamic> toMap({bool isNew = false}) {
    final map = <String, dynamic>{
      'id': id,
      'weekStartDate': Timestamp.fromDate(weekStartDate),
      'weekEndDate': Timestamp.fromDate(weekEndDate),
      'churchId': churchId,
      'isPublished': isPublished,
      'birthdays': birthdays.map((b) => b.toMap()).toList(),
      'anniversaries': anniversaries.map((a) => a.toMap()).toList(),
      'createdBy': createdBy,
      'createdByName': createdByName,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (isNew) {
      map['createdAt'] = FieldValue.serverTimestamp();
    }

    return map;
  }

  BirthdayAnniversaryWeek copyWith({
    String? id,
    DateTime? weekStartDate,
    DateTime? weekEndDate,
    String? churchId,
    bool? isPublished,
    List<BirthdayEntry>? birthdays,
    List<AnniversaryEntry>? anniversaries,
    String? createdBy,
    String? createdByName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BirthdayAnniversaryWeek(
      id: id ?? this.id,
      weekStartDate: weekStartDate ?? this.weekStartDate,
      weekEndDate: weekEndDate ?? this.weekEndDate,
      churchId: churchId ?? this.churchId,
      isPublished: isPublished ?? this.isPublished,
      birthdays: birthdays ?? this.birthdays,
      anniversaries: anniversaries ?? this.anniversaries,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
