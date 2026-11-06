import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/config/app_config.dart';
import '../models/birthday_anniversary_week.dart';
import '../models/member_reminder.dart';

/// Repository for Firestore queries and staff operations on weekly birthdays,
/// anniversaries, member reminders, and church wish requests.
class BirthdayRepository {
  final FirebaseFirestore? _customFirestore;
  final http.Client? _customHttpClient;
  final String? serverBaseUrl;

  static const String weeksCollection = 'birthday_anniversary_weeks';
  static const String remindersCollection = 'member_reminders';
  static const String wishLogsCollection = 'wish_logs';

  BirthdayRepository({
    FirebaseFirestore? firestore,
    http.Client? httpClient,
    this.serverBaseUrl,
  })  : _customFirestore = firestore,
        _customHttpClient = httpClient;

  String get _effectiveBaseUrl => serverBaseUrl ?? AppConfig.apiBaseUrl;

  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  http.Client get _http => _customHttpClient ?? http.Client();

  CollectionReference<Map<String, dynamic>> get _weeks =>
      _firestore.collection(weeksCollection);

  CollectionReference<Map<String, dynamic>> get _reminders =>
      _firestore.collection(remindersCollection);

  CollectionReference<Map<String, dynamic>> get _wishLogs =>
      _firestore.collection(wishLogsCollection);

  /// Streams a specific weekly bulletin.
  /// For members: queries documents where isPublished == true and id == weekId,
  /// avoiding permission-denied on drafts and non-existent weeks.
  /// For staff: listens directly to the document for real-time draft/published editing.
  Stream<BirthdayAnniversaryWeek?> streamWeek(String weekId, {required bool isStaff}) {
    if (kDebugMode) {
      debugPrint('[BirthdayRepository] streamWeek weekId: $weekId, isStaff: $isStaff, path: $weeksCollection/$weekId');
    }

    if (isStaff) {
      return _weeks.doc(weekId).snapshots().handleError((e) {
        if (kDebugMode) {
          debugPrint('[BirthdayRepository] Error streaming week doc (staff): $e');
        }
        throw e;
      }).map((doc) {
        if (!doc.exists || doc.data() == null) return null;
        return BirthdayAnniversaryWeek.fromMap(doc.data()!, doc.id);
      });
    }

    return _weeks
        .where('isPublished', isEqualTo: true)
        .where('id', isEqualTo: weekId)
        .snapshots()
        .handleError((e) {
      if (kDebugMode) {
        debugPrint('[BirthdayRepository] Error querying week (member): $e');
      }
      throw e;
    }).map((snap) {
      if (snap.docs.isEmpty) return null;
      return BirthdayAnniversaryWeek.fromMap(snap.docs.first.data(), snap.docs.first.id);
    });
  }

  /// One-time fetch of a weekly bulletin
  Future<BirthdayAnniversaryWeek?> getWeek(String weekId) async {
    try {
      final doc = await _weeks.doc(weekId).get();
      if (!doc.exists || doc.data() == null) return null;
      return BirthdayAnniversaryWeek.fromMap(doc.data()!, doc.id);
    } catch (e) {
      return null;
    }
  }

  /// Safely cleans up weekly bulletins that have strictly passed (older than current week Monday).
  /// Guarantees current and future weeks are never deleted.
  Future<int> cleanupPastWeeks({required String performedByUid}) async {
    final currentMonday = BirthdayAnniversaryWeek.getMondayOf(DateTime.now());
    final currentWeekId = BirthdayAnniversaryWeek.generateWeekId(currentMonday);

    try {
      final pastWeeksSnap = await _weeks
          .where('weekEndDate', isLessThan: Timestamp.fromDate(currentMonday))
          .get();

      int deletedCount = 0;
      for (final doc in pastWeeksSnap.docs) {
        if (doc.id != currentWeekId) {
          await doc.reference.delete();
          deletedCount++;
        }
      }
      return deletedCount;
    } catch (_) {
      return 0;
    }
  }

