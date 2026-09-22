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

/// Priority filter notifier for announcements
class AnnouncementPriorityFilterNotifier
    extends Notifier<AnnouncementPriority?> {
  @override
  AnnouncementPriority? build() => null;

  void setPriority(AnnouncementPriority? priority) => state = priority;
}

final announcementPriorityFilterProvider =
    NotifierProvider<AnnouncementPriorityFilterNotifier,
        AnnouncementPriority?>(
  AnnouncementPriorityFilterNotifier.new,
);

/// Combined filtered announcements provider respecting search and priority filters.
/// Staff users view all announcements (with drafts); ordinary members view published only.
final filteredAnnouncementsProvider = Provider<AsyncValue<List<Announcement>>>((ref) {
  final isStaff = ref.watch(isStaffUserProvider);
  final announcementsAsync = isStaff
      ? ref.watch(allAnnouncementsStreamProvider)
      : ref.watch(publishedAnnouncementsStreamProvider);

  final searchQuery =
      ref.watch(announcementSearchQueryProvider).trim().toLowerCase();
  final priorityFilter = ref.watch(announcementPriorityFilterProvider);

  return announcementsAsync.whenData((list) {
    return list.where((item) {
      // 1. Priority filter
      if (priorityFilter != null && item.priority != priorityFilter) {
        return false;
      }

      // 2. Search query (matches title or description)
      if (searchQuery.isNotEmpty) {
        final matchesTitle = item.title.toLowerCase().contains(searchQuery);
        final matchesBody =
            item.description.toLowerCase().contains(searchQuery);
        if (!matchesTitle && !matchesBody) return false;
      }

      return true;
    }).toList();
  });
});

/// Fetches a single announcement by ID
final announcementDetailProvider =
    FutureProvider.family<Announcement?, String>((ref, id) {
  final repo = ref.watch(announcementRepositoryProvider);
  return repo.getAnnouncementById(id);
});
