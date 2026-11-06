import 'package:cloud_firestore/cloud_firestore.dart';

/// Single church couple wedding anniversary record within a weekly bulletin.
class AnniversaryEntry {
  final String id;
  final String? memberUid;             // Optional/null: app account not required
  final String? spouseUid;             // Optional/null
  final String? brideUid;              // Optional/null
  final String? groomUid;              // Optional/null
  final String coupleName;             // e.g. "John & Mary"
  final String? brideName;             // Optional separate bride/wife name
  final String? groomName;             // Optional separate groom/husband name
  final String? familyNumber;          // Optional family number
  final DateTime eventDate;            // Occurrence date in target week
  final DateTime weddingAnniversary;   // Historical wedding date
  final String? place;                 // Location / Parish unit (e.g. 'Karuvichan Kuzhi')
  final String? profileImageUrl;

  const AnniversaryEntry({
    required this.id,
    this.memberUid,
    this.spouseUid,
    this.brideUid,
    this.groomUid,
    required this.coupleName,
    this.brideName,
    this.groomName,
    this.familyNumber,
    required this.eventDate,
    required this.weddingAnniversary,
    this.place,
    this.profileImageUrl,
  });

  /// Alias for coupleName conforming to church specification
  String get coupleDisplayName => coupleName;

  /// Alias for weddingAnniversary
  DateTime get weddingDate => weddingAnniversary;

  /// True if at least one spouse has an active app user account
  bool get hasAppAccount =>
      (memberUid != null && memberUid!.trim().isNotEmpty) ||
      (spouseUid != null && spouseUid!.trim().isNotEmpty) ||
      (brideUid != null && brideUid!.trim().isNotEmpty) ||
      (groomUid != null && groomUid!.trim().isNotEmpty);

  /// Resolves the primary recipient UID for push notifications if available
  String? get primaryRecipientUid {
    if (memberUid != null && memberUid!.trim().isNotEmpty) return memberUid;
    if (brideUid != null && brideUid!.trim().isNotEmpty) return brideUid;
    if (groomUid != null && groomUid!.trim().isNotEmpty) return groomUid;
    if (spouseUid != null && spouseUid!.trim().isNotEmpty) return spouseUid;
    return null;
  }

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
    final rawWeddingDate = map['weddingDate'] ?? map['weddingAnniversary'];
    return AnniversaryEntry(
      id: map['id'] as String? ?? '',
      memberUid: map['memberUid'] as String?,
      spouseUid: map['spouseUid'] as String?,
      brideUid: map['brideUid'] as String?,
      groomUid: map['groomUid'] as String?,
      coupleName: (map['coupleDisplayName'] ?? map['coupleName']) as String? ?? '',
      brideName: map['brideName'] as String?,
      groomName: map['groomName'] as String?,
      familyNumber: map['familyNumber'] as String?,
      eventDate: parseDate(map['eventDate'], now),
      weddingAnniversary: parseDate(rawWeddingDate, now),
      place: map['place'] as String?,
      profileImageUrl: map['profileImageUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      if (memberUid != null && memberUid!.isNotEmpty) 'memberUid': memberUid,
      if (spouseUid != null && spouseUid!.isNotEmpty) 'spouseUid': spouseUid,
      if (brideUid != null && brideUid!.isNotEmpty) 'brideUid': brideUid,
      if (groomUid != null && groomUid!.isNotEmpty) 'groomUid': groomUid,
      'coupleName': coupleName,
      'coupleDisplayName': coupleName,
      if (brideName != null && brideName!.isNotEmpty) 'brideName': brideName,
      if (groomName != null && groomName!.isNotEmpty) 'groomName': groomName,
      if (familyNumber != null && familyNumber!.isNotEmpty)
        'familyNumber': familyNumber,
      'eventDate': Timestamp.fromDate(eventDate),
      'weddingAnniversary': Timestamp.fromDate(weddingAnniversary),
      'weddingDate': Timestamp.fromDate(weddingAnniversary),
      if (place != null && place!.isNotEmpty) 'place': place,
      if (profileImageUrl != null && profileImageUrl!.isNotEmpty)
        'profileImageUrl': profileImageUrl,
    };
  }
}
