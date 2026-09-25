import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/models/auth_state.dart';
import '../../auth/models/member_profile.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/admin_repository.dart';
import '../models/audit_log.dart';

/// Provider for AdminRepository
final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository();
});

/// Provider checking whether current authenticated user has authorized staff roles:
/// 'admin', 'committee', or 'pastor' and has approved status
final isStaffUserProvider = Provider<bool>((ref) {
  final auth = ref.watch(authProvider);
  if (!auth.isAuthenticated || auth.profile == null) return false;
  if (auth.profile!.status != MemberStatus.approved) return false;
  final role = auth.profile!.role.toLowerCase();
  return ['admin', 'committee', 'pastor'].contains(role);
});

/// Provider checking whether current authenticated user is an approved church member.
final isApprovedMemberProvider = Provider<bool>((ref) {
  final auth = ref.watch(authProvider);
  if (!auth.isAuthenticated || auth.profile == null) return false;
  return auth.profile!.status == MemberStatus.approved;
});

/// Streams all members from Firestore
final allMembersStreamProvider = StreamProvider<List<MemberProfile>>((ref) {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.streamAllMembers();
});

/// Streams verification audit logs
final auditLogsStreamProvider = StreamProvider<List<AuditLog>>((ref) {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.streamAuditLogs();
});

/// Notifier for currently selected status tab filter
class AdminStatusFilterNotifier extends Notifier<MemberStatus?> {
  @override
  MemberStatus? build() => MemberStatus.pending;

  void setFilter(MemberStatus? filter) => state = filter;
}

/// Currently selected status tab filter in Admin Dashboard (defaults to pending)
final adminStatusFilterProvider =
    NotifierProvider<AdminStatusFilterNotifier, MemberStatus?>(
  AdminStatusFilterNotifier.new,
);

/// Notifier for current search query string
class AdminSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
}

/// Current search query string in Admin Dashboard
final adminSearchQueryProvider =
    NotifierProvider<AdminSearchQueryNotifier, String>(
  AdminSearchQueryNotifier.new,
);

/// Aggregate statistics of members grouped by status
final memberCountsProvider = Provider<Map<MemberStatus, int>>((ref) {
  final membersAsync = ref.watch(allMembersStreamProvider);
  final counts = <MemberStatus, int>{
    MemberStatus.pending: 0,
    MemberStatus.approved: 0,
    MemberStatus.rejected: 0,
    MemberStatus.suspended: 0,
  };

  membersAsync.whenData((list) {
    for (final m in list) {
      if (counts.containsKey(m.status)) {
        counts[m.status] = counts[m.status]! + 1;
      }
    }
  });

  return counts;
});

/// Filtered list of members combining status filter and search query (family number, name, email)
final filteredMembersProvider = Provider<List<MemberProfile>>((ref) {
  final membersAsync = ref.watch(allMembersStreamProvider);
  final statusFilter = ref.watch(adminStatusFilterProvider);
  final searchQuery = ref.watch(adminSearchQueryProvider).trim().toLowerCase();

  return membersAsync.maybeWhen(
    data: (members) {
      return members.where((m) {
        // 1. Status filter (if specific tab selected)
        if (statusFilter != null && m.status != statusFilter) {
          return false;
        }

        // 2. Search query (matches family number, official full name, or email)
        if (searchQuery.isNotEmpty) {
          final matchesFamilyNumber =
              m.familyNumber.toLowerCase().contains(searchQuery);
          final matchesName = m.fullName.toLowerCase().contains(searchQuery);
          final matchesEmail = m.email.toLowerCase().contains(searchQuery);

          if (!matchesFamilyNumber && !matchesName && !matchesEmail) {
            return false;
          }
        }

        return true;
      }).toList();
    },
    orElse: () => [],
  );
});
