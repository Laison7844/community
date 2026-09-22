import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

/// Repository responsible for uploading and managing member profile images in Firebase Storage.
class StorageRepository {
  final FirebaseStorage? _customStorage;

  StorageRepository({FirebaseStorage? storage}) : _customStorage = storage;

  FirebaseStorage get _storage => _customStorage ?? FirebaseStorage.instance;

  /// Uploads a member's profile photo to `member_profiles/{uid}/profile_photo`
  /// and returns the download URL.
  Future<String> uploadProfilePhoto({
    required String uid,
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      final ext = fileName.split('.').last.toLowerCase();
      final contentType = ext == 'png'
          ? 'image/png'
          : (ext == 'webp' ? 'image/webp' : 'image/jpeg');

      final ref = _storage.ref().child('member_profiles/$uid/profile_photo');

      final metadata = SettableMetadata(
        contentType: contentType,
        customMetadata: {
          'uploadedBy': uid,
          'purpose': 'church_member_profile_photo',
        },
      );

      final uploadTask = await ref.putData(bytes, metadata);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      throw 'Failed to upload church profile photo: ${e.message ?? e.code}';
    } catch (e) {
      throw 'An unexpected error occurred while uploading your profile photo.';
    }
  }

  /// Deletes profile photo from Firebase Storage (used during rollback)
  Future<void> deleteProfilePhoto(String uid) async {
    try {
      final ref = _storage.ref().child('member_profiles/$uid/profile_photo');
      await ref.delete();
    } catch (_) {
      // Best-effort cleanup
    }
  }

  /// Uploads an announcement banner image to `announcements/{announcementId}/banner`
  Future<String> uploadAnnouncementImage({
    required String announcementId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      final ext = fileName.split('.').last.toLowerCase();
      final contentType = ext == 'png'
          ? 'image/png'
          : (ext == 'webp' ? 'image/webp' : 'image/jpeg');

      final ref = _storage.ref().child('announcements/$announcementId/banner');

      final metadata = SettableMetadata(
        contentType: contentType,
        cacheControl: 'public, max-age=86400',
        customMetadata: {
          'announcementId': announcementId,
          'purpose': 'church_announcement_banner',
        },
      );

      final uploadTask = await ref.putData(bytes, metadata);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      throw 'Failed to upload announcement banner: ${e.message ?? e.code}';
    } catch (e) {
      throw 'An unexpected error occurred while uploading announcement banner.';
    }
  }

  /// Safely deletes announcement banner image from Storage.
  /// Gracefully handles missing files without crashing.
  Future<void> deleteAnnouncementImage(String announcementId) async {
    try {
      final ref = _storage.ref().child('announcements/$announcementId/banner');
      await ref.delete();
    } on FirebaseException catch (e) {
      // Ignore if image doesn't exist; do not block deletion
      if (e.code != 'object-not-found') {
        // Suppress non-critical image cleanup failure
      }
    } catch (_) {
      // Best-effort non-blocking cleanup
    }
  }
}
