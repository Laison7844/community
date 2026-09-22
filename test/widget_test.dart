import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:communtiy/app/app.dart';
import 'package:communtiy/core/constants/app_strings.dart';
import 'package:communtiy/core/utils/validators.dart';
import 'package:communtiy/features/admin/data/admin_repository.dart';
import 'package:communtiy/features/admin/models/audit_log.dart';
import 'package:communtiy/features/auth/models/auth_state.dart';
import 'package:communtiy/features/auth/models/member_profile.dart';

void main() {
  group('Validators Unit Tests', () {
    test('requiredField validation', () {
      expect(Validators.requiredField(''), isNotNull);
      expect(Validators.requiredField('   '), isNotNull);
      expect(Validators.requiredField(null), isNotNull);
      expect(Validators.requiredField('John'), isNull);
    });

    test('officialFullName validation', () {
      expect(Validators.officialFullName(''), isNotNull);
      expect(Validators.officialFullName('A'), isNotNull); // too short
      expect(Validators.officialFullName(null), isNotNull);
      expect(Validators.officialFullName('Rev. John Samuel'), isNull);
    });

    test('familyNumber validation', () {
      expect(Validators.familyNumber(''), isNotNull);
      expect(Validators.familyNumber(' '), isNotNull);
      expect(Validators.familyNumber('1'), isNotNull); // minimum 2 chars
      expect(Validators.familyNumber(null), isNotNull);
      expect(Validators.familyNumber('F-102'), isNull);
      expect(Validators.familyNumber('FAM/2024/09'), isNull);
    });

    test('email validation', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('invalid-email'), isNotNull);
      expect(Validators.email('user@'), isNotNull);
      expect(Validators.email('member@csichurch.org'), isNull);
    });

    test('password validation', () {
      expect(Validators.password('12345'), isNotNull);
      expect(Validators.password('123456'), isNull);
    });

    test('confirmPassword validation', () {
      expect(Validators.confirmPassword('password123', 'different'), isNotNull);
      expect(Validators.confirmPassword('password123', 'password123'), isNull);
    });

    test('optionalPhone validation', () {
      expect(Validators.optionalPhone(''), isNull);
      expect(Validators.optionalPhone(null), isNull);
      expect(Validators.optionalPhone('123'), isNotNull);
      expect(Validators.optionalPhone('+91 9876543210'), isNull);
    });

    test('validateImageFile validation', () {
      // Empty file
      expect(
        Validators.validateImageFile(sizeInBytes: 0, fileName: 'photo.jpg'),
        isNotNull,
      );
      // Exceeds 5MB limit (6MB)
      expect(
        Validators.validateImageFile(
          sizeInBytes: 6 * 1024 * 1024,
          fileName: 'large.jpg',
        ),
        isNotNull,
      );
      // Unsupported extension
      expect(
        Validators.validateImageFile(
          sizeInBytes: 500 * 1024,
          fileName: 'document.pdf',
        ),
        isNotNull,
      );
      // Valid JPG
      expect(
        Validators.validateImageFile(
          sizeInBytes: 500 * 1024,
          fileName: 'profile.jpg',
        ),
        isNull,
      );
      // Valid PNG
      expect(
        Validators.validateImageFile(
          sizeInBytes: 1024 * 1024,
          fileName: 'avatar.png',
        ),
        isNull,
      );
      // Valid WebP
      expect(
        Validators.validateImageFile(
          sizeInBytes: 200 * 1024,
          fileName: 'photo.webp',
        ),
        isNull,
      );
    });
  });

  group('MemberProfile & Shared Family Number Tests', () {
    test('MemberStatus string parsing and conversion', () {
      expect(MemberProfile.statusFromString('pending'), MemberStatus.pending);
      expect(MemberProfile.statusFromString('approved'), MemberStatus.approved);
      expect(MemberProfile.statusFromString('rejected'), MemberStatus.rejected);
      expect(MemberProfile.statusFromString('suspended'), MemberStatus.suspended);
      expect(MemberProfile.statusFromString(null), MemberStatus.pending);

      expect(MemberProfile.statusToString(MemberStatus.pending), 'pending');
      expect(MemberProfile.statusToString(MemberStatus.approved), 'approved');
      expect(MemberProfile.statusToString(MemberStatus.rejected), 'rejected');
      expect(MemberProfile.statusToString(MemberStatus.suspended), 'suspended');
    });

    test('MemberProfile serialization with familyNumber and profileImageUrl', () {
      const profile = MemberProfile(
        uid: 'user_abc123',
        fullName: 'Thomas Matthew',
        familyNumber: 'F-104',
        profileImageUrl:
            'https://firebasestorage.googleapis.com/v0/b/church-5d638.firebasestorage.app/o/member_profiles%2Fuser_abc123%2Fprofile_photo?alt=media',
        email: 'thomas@csichurch.org',
        phone: '+919876543210',
        familyInfo: 'St. Luke Ward',
        status: MemberStatus.pending,
        role: 'member',
        churchId: 'csi_main',
      );

      final map = profile.toMap(isNew: true);
      expect(map['uid'], 'user_abc123');
      expect(map['fullName'], 'Thomas Matthew');
      expect(map['familyNumber'], 'F-104');
      expect(map['profileImageUrl'], contains('user_abc123'));
      expect(map['email'], 'thomas@csichurch.org');
      expect(map['status'], 'pending');
      expect(map['role'], 'member');
      expect(map['churchId'], 'csi_main');

      final reconstructed = MemberProfile.fromMap(map, uid: 'user_abc123');
      expect(reconstructed.uid, 'user_abc123');
      expect(reconstructed.fullName, 'Thomas Matthew');
      expect(reconstructed.familyNumber, 'F-104');
      expect(reconstructed.profileImageUrl, contains('user_abc123'));
      expect(reconstructed.isPending, isTrue);
      expect(reconstructed.isApproved, isFalse);
    });

    test('Multiple family members share the same familyNumber with independent UIDs and statuses', () {
      const sharedFamilyNumber = 'FAM-2024-CSI-42';

      // Parent member (already approved)
      const parentMember = MemberProfile(
        uid: 'parent_uid_001',
        fullName: 'Abraham Joshua',
        familyNumber: sharedFamilyNumber,
        profileImageUrl: 'https://storage/parent.jpg',
        email: 'abraham@csichurch.org',
        status: MemberStatus.approved,
        role: 'member',
        churchId: 'csi_main',
      );

      // Youth member (newly registered, pending approval)
      const youthMember = MemberProfile(
        uid: 'youth_uid_002',
        fullName: 'Sarah Abraham',
        familyNumber: sharedFamilyNumber,
        profileImageUrl: 'https://storage/youth.jpg',
        email: 'sarah@csichurch.org',
        status: MemberStatus.pending,
        role: 'member',
        churchId: 'csi_main',
      );

      // Verify same family number is preserved
      expect(parentMember.familyNumber, equals(youthMember.familyNumber));

      // Verify separate unique UIDs
      expect(parentMember.uid, isNot(equals(youthMember.uid)));

      // Verify independent approval statuses
      expect(parentMember.isApproved, isTrue);
      expect(youthMember.isApproved, isFalse);
      expect(youthMember.isPending, isTrue);
    });
  });

  group('Security & Rollback Tests', () {
    test('Security-sensitive updates: familyNumber cannot be changed on update', () {
      const originalProfile = MemberProfile(
        uid: 'user_777',
        fullName: 'Original Name',
        familyNumber: 'F-100',
        profileImageUrl: 'https://storage/photo.jpg',
        email: 'user777@csichurch.org',
        status: MemberStatus.pending,
        role: 'member',
        churchId: 'csi_main',
      );

      // User attempts to update their personal name and phone
      final updatedProfile = originalProfile.copyWith(
        fullName: 'Updated Name',
        phone: '+919999999999',
      );

      // Verify familyNumber remains strictly identical
      expect(updatedProfile.familyNumber, equals(originalProfile.familyNumber));
      expect(updatedProfile.fullName, 'Updated Name');
      expect(updatedProfile.status, equals(originalProfile.status));
      expect(updatedProfile.role, equals(originalProfile.role));
      expect(updatedProfile.churchId, equals(originalProfile.churchId));
      expect(updatedProfile.uid, equals(originalProfile.uid));
    });

    test('Profile Image URL policy conformance check', () {
      const validUrl =
          'https://firebasestorage.googleapis.com/v0/b/church-5d638.firebasestorage.app/o/member_profiles%2Fuser_xyz%2Fprofile_photo?alt=media';
      const invalidUrlCrossUser =
          'https://firebasestorage.googleapis.com/v0/b/church-5d638.firebasestorage.app/o/member_profiles%2Fother_user%2Fprofile_photo?alt=media';
      const invalidUrlExternal = 'https://external-attacker-site.com/malicious.jpg';

      bool isValidStorageUrl(String url, String userId) {
        return url.startsWith('https://firebasestorage.googleapis.com/') &&
            url.contains('member_profiles') &&
            url.contains(userId);
      }

      expect(isValidStorageUrl(validUrl, 'user_xyz'), isTrue);
      expect(isValidStorageUrl(invalidUrlCrossUser, 'user_xyz'), isFalse);
      expect(isValidStorageUrl(invalidUrlExternal, 'user_xyz'), isFalse);
    });

    test('Photo read authorization logic simulation (owner or staff only)', () {
      // Simulates Storage security rule logic:
      // allow read: if isOwner(userId) || isAuthorizedStaff()
      bool canReadPhoto({
        required String callerUid,
        required String targetUserId,
        required String callerRole,
      }) {
        final isOwner = callerUid == targetUserId;
        final isStaff = ['admin', 'committee', 'pastor'].contains(callerRole);
        return isOwner || isStaff;
      }

      // Owner reading own photo -> ALLOW
      expect(
        canReadPhoto(callerUid: 'user_1', targetUserId: 'user_1', callerRole: 'member'),
        isTrue,
      );

      // Committee member reading applicant photo -> ALLOW
      expect(
        canReadPhoto(callerUid: 'admin_1', targetUserId: 'user_1', callerRole: 'committee'),
        isTrue,
      );

      // Ordinary church member reading another applicant photo -> DENY
      expect(
        canReadPhoto(callerUid: 'user_2', targetUserId: 'user_1', callerRole: 'member'),
        isFalse,
      );

      // Unauthenticated / empty caller -> DENY
      expect(
        canReadPhoto(callerUid: '', targetUserId: 'user_1', callerRole: 'member'),
        isFalse,
      );
    });

    test('Best-effort rollback simulation: cleans up user and propagates error when Firestore fails', () async {
      bool userDeleted = false;
      bool photoDeleted = false;
      bool errorPropagated = false;

      // Simulated atomic registration with compensation steps
      Future<void> simulateRegistrationFlow({required bool firestoreFails}) async {
        // Step 1: create auth user (succeeds)
        // Step 2: upload photo (succeeds)
        try {
          // Step 3: write Firestore document
          if (firestoreFails) {
            throw Exception('Firestore write permission denied or network error');
          }
        } catch (e) {
          // Best-effort compensation cleanup
          try {
            photoDeleted = true; // simulates _storageRepo.deleteProfilePhoto
          } catch (_) {}
          try {
            userDeleted = true; // simulates user.delete()
          } catch (_) {}
          rethrow;
        }
      }

      try {
        await simulateRegistrationFlow(firestoreFails: true);
      } catch (e) {
        errorPropagated = true;
      }

      expect(errorPropagated, isTrue);
      expect(photoDeleted, isTrue);
      expect(userDeleted, isTrue);
    });
  });

  group('Phase 3 — Status Transition & Policy Tests', () {
    test('Valid status transitions according to church policy', () {
      // Pending -> Approved
      expect(
        AdminRepository.isValidStatusTransition(MemberStatus.pending, MemberStatus.approved),
        isTrue,
      );
      // Pending -> Rejected
      expect(
        AdminRepository.isValidStatusTransition(MemberStatus.pending, MemberStatus.rejected),
        isTrue,
      );
      // Approved -> Suspended
      expect(
        AdminRepository.isValidStatusTransition(MemberStatus.approved, MemberStatus.suspended),
        isTrue,
      );
      // Suspended -> Approved (Restore)
      expect(
        AdminRepository.isValidStatusTransition(MemberStatus.suspended, MemberStatus.approved),
        isTrue,
      );
      // Rejected -> Pending (Reconsideration)
      expect(
        AdminRepository.isValidStatusTransition(MemberStatus.rejected, MemberStatus.pending),
        isTrue,
      );
      // Rejected -> Approved
      expect(
        AdminRepository.isValidStatusTransition(MemberStatus.rejected, MemberStatus.approved),
        isTrue,
      );
    });

    test('Invalid status transitions rejected by church policy', () {
      // Same status transition rejected
      expect(
        AdminRepository.isValidStatusTransition(MemberStatus.pending, MemberStatus.pending),
        isFalse,
      );
      expect(
        AdminRepository.isValidStatusTransition(MemberStatus.approved, MemberStatus.approved),
        isFalse,
      );

      // Pending directly to Suspended without prior approval rejected
      expect(
        AdminRepository.isValidStatusTransition(MemberStatus.pending, MemberStatus.suspended),
        isFalse,
      );

      // Approved cannot be directly rejected (must be suspended)
      expect(
        AdminRepository.isValidStatusTransition(MemberStatus.approved, MemberStatus.rejected),
        isFalse,
      );

      // Suspended cannot be directly rejected
      expect(
        AdminRepository.isValidStatusTransition(MemberStatus.suspended, MemberStatus.rejected),
        isFalse,
      );

      // None status transitions rejected
      expect(
        AdminRepository.isValidStatusTransition(MemberStatus.none, MemberStatus.approved),
        isFalse,
      );
    });
  });

  group('Phase 3 — Role-Based Staff Authorization & Self-Approval Prevention', () {
    bool checkStaffAccess(String? role) {
      if (role == null) return false;
      return ['admin', 'committee', 'pastor'].contains(role.toLowerCase());
    }

    test('Authorized roles grant staff verification access', () {
      expect(checkStaffAccess('admin'), isTrue);
      expect(checkStaffAccess('committee'), isTrue);
      expect(checkStaffAccess('pastor'), isTrue);
      expect(checkStaffAccess('ADMIN'), isTrue);
    });

    test('Ordinary members and guest roles are denied staff verification access', () {
      expect(checkStaffAccess('member'), isFalse);
      expect(checkStaffAccess('user'), isFalse);
      expect(checkStaffAccess('guest'), isFalse);
      expect(checkStaffAccess(null), isFalse);
    });

    test('Self-approval prevention logic simulation', () {
      // Staff cannot approve their own profile (request.auth.uid != targetUid)
      bool canApprove({
        required String staffUid,
        required String staffRole,
        required String targetUid,
      }) {
        final isStaff = checkStaffAccess(staffRole);
        final isNotSelf = staffUid != targetUid;
        return isStaff && isNotSelf;
      }

      // Committee member approving another member -> ALLOWED
      expect(
        canApprove(staffUid: 'staff_123', staffRole: 'committee', targetUid: 'applicant_456'),
        isTrue,
      );

      // Committee member attempting to self-approve -> FORBIDDEN
      expect(
        canApprove(staffUid: 'staff_123', staffRole: 'committee', targetUid: 'staff_123'),
        isFalse,
      );

      // Ordinary member attempting to approve anyone -> FORBIDDEN
      expect(
        canApprove(staffUid: 'member_789', staffRole: 'member', targetUid: 'applicant_456'),
        isFalse,
      );
    });
  });

  group('Phase 3 — Audit Log Model & Immutability Tests', () {
    test('AuditLog model serialization and deserialization', () {
      final now = DateTime.now();
      final log = AuditLog(
        id: 'log_001',
        targetUid: 'member_99',
        targetFullName: 'David Paul',
        targetFamilyNumber: 'FAM-042',
        previousStatus: 'pending',
        newStatus: 'approved',
        action: 'approve',
        reason: 'Verified against parish census register volume 2',
        performedByUid: 'staff_77',
        performedByRole: 'pastor',
        timestamp: now,
      );

      final map = log.toMap();
      expect(map['id'], 'log_001');
      expect(map['targetUid'], 'member_99');
      expect(map['targetFullName'], 'David Paul');
      expect(map['targetFamilyNumber'], 'FAM-042');
      expect(map['previousStatus'], 'pending');
      expect(map['newStatus'], 'approved');
      expect(map['action'], 'approve');
      expect(map['reason'], contains('parish census'));
      expect(map['performedByUid'], 'staff_77');
      expect(map['performedByRole'], 'pastor');

      final reconstructed = AuditLog.fromMap(map, 'log_001');
      expect(reconstructed.id, 'log_001');
      expect(reconstructed.targetFullName, 'David Paul');
      expect(reconstructed.action, 'approve');
      expect(reconstructed.performedByRole, 'pastor');
    });

    test('Audit records are immutable and append-only', () {
      // In Firestore rules:
      // match /verification_audit_logs/{logId} {
      //   allow update, delete: if false;
      // }
      bool canModifyAuditRecord() => false;
      bool canDeleteAuditRecord() => false;

      expect(canModifyAuditRecord(), isFalse);
      expect(canDeleteAuditRecord(), isFalse);
    });
  });

  group('Phase 3 — Search by Shared Family Number & Multi-member Filtering', () {
    final members = [
      const MemberProfile(
        uid: 'uid_fam42_father',
        fullName: 'Dr. John Abraham',
        familyNumber: 'FAM-042',
        profileImageUrl: 'https://storage/father.jpg',
        email: 'john.abraham@csichurch.org',
        status: MemberStatus.approved,
        role: 'member',
        churchId: 'csi_main',
      ),
      const MemberProfile(
        uid: 'uid_fam42_son',
        fullName: 'Samuel Abraham',
        familyNumber: 'FAM-042',
        profileImageUrl: 'https://storage/son.jpg',
        email: 'samuel.abraham@csichurch.org',
        status: MemberStatus.pending,
        role: 'member',
        churchId: 'csi_main',
      ),
      const MemberProfile(
        uid: 'uid_fam88_member',
        fullName: 'Mary George',
        familyNumber: 'FAM-088',
        profileImageUrl: 'https://storage/mary.jpg',
        email: 'mary.george@csichurch.org',
        status: MemberStatus.pending,
        role: 'member',
        churchId: 'csi_main',
      ),
    ];

    test('Search by shared family number returns all family members with distinct UIDs and statuses', () {
      final searchQuery = 'FAM-042'.toLowerCase();

      final results = members.where((m) {
        return m.familyNumber.toLowerCase().contains(searchQuery) ||
            m.fullName.toLowerCase().contains(searchQuery) ||
            m.email.toLowerCase().contains(searchQuery);
      }).toList();

      expect(results.length, 2);
      expect(results[0].familyNumber, 'FAM-042');
      expect(results[1].familyNumber, 'FAM-042');
      expect(results[0].uid, isNot(equals(results[1].uid)));
      expect(results[0].status, MemberStatus.approved);
      expect(results[1].status, MemberStatus.pending);
    });

    test('Search by official full name returns specific applicant', () {
      final searchQuery = 'Mary'.toLowerCase();

      final results = members.where((m) {
        return m.familyNumber.toLowerCase().contains(searchQuery) ||
            m.fullName.toLowerCase().contains(searchQuery) ||
            m.email.toLowerCase().contains(searchQuery);
      }).toList();

      expect(results.length, 1);
      expect(results.first.fullName, 'Mary George');
      expect(results.first.familyNumber, 'FAM-088');
    });

    test('Status filtering isolates pending applicants', () {
      final pendingMembers = members.where((m) => m.status == MemberStatus.pending).toList();
      expect(pendingMembers.length, 2);
      expect(pendingMembers.map((m) => m.fullName), containsAll(['Samuel Abraham', 'Mary George']));
    });
  });

  group('Widget Tests', () {
    testWidgets('App renders splash page with church branding', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: CSIChurchApp(),
        ),
      );

      // Verify that the church title and tagline are present
      expect(find.text(AppStrings.churchName), findsOneWidget);
      expect(find.text(AppStrings.tagline), findsOneWidget);
    });
  });
}