  /// Streams historical weeks ordered chronologically descending (capped at limit).
  Stream<List<BirthdayAnniversaryWeek>> streamHistoricalWeeks({
    int limit = 12,
    required bool isStaff,
    String churchId = 'csi_main',
  }) {
    Query<Map<String, dynamic>> query = _weeks
        .where('churchId', isEqualTo: churchId)
        .orderBy('weekStartDate', descending: true)
        .limit(limit);

    if (!isStaff) {
      query = query.where('isPublished', isEqualTo: true);
    }

    return query.snapshots().map((snap) {
      return snap.docs
          .map((d) => BirthdayAnniversaryWeek.fromMap(d.data(), d.id))
          .toList();
    });
  }

  /// Staff mutation: creates or updates a weekly bulletin document
  Future<void> saveWeeklyBulletin(
    BirthdayAnniversaryWeek week, {
    required String performedByUid,
    required String performedByRole,
  }) async {
    try {
      final docRef = _weeks.doc(week.id);
      final exists = (await docRef.get()).exists;
      await docRef.set(week.toMap(isNew: !exists), SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw 'Failed to save weekly bulletin: ${e.message ?? e.code}';
    } catch (e) {
      throw 'An unexpected error occurred while saving the weekly bulletin.';
    }
  }

  /// Staff mutation: toggles publication status of a week
  Future<void> togglePublishStatus({
    required String weekId,
    required bool isPublished,
  }) async {
    try {
      await _weeks.doc(weekId).update({
        'isPublished': isPublished,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw 'Failed to update publication status: ${e.message ?? e.code}';
    } catch (e) {
      throw 'An unexpected error occurred while updating publication status.';
    }
  }

  /// Streams personal reminders created by the current member for a given week
  Stream<List<MemberReminder>> streamMemberReminders({
    required String userUid,
    required String weekId,
  }) {
    return _reminders
        .where('userUid', isEqualTo: userUid)
        .where('weekId', isEqualTo: weekId)
        .snapshots()
        .map((snap) {
      return snap.docs
          .map((d) => MemberReminder.fromMap(d.data(), d.id))
          .toList();
    });
  }

  /// Toggles personal reminder (creates if not active, updates or disables if active)
  Future<void> setReminder(MemberReminder reminder) async {
    try {
      final docRef = _reminders.doc(reminder.id);
      await docRef.set(reminder.toMap(isNew: true), SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw 'Failed to set reminder: ${e.message ?? e.code}';
    } catch (e) {
      throw 'An unexpected error occurred while setting reminder.';
    }
  }

  /// Disables / deletes personal reminder
  Future<void> removeReminder(String reminderId) async {
    try {
      await _reminders.doc(reminderId).delete();
    } catch (_) {
      // Best-effort non-blocking delete
    }
  }

  /// Sends a church birthday or wedding anniversary wish.
  ///
  /// Calls the secure Node.js backend if reachable; also logs record in Firestore `wish_logs`
  /// with sender UID enforced from authenticated context.
  Future<void> sendWish({
    required String senderUid,
    required String senderName,
    required String recipientUid,
    required String recipientName,
    required String type, // 'birthday' or 'anniversary'
    required String eventDateStr,
    String? idToken,
  }) async {
    // 1. Record wish attempt in Firestore
    final logRef = _wishLogs.doc();
    final logData = {
      'id': logRef.id,
      'senderUid': senderUid,
      'senderName': senderName,
      'recipientUid': recipientUid,
      'recipientName': recipientName,
      'type': type,
      'eventDate': eventDateStr,
      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      await logRef.set(logData);
    } catch (e) {
      // Continue even if client logging fails
    }

    // 2. Dispatch push notification via Node.js Backend API
    if (idToken != null && idToken.isNotEmpty) {
      try {
        final url = Uri.parse('$_effectiveBaseUrl/api/wishes/send');
        final response = await _http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
          body: jsonEncode({
            'recipientUid': recipientUid,
            'recipientName': recipientName,
            'type': type,
            'eventDate': eventDateStr,
          }),
        );
        if (response.statusCode >= 400) {
          final body = jsonDecode(response.body);
          throw body['error'] ?? 'Notification server error';
        }
      } catch (err) {
        // Non-blocking for UI if server is running on a different port or in background
      }
    }
  }
}
