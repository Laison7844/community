import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../admin/providers/admin_provider.dart';
import '../data/announcement_repository.dart';
import '../models/announcement.dart';
import '../models/announcement_audit_log.dart';

/// Provider for AnnouncementRepository
final announcementRepositoryProvider = Provider<AnnouncementRepository>((ref) {
  return AnnouncementRepository();
});

/// Streams published announcements (for church members)
final publishedAnnouncementsStreamProvider =
    StreamProvider<List<Announcement>>((ref) {
  final repo = ref.watch(announcementRepositoryProvider);
  return repo.streamPublishedAnnouncements();
});

/// Streams all announcements including drafts (for authorized committee/staff)
final allAnnouncementsStreamProvider =
    StreamProvider<List<Announcement>>((ref) {
  final repo = ref.watch(announcementRepositoryProvider);
  return repo.streamAllAnnouncements();
});

/// Streams announcement audit logs (for authorized committee/staff)
final announcementAuditLogsStreamProvider =
    StreamProvider<List<AnnouncementAuditLog>>((ref) {
  final repo = ref.watch(announcementRepositoryProvider);
  return repo.streamAuditLogs();
});

/// Search query notifier for announcements
class AnnouncementSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
}

final announcementSearchQueryProvider =
    NotifierProvider<AnnouncementSearchQueryNotifier, String>(
  AnnouncementSearchQueryNotifier.new,
);

/// Type filter notifier for announcements (Marriage / General / Special)
class AnnouncementTypeFilterNotifier extends Notifier<AnnouncementType?> {
  @override
  AnnouncementType? build() => null;

  void setType(AnnouncementType? type) => state = type;
}

final announcementTypeFilterProvider =
    NotifierProvider<AnnouncementTypeFilterNotifier, AnnouncementType?>(
  AnnouncementTypeFilterNotifier.new,
);

/// Deprecated legacy priority filter retained strictly for compatibility
@Deprecated('Use announcementTypeFilterProvider instead')
class AnnouncementPriorityFilterNotifier
    extends Notifier<AnnouncementPriority?> {
  @override
  AnnouncementPriority? build() => null;

  void setPriority(AnnouncementPriority? priority) => state = priority;
}

@Deprecated('Use announcementTypeFilterProvider instead')
final announcementPriorityFilterProvider =
    NotifierProvider<AnnouncementPriorityFilterNotifier,
        AnnouncementPriority?>(
  AnnouncementPriorityFilterNotifier.new,
);

/// Publication status filter for staff management (All / Published / Draft)
enum AnnouncementStatusFilter {
  all,
  published,
  draft;

  String get displayName {
    switch (this) {
      case AnnouncementStatusFilter.all:
        return 'All Notices';
      case AnnouncementStatusFilter.published:
        return 'Published';
      case AnnouncementStatusFilter.draft:
        return 'Drafts';
    }
  }
}

class AnnouncementStatusFilterNotifier
    extends Notifier<AnnouncementStatusFilter> {
  @override
  AnnouncementStatusFilter build() => AnnouncementStatusFilter.all;

  void setFilter(AnnouncementStatusFilter filter) => state = filter;
}

final announcementStatusFilterProvider =
    NotifierProvider<AnnouncementStatusFilterNotifier,
        AnnouncementStatusFilter>(
  AnnouncementStatusFilterNotifier.new,
);

/// Combined filtered announcements provider respecting search, type, and publication filters.
/// Staff users view all announcements (with drafts); ordinary members view published only.
final filteredAnnouncementsProvider = Provider<AsyncValue<List<Announcement>>>((ref) {
  final isStaff = ref.watch(isStaffUserProvider);
  final announcementsAsync = isStaff
      ? ref.watch(allAnnouncementsStreamProvider)
      : ref.watch(publishedAnnouncementsStreamProvider);

  final searchQuery =
      ref.watch(announcementSearchQueryProvider).trim().toLowerCase();
  final typeFilter = ref.watch(announcementTypeFilterProvider);
  final statusFilter = isStaff
      ? ref.watch(announcementStatusFilterProvider)
      : AnnouncementStatusFilter.all;

  return announcementsAsync.whenData((list) {
    final now = DateTime.now();
    return list.where((item) {
      // 1. Publication status filter (staff only)
      if (isStaff) {
        if (statusFilter == AnnouncementStatusFilter.published && !item.isPublished) {
          return false;
        }
        if (statusFilter == AnnouncementStatusFilter.draft && item.isPublished) {
          return false;
        }
      } else {
        // Members only see published and validly unexpired announcements
        if (!item.isVisibleForMembers(now)) {
          return false;
        }
      }

      // 2. Type filter
      if (typeFilter != null && item.announcementType != typeFilter) {
        return false;
      }

      // 3. Search query (matches title, description, bride/groom names/details)
      if (searchQuery.isNotEmpty) {
        final matchesTitle = item.title.toLowerCase().contains(searchQuery);
        final matchesBody = item.description.toLowerCase().contains(searchQuery);
        final matchesBride = item.brideName?.toLowerCase().contains(searchQuery) ?? false;
        final matchesGroom = item.groomName?.toLowerCase().contains(searchQuery) ?? false;
        final matchesBrideDetails = item.brideDetails?.toLowerCase().contains(searchQuery) ?? false;
        final matchesGroomDetails = item.groomDetails?.toLowerCase().contains(searchQuery) ?? false;

        if (!matchesTitle &&
            !matchesBody &&
            !matchesBride &&
            !matchesGroom &&
            !matchesBrideDetails &&
            !matchesGroomDetails) {
          return false;
        }
      }

      return true;
    }).toList();
  });
});

/// Fetches an announcement by ID, checking the active in-memory stream cache first
final announcementDetailProvider =
    FutureProvider.family<Announcement?, String>((ref, id) {
  final isStaff = ref.watch(isStaffUserProvider);
  final announcementsAsync = isStaff
      ? ref.watch(allAnnouncementsStreamProvider)
      : ref.watch(publishedAnnouncementsStreamProvider);

  final cachedList = announcementsAsync.asData?.value;
  if (cachedList != null) {
    try {
      return cachedList.firstWhere((a) => a.id == id);
    } catch (_) {
      // Document not found in stream cache; fall back to direct fetch
    }
  }

  final repo = ref.watch(announcementRepositoryProvider);
  return repo.getAnnouncementById(id);
});
