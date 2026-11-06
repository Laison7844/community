import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/notification_service.dart';
import '../data/auth_repository.dart';
import '../data/member_repository.dart';
import '../data/storage_repository.dart';
import '../models/auth_state.dart';
import '../models/member_profile.dart';

/// Provider for AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Provider for MemberRepository
final memberRepositoryProvider = Provider<MemberRepository>((ref) {
  return MemberRepository();
});

/// Provider for StorageRepository
final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  return StorageRepository();
});

/// Riverpod Notifier managing real Firebase Authentication, Storage photo upload, and Firestore member status.
class AuthNotifier extends Notifier<AuthState> {
  late final AuthRepository _authRepo;
  late final MemberRepository _memberRepo;
  late final StorageRepository _storageRepo;

  @override
  AuthState build() {
    _authRepo = ref.watch(authRepositoryProvider);
    _memberRepo = ref.watch(memberRepositoryProvider);
    _storageRepo = ref.watch(storageRepositoryProvider);

    // Check if an existing Firebase session exists
    try {
      final currentUser = _authRepo.currentUser;
      if (currentUser != null) {
        // Restore session in background
        _restoreSession(currentUser.uid, currentUser.email);
        return AuthState(
          isAuthenticated: true,
          uid: currentUser.uid,
          email: currentUser.email,
          isLoading: true,
        );
      }
    } catch (_) {
      // Handles test environments where Firebase is not initialized
    }

    return AuthState.unauthenticated();
  }

  /// Restores session by fetching the Firestore member profile
  Future<void> _restoreSession(String uid, String? email) async {
    try {
      final profile = await _memberRepo.getMemberProfile(uid);
      if (profile != null) {
        state = AuthState(
          isAuthenticated: true,
          status: profile.status,
          uid: uid,
          email: profile.email.isNotEmpty ? profile.email : email,
          fullName: profile.fullName,
          profile: profile,
          isLoading: false,
        );
        // Automatically sync device FCM token in background
        _syncFcmToken(uid);
      } else {
        // User is authenticated with Firebase but has no member profile
        state = AuthState(
          isAuthenticated: false,
          status: MemberStatus.none,
          errorMessage: 'No church profile found. Please request church access.',
          isLoading: false,
        );
        await _authRepo.signOut();
      }
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Sign in with Firebase Authentication and retrieve member profile
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final credential = await _authRepo.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw 'Failed to sign in. Please try again.';
      }

      // Fetch member profile from Firestore
      final profile = await _memberRepo.getMemberProfile(user.uid);

      if (profile == null) {
        await _authRepo.signOut();
        state = AuthState.unauthenticated().copyWith(
          errorMessage:
              'No church member record found for this email. Please request access or contact the church committee.',
        );
        return false;
      }

      // Handle suspended accounts
      if (profile.isSuspended) {
        await _authRepo.signOut();
        state = AuthState.unauthenticated().copyWith(
          status: MemberStatus.suspended,
          errorMessage:
              'This church membership has been suspended. Please contact the church pastor or committee.',
        );
        return false;
      }

      // Handle rejected accounts
      if (profile.isRejected) {
        await _authRepo.signOut();
        state = AuthState.unauthenticated().copyWith(
          status: MemberStatus.rejected,
          errorMessage:
              'Your church membership application was not approved by the committee. Please contact church administration.',
        );
        return false;
      }

      // Valid session (either approved or pending review)
      state = AuthState(
        isAuthenticated: true,
        status: profile.status,
        uid: user.uid,
        email: profile.email,
        fullName: profile.fullName,
        profile: profile,
        isLoading: false,
      );

      // Automatically register device FCM token with backend
      _syncFcmToken(user.uid);

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Register a new church member with:
  /// - Firebase Authentication
  /// - Mandatory profile photo upload to Firebase Storage
  /// - Firestore profile with mandatory official fullName and shared familyNumber
  /// - Enforced status='pending' and role='member'
  Future<bool> requestAccess({
    required String fullName,
    required String familyNumber,
    required Uint8List photoBytes,
    required String photoFileName,
    required String email,
    String? phone,
    String? familyInfo,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // 1. Create Firebase Authentication account
      final credential = await _authRepo.signUpWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw 'Could not create church account. Please try again.';
      }

      // 2. Upload mandatory profile photo to Firebase Storage
      String profileImageUrl;
      try {
        profileImageUrl = await _storageRepo.uploadProfilePhoto(
          uid: user.uid,
          bytes: photoBytes,
          fileName: photoFileName,
        );
      } catch (uploadError) {
        // Rollback: delete the newly created Firebase Auth user if photo upload fails
        try {
          await user.delete();
        } catch (_) {
          await _authRepo.signOut();
        }
        rethrow;
      }

      // 3. Build initial MemberProfile with strictly enforced 'pending' status.
      // Note: familyNumber is unique to each family, NOT each member. Multiple family
      // members can register with the same familyNumber. Each member has an independent
      // UID and approval workflow.
      final newProfile = MemberProfile(
        uid: user.uid,
        fullName: fullName.trim(),
        familyNumber: familyNumber.trim(),
        profileImageUrl: profileImageUrl,
        email: email.trim(),
        phone: phone?.trim(),
        familyInfo: familyInfo?.trim(),
        status: MemberStatus.pending,
        role: 'member',
        churchId: 'csi_main',
      );

      // 4. Write document to Firestore: `member_profiles/{uid}`
      try {
        await _memberRepo.createMemberProfile(newProfile);
      } catch (firestoreError) {
        // Rollback: delete photo from storage and delete auth user to prevent orphaned resources
        try {
          await _storageRepo.deleteProfilePhoto(user.uid);
          await user.delete();
        } catch (_) {
          await _authRepo.signOut();
        }
        rethrow;
      }

      // 5. Update state to authenticated with pending status
      state = AuthState(
        isAuthenticated: true,
        status: MemberStatus.pending,
        uid: user.uid,
        email: newProfile.email,
        fullName: newProfile.fullName,
        profile: newProfile,
        isLoading: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Re-fetches the Firestore member profile to verify if committee approved the account
  Future<MemberStatus> refreshStatus() async {
    final currentUid = state.uid ?? _authRepo.currentUser?.uid;
    if (currentUid == null) {
      return MemberStatus.none;
    }

    state = state.copyWith(isLoading: true);

    try {
      final profile = await _memberRepo.getMemberProfile(currentUid);
      if (profile != null) {
        state = state.copyWith(
          status: profile.status,
          fullName: profile.fullName,
          profile: profile,
          isLoading: false,
        );
        return profile.status;
      }
    } catch (_) {
      // If error occurs during refresh, keep current state
    }

    state = state.copyWith(isLoading: false);
    return state.status;
  }

  /// Send password reset email via Firebase Auth
  Future<bool> sendPasswordReset(String email) async {
    try {
      await _authRepo.sendPasswordResetEmail(email);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  /// Sign out from Firebase Authentication and reset state
  Future<void> signOut() async {
    try {
      NotificationService.instance.clearSession();
      await _authRepo.signOut();
    } catch (_) {}
    state = AuthState.unauthenticated();
  }

  /// Silently registers the FCM device token with the backend in the background
  void _syncFcmToken(String uid) {
    Future.microtask(() async {
      try {
        final idToken = await _authRepo.getIdToken();
        await NotificationService.instance.registerTokenWithBackend(
          uid: uid,
          idToken: idToken,
        );
      } catch (_) {
        // Non-blocking background registration
      }
    });
  }
}

/// Global provider for the authentication state
final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
