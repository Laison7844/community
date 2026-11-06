import 'package:cloud_firestore/cloud_firestore.dart';

/// Single church member birthday record within a weekly bulletin.
class BirthdayEntry {
  final String id;
  final String? memberUid;        // Optional/null: church person does not require an app account
  final String memberName;       // Person Name *
  final String? familyNumber;     // Family Number (optional)
  final DateTime eventDate;       // Date of birthday occurrence in the current week
  final DateTime dateOfBirth;     // Historical birth date containing the birth year
  final String? place;            // Location / Parish unit (e.g. 'Karuvichan Kuzhi')
  final String? profileImageUrl;

  const BirthdayEntry({
    required this.id,
    this.memberUid,
    required this.memberName,
    this.familyNumber,
    required this.eventDate,
    required this.dateOfBirth,
    this.place,
    this.profileImageUrl,
  });

  /// True if celebrant has a linked app user account
  bool get hasAppAccount => memberUid != null && memberUid!.trim().isNotEmpty;

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
      memberUid: map['memberUid'] as String?,
      memberName: (map['name'] ?? map['memberName']) as String? ?? '',
      familyNumber: map['familyNumber'] as String?,
      eventDate: parseDate(map['eventDate'], now),
      dateOfBirth: parseDate(map['dateOfBirth'], now),
      place: map['place'] as String?,
      profileImageUrl: map['profileImageUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      if (memberUid != null && memberUid!.isNotEmpty) 'memberUid': memberUid,
      'memberName': memberName,
      'name': memberName,
      if (familyNumber != null && familyNumber!.isNotEmpty)
        'familyNumber': familyNumber,
      'eventDate': Timestamp.fromDate(eventDate),
      'dateOfBirth': Timestamp.fromDate(dateOfBirth),
      if (place != null && place!.isNotEmpty) 'place': place,
      if (profileImageUrl != null && profileImageUrl!.isNotEmpty)
        'profileImageUrl': profileImageUrl,
    };
  }
}
