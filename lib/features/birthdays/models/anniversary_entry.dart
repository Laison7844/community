import 'package:cloud_firestore/cloud_firestore.dart';

/// Single church couple wedding anniversary record within a weekly bulletin.
class AnniversaryEntry {
  final String id;
  final String memberUid;
  final String? spouseUid;
  final String coupleName;             // e.g. "John & Mary"
  final DateTime eventDate;            // Occurrence date in target week
  final DateTime weddingAnniversary;   // Historical wedding date
  final String? place;                 // Location / Parish unit (e.g. 'Kowdiar')
  final String? profileImageUrl;

  const AnniversaryEntry({
    required this.id,
    required this.memberUid,
    this.spouseUid,
    required this.coupleName,
    required this.eventDate,
    required this.weddingAnniversary,
    this.place,
    this.profileImageUrl,
  });

  /// Automatically calculates the anniversary years count
  int get calculatedYears {
    int years = eventDate.year - weddingAnniversary.year;
    if (eventDate.month < weddingAnniversary.month ||
        (eventDate.month == weddingAnniversary.month && eventDate.day < weddingAnniversary.day)) {
      years--;
    }
    return years >= 0 ? years : 0;
  }

  /// Formats ordinal string, e.g. "12th Anniversary", "1st Anniversary"
  String get formattedAnniversaryOrdinal {
    final count = calculatedYears;
    if (count <= 0) return 'Wedding Anniversary';

    final remainder10 = count % 10;
    final remainder100 = count % 100;

    String suffix = 'th';
    if (remainder100 < 11 || remainder100 > 13) {
      if (remainder10 == 1) suffix = 'st';
      if (remainder10 == 2) suffix = 'nd';
      if (remainder10 == 3) suffix = 'rd';
    }

    return '$count$suffix Anniversary';
  }

  /// Whether today is the actual anniversary date
  bool get isToday {
    final now = DateTime.now();
    return now.year == eventDate.year &&
        now.month == eventDate.month &&
        now.day == eventDate.day;
  }

  factory AnniversaryEntry.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic val, DateTime fallback) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? fallback;
      return fallback;
    }

    final now = DateTime.now();
    return AnniversaryEntry(
      id: map['id'] as String? ?? '',
      memberUid: map['memberUid'] as String? ?? '',
      spouseUid: map['spouseUid'] as String?,
      coupleName: map['coupleName'] as String? ?? '',
      eventDate: parseDate(map['eventDate'], now),
      weddingAnniversary: parseDate(map['weddingAnniversary'], now),
      place: map['place'] as String?,
      profileImageUrl: map['profileImageUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'memberUid': memberUid,
      'spouseUid': spouseUid,
      'coupleName': coupleName,
      'eventDate': Timestamp.fromDate(eventDate),
      'weddingAnniversary': Timestamp.fromDate(weddingAnniversary),
      'place': place,
      'profileImageUrl': profileImageUrl,
    };
  }
}
