import 'member_profile.dart';

/// Status of a church member account.
enum MemberStatus {
  none,       // Unauthenticated or not yet submitted
  pending,    // Submitted registration, awaiting committee approval
  approved,   // Active approved church member
  rejected,   // Registration rejected by church committee
  suspended,  // Member account suspended
}

/// Represents the current authentication and membership session state.
class AuthState {
  final bool isAuthenticated;
  final MemberStatus status;
  final String? uid;
  final String? email;
  final String? fullName;
  final MemberProfile? profile;
  final String? errorMessage;
  final bool isLoading;

  const AuthState({
    this.isAuthenticated = false,
    this.status = MemberStatus.none,
    this.uid,
    this.email,
    this.fullName,
    this.profile,
    this.errorMessage,
    this.isLoading = false,
  });

  /// Factory for an unauthenticated user
  factory AuthState.unauthenticated() => const AuthState();

  /// Creates a copy with optionally modified fields
  AuthState copyWith({
    bool? isAuthenticated,
    MemberStatus? status,
    String? uid,
    String? email,
    String? fullName,
    MemberProfile? profile,
    String? errorMessage,
    bool? isLoading,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      status: status ?? this.status,
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      profile: profile ?? this.profile,
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
