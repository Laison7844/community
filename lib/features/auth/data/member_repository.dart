import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/member_profile.dart';

/// Repository responsible for reading and writing member profile documents in Cloud Firestore.
///
/// Collection path: `member_profiles/{uid}`
class MemberRepository {
  final FirebaseFirestore? _customFirestore;
  static const String collectionName = 'member_profiles';

  MemberRepository({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(collectionName);

  /// Creates a new member profile in Firestore.
  /// Enforces default `status: pending` and `role: member` on creation.
  Future<void> createMemberProfile(MemberProfile profile) async {
    try {
      await _collection.doc(profile.uid).set(
            profile.toMap(isNew: true),
            SetOptions(merge: false),
          );
    } on FirebaseException catch (e) {
      throw 'Failed to create church member profile: ${e.message ?? e.code}';
    } catch (e) {
      throw 'An unexpected error occurred while saving your church member profile.';
    }
  }

  /// Fetches a member profile by UID. Returns null if document does not exist.
  Future<MemberProfile?> getMemberProfile(String uid) async {
    try {
      final doc = await _collection.doc(uid).get();
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return MemberProfile.fromMap(doc.data()!, uid: doc.id);
    } on FirebaseException catch (e) {
      throw 'Failed to retrieve church membership details: ${e.message ?? e.code}';
    } catch (e) {
      throw 'An unexpected error occurred while fetching your church profile.';
    }
  }

  /// Stream updates for a specific member profile (e.g. when committee approves the member in real-time)
  Stream<MemberProfile?> streamMemberProfile(String uid) {
    return _collection.doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return MemberProfile.fromMap(doc.data()!, uid: doc.id);
    });
  }
}
