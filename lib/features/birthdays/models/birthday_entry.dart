import 'package:cloud_firestore/cloud_firestore.dart';

/// Single church member birthday record within a weekly bulletin.
class BirthdayEntry {
  final String id;
  final String memberUid;
  final String memberName;
  final DateTime eventDate;       // Date of birthday occurrence in the current week
  final DateTime dateOfBirth;     // Historical birth date containing the birth year
  final String? place;            // Location / Parish unit (e.g. 'Thiruvananthapuram')
  final String? profileImageUrl;

  const BirthdayEntry({
    required this.id,
    required this.memberUid,
    required this.memberName,
    required this.eventDate,
    required this.dateOfBirth,
    this.place,
    this.profileImageUrl,
  });

  /// Automatically calculates the age on the birthday occurrence date
  int get calculatedAge {
    int age = eventDate.year - dateOfBirth.year;
    if (eventDate.month < dateOfBirth.month ||
        (eventDate.month == dateOfBirth.month && eventDate.day < dateOfBirth.day)) {
      age--;
    }
    return age >= 0 ? age : 0;
  }

  /// Whether today is the actual birthday date
  bool get isToday {
    final now = DateTime.now();
    return now.year == eventDate.year &&
        now.month == eventDate.month &&
        now.day == eventDate.day;
  }

  factory BirthdayEntry.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic val, DateTime fallback) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? fallback;
      return fallback;
    }

    final now = DateTime.now();
    return BirthdayEntry(
      id: map['id'] as String? ?? '',
      memberUid: map['memberUid'] as String? ?? '',
      memberName: map['memberName'] as String? ?? '',
      eventDate: parseDate(map['eventDate'], now),
      dateOfBirth: parseDate(map['dateOfBirth'], now),
      place: map['place'] as String?,
      profileImageUrl: map['profileImageUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'memberUid': memberUid,
      'memberName': memberName,
      'eventDate': Timestamp.fromDate(eventDate),
      'dateOfBirth': Timestamp.fromDate(dateOfBirth),
      'place': place,
      'profileImageUrl': profileImageUrl,
    };
  }
}
