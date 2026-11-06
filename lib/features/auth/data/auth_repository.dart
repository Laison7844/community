import 'package:firebase_auth/firebase_auth.dart';

/// Repository responsible for direct communication with Firebase Authentication.
class AuthRepository {
  final FirebaseAuth? _customAuth;

  AuthRepository({FirebaseAuth? firebaseAuth}) : _customAuth = firebaseAuth;

  FirebaseAuth get _firebaseAuth => _customAuth ?? FirebaseAuth.instance;

  /// Stream of user authentication state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Current signed-in Firebase user
  User? get currentUser => _firebaseAuth.currentUser;

  /// Retrieves Firebase ID token for backend API authentication
  Future<String?> getIdToken([bool forceRefresh = false]) async {
    try {
      return await _firebaseAuth.currentUser?.getIdToken(forceRefresh);
    } catch (_) {
      return null;
    }
  }

  /// Sign up with email and password
  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw getFriendlyErrorMessage(e);
    } catch (e) {
      throw 'An unexpected error occurred during registration. Please try again.';
    }
  }

  /// Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw getFriendlyErrorMessage(e);
    } catch (e) {
      throw 'An unexpected error occurred while signing in. Please try again.';
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw getFriendlyErrorMessage(e);
    } catch (e) {
      throw 'Could not send password reset email. Please try again.';
    }
  }

  /// Sign out from Firebase Authentication
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw 'Failed to sign out. Please try again.';
    }
  }

  /// Converts technical Firebase Auth error codes into clear, user-friendly messages
  static String getFriendlyErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No church account found with this email. Please check the address or request access.';
      case 'wrong-password':
        return 'Incorrect password. Please try again or tap "Forgot Password".';
      case 'invalid-credential':
        return 'Invalid email or password. Please verify your credentials.';
      case 'email-already-in-use':
        return 'An account with this email already exists. Please sign in instead.';
      case 'weak-password':
        return 'The password entered is too weak. Please use at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This church account has been disabled. Please contact the church committee.';
      case 'too-many-requests':
        return 'Too many sign-in attempts. Please wait a few moments before trying again.';
      case 'network-request-failed':
        return 'Network error: Please check your internet connection and try again.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is currently not enabled in the Firebase Console.';
      default:
        return e.message ?? 'Authentication failed. Please check your credentials.';
    }
  }
}
