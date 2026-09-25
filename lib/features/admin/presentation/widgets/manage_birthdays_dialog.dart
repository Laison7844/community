import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_styles.dart';
import '../../../../core/widgets/member_avatar.dart';
import '../../../auth/models/auth_state.dart';
import '../../../auth/models/member_profile.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/admin_provider.dart';
import '../../../birthdays/models/anniversary_entry.dart';
import '../../../birthdays/models/birthday_anniversary_week.dart';
import '../../../birthdays/models/birthday_entry.dart';
import '../../../birthdays/providers/birthday_provider.dart';

/// Management dialog for church staff to manage the current weekly birthday & anniversary bulletin.
/// Locked to the current Monday -> Sunday week (no arbitrary week navigation).
class ManageBirthdaysDialog extends ConsumerStatefulWidget {
  final String? initialWeekId;

  const ManageBirthdaysDialog({super.key, this.initialWeekId});

  @override
  ConsumerState<ManageBirthdaysDialog> createState() =>
      _ManageBirthdaysDialogState();
}

class _ManageBirthdaysDialogState extends ConsumerState<ManageBirthdaysDialog> {
  late final DateTime _selectedMonday;
  late final DateTime _selectedSunday;
  late final String _weekId;

  bool _isLoading = true;
  String? _errorMessage;
  bool _isSaving = false;
  bool _isPublished = false;

  List<BirthdayEntry> _birthdays = [];
  List<AnniversaryEntry> _anniversaries = [];

  @override
  void initState() {
    super.initState();
    // Admin management manages the current applicable week only
    final now = DateTime.now();
    _selectedMonday = BirthdayAnniversaryWeek.getMondayOf(now);
    _selectedSunday = BirthdayAnniversaryWeek.getSundayOf(_selectedMonday);
    _weekId = BirthdayAnniversaryWeek.generateWeekId(_selectedMonday);
    _loadWeekData();
  }

  Future<void> _loadWeekData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(birthdayRepositoryProvider);

      // Safe cleanup of strictly past bulletins in background
      final auth = ref.read(authProvider);
      if (auth.uid != null) {
        repo.cleanupPastWeeks(performedByUid: auth.uid!);
      }

      final week = await repo.getWeek(_weekId);
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        if (week != null) {
          _isPublished = week.isPublished;
          _birthdays = List.from(week.birthdays);
          _anniversaries = List.from(week.anniversaries);
        } else {
          _isPublished = false;
          _birthdays = [];
          _anniversaries = [];
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (e.toString().contains('permission-denied')) {
          _errorMessage =
              'Permission Denied: Please verify your staff authorization (Admin, Committee, or Pastor).';
        } else {
          _errorMessage = 'Failed to load bulletin: $e';
        }
      });
    }
  }

  Future<void> _handleSave() async {
    setState(() {
      _isSaving = true;
    });

    final auth = ref.read(authProvider);
    final staffUid = auth.uid ?? '';
    final staffRole = auth.profile?.role ?? 'committee';
    final staffName = auth.fullName ?? 'Parish Staff';

    final week = BirthdayAnniversaryWeek(
      id: _weekId,
      weekStartDate: _selectedMonday,
      weekEndDate: _selectedSunday,
      churchId: 'csi_main',
      isPublished: _isPublished,
      birthdays: _birthdays,
      anniversaries: _anniversaries,
      createdBy: staffUid,
      createdByName: staffName,
      updatedAt: DateTime.now(),
    );

    try {
      final repo = ref.read(birthdayRepositoryProvider);
      await repo.saveWeeklyBulletin(
        week,
        performedByUid: staffUid,
        performedByRole: staffRole,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Weekly Bulletin saved successfully (${_isPublished ? "Published" : "Draft"}).',
          ),
          backgroundColor: AppColors.subtleOlive,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving bulletin: $e'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  void _openAddBirthdayDialog(List<MemberProfile> approvedMembers) async {
    final entry = await showDialog<BirthdayEntry>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AddBirthdayDialog(
        approvedMembers: approvedMembers,
        weekMonday: _selectedMonday,
        weekSunday: _selectedSunday,
        existingBirthdays: _birthdays,
      ),
    );

    if (entry != null && mounted) {
      setState(() {
        _birthdays.add(entry);
        _birthdays.sort((a, b) => a.eventDate.compareTo(b.eventDate));
      });
    }
  }

  void _openAddAnniversaryDialog(List<MemberProfile> approvedMembers) async {
    final entry = await showDialog<AnniversaryEntry>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AddAnniversaryDialog(
        approvedMembers: approvedMembers,
        weekMonday: _selectedMonday,
        weekSunday: _selectedSunday,
        existingAnniversaries: _anniversaries,
      ),
    );

    if (entry != null && mounted) {
      setState(() {
        _anniversaries.add(entry);
        _anniversaries.sort((a, b) => a.eventDate.compareTo(b.eventDate));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final allMembersAsync = ref.watch(allMembersStreamProvider);
    final approvedMembers = allMembersAsync.when(
      data: (list) =>
          list.where((m) => m.status == MemberStatus.approved).toList(),
      loading: () => <MemberProfile>[],
      error: (_, _) => <MemberProfile>[],
    );

    final weekRangeStr =
        '${DateFormat('MMM d').format(_selectedMonday)} – ${DateFormat('MMM d, y').format(_selectedSunday)}';

    return Dialog(
      backgroundColor: AppColors.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 880, maxHeight: 740),
        child: Padding(
          padding: const EdgeInsets.all(AppStyles.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header without arbitrary week navigation
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBrown.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.celebration_rounded,
                      color: AppColors.primaryBrown,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: AppStyles.space16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Manage Weekly Birthdays & Anniversaries',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryBrown,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              'Bulletin Week: $weekRangeStr',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.subtleOlive.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Current Week',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.subtleOlive,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Action Toolbar: Add buttons & Publish toggle
              Wrap(
                spacing: 12,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBrown,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.cake_rounded, size: 18),
                        label: const Text('+ Add Birthday'),
                        onPressed: _isLoading || _errorMessage != null
                            ? null
                            : () => _openAddBirthdayDialog(approvedMembers),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentWine,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.favorite_rounded, size: 18),
                        label: const Text('+ Add Anniversary'),
                        onPressed: _isLoading || _errorMessage != null
                            ? null
                            : () => _openAddAnniversaryDialog(approvedMembers),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: _isPublished,
                        activeThumbColor: Colors.white,
                        activeTrackColor: AppColors.subtleOlive,
                        onChanged: (val) {
                          setState(() {
                            _isPublished = val;
                          });
                        },
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isPublished
                            ? 'Published (Visible to all members)'
                            : 'Draft (Staff view only)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _isPublished
                              ? AppColors.subtleOlive
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppStyles.space16),

              // Body: Loading, Error, Empty, or Lists
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              color: AppColors.primaryBrown,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Loading current weekly bulletin...',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _errorMessage != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(AppStyles.space20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.error_outline_rounded,
                                      size: 48, color: AppColors.errorRed),
                                  const SizedBox(height: 12),
                                  Text(
                                    _errorMessage!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: AppColors.errorRed,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.refresh_rounded),
                                    label: const Text('Retry'),
                                    onPressed: _loadWeekData,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : _birthdays.isEmpty && _anniversaries.isEmpty
                            ? _buildCompletelyEmptyBulletinView(approvedMembers)
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Left: Birthdays Column
                                  Expanded(
                                    child: _buildBirthdaysListColumn(),
                                  ),
                                  const VerticalDivider(width: 28),
                                  // Right: Anniversaries Column
                                  Expanded(
                                    child: _buildAnniversariesListColumn(),
                                  ),
                                ],
                              ),
              ),
              const Divider(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_birthdays.length} Birthdays • ${_anniversaries.length} Anniversaries',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryBrown,
                    ),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed:
                            _isSaving ? null : () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: AppStyles.space12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBrown,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                        ),
                        icon: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_rounded, size: 18),
                        label: Text(_isSaving
                            ? 'Saving Bulletin...'
                            : 'Save Weekly Bulletin'),
                        onPressed: _isSaving ? null : _handleSave,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletelyEmptyBulletinView(List<MemberProfile> approvedMembers) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppStyles.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryBrown.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.calendar_view_week_rounded,
                size: 52,
                color: AppColors.primaryBrown,
              ),
            ),
            const SizedBox(height: AppStyles.space16),
            const Text(
              'No birthdays or anniversaries have been added for this week yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryBrown,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Click "+ Add Birthday" or "+ Add Anniversary" above to populate this week\'s parish bulletin.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppStyles.space20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.cake_rounded, color: AppColors.primaryBrown),
                  label: const Text('Add Birthday', style: TextStyle(color: AppColors.primaryBrown)),
                  onPressed: () => _openAddBirthdayDialog(approvedMembers),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.favorite_rounded, color: AppColors.accentWine),
                  label: const Text('Add Anniversary', style: TextStyle(color: AppColors.accentWine)),
                  onPressed: () => _openAddAnniversaryDialog(approvedMembers),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBirthdaysListColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.cake_rounded,
                size: 18, color: AppColors.primaryBrown),
            const SizedBox(width: 8),
            const Text(
              'Weekly Birthdays',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryBrown,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryBrown.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_birthdays.length}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryBrown,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppStyles.space8),
        Expanded(
          child: _birthdays.isEmpty
              ? Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(AppStyles.space16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const Text(
                    'No birthdays added yet.',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                )
              : ListView.builder(
                  itemCount: _birthdays.length,
                  itemBuilder: (context, i) {
                    final b = _birthdays[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: AppColors.softBeige),
                      ),
                      child: ListTile(
                        dense: true,
                        leading: MemberAvatar(
                          imageUrl: b.profileImageUrl,
                          radius: 18,
                        ),
                        title: Text(
                          b.memberName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${DateFormat('d MMM').format(b.eventDate)} • Age ${b.calculatedAge}${b.place != null && b.place!.isNotEmpty ? " • ${b.place}" : ""}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: IconButton(
                          tooltip: 'Remove',
                          icon: const Icon(Icons.delete_outline_rounded,
                              size: 18, color: AppColors.errorRed),
                          onPressed: () {
                            setState(() {
                              _birthdays.removeAt(i);
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAnniversariesListColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.favorite_rounded,
                size: 18, color: AppColors.accentWine),
            const SizedBox(width: 8),
            const Text(
              'Weekly Wedding Anniversaries',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.accentWine,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accentWine.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_anniversaries.length}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentWine,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppStyles.space8),
        Expanded(
          child: _anniversaries.isEmpty
              ? Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(AppStyles.space16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const Text(
                    'No wedding anniversaries added yet.',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                )
              : ListView.builder(
                  itemCount: _anniversaries.length,
                  itemBuilder: (context, i) {
                    final a = _anniversaries[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: AppColors.softBeige),
                      ),
                      child: ListTile(
                        dense: true,
                        leading: MemberAvatar(
                          imageUrl: a.profileImageUrl,
                          radius: 18,
                          iconColor: AppColors.accentWine,
                        ),
                        title: Text(
                          a.coupleName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${DateFormat('d MMM').format(a.eventDate)} • ${a.formattedAnniversaryOrdinal}${a.place != null && a.place!.isNotEmpty ? " • ${a.place}" : ""}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: IconButton(
                          tooltip: 'Remove',
                          icon: const Icon(Icons.delete_outline_rounded,
                              size: 18, color: AppColors.errorRed),
                          onPressed: () {
                            setState(() {
                              _anniversaries.removeAt(i);
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ============================================================================
// DEDICATED ADD BIRTHDAY DIALOG WITH SEARCHABLE MEMBER SELECTOR
// ============================================================================

class _AddBirthdayDialog extends StatefulWidget {
  final List<MemberProfile> approvedMembers;
  final DateTime weekMonday;
  final DateTime weekSunday;
  final List<BirthdayEntry> existingBirthdays;

  const _AddBirthdayDialog({
    required this.approvedMembers,
    required this.weekMonday,
    required this.weekSunday,
    required this.existingBirthdays,
  });

  @override
  State<_AddBirthdayDialog> createState() => _AddBirthdayDialogState();
}

class _AddBirthdayDialogState extends State<_AddBirthdayDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  MemberProfile? _selectedMember;
  DateTime? _selectedOccurrenceDate;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onMemberSelected(MemberProfile member) {
    setState(() {
      _selectedMember = member;

      // Calculate occurrence date within current week Monday..Sunday
      if (member.dateOfBirth != null) {
        final dob = member.dateOfBirth!;
        final occurrenceCandidate =
            DateTime(widget.weekMonday.year, dob.month, dob.day);
        if (!occurrenceCandidate.isBefore(widget.weekMonday) &&
            !occurrenceCandidate.isAfter(widget.weekSunday)) {
          _selectedOccurrenceDate = occurrenceCandidate;
        } else {
          _selectedOccurrenceDate = widget.weekMonday;
        }
      } else {
        _selectedOccurrenceDate = widget.weekMonday;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchQuery.trim().toLowerCase();
    final matchingMembers = widget.approvedMembers.where((m) {
      if (query.isEmpty) return true;
      final nameMatches = m.fullName.toLowerCase().contains(query);
      final familyMatches = m.familyNumber.toLowerCase().contains(query);
      return nameMatches || familyMatches;
    }).toList();

    final isAlreadyAdded = _selectedMember != null &&
        widget.existingBirthdays.any((b) => b.memberUid == _selectedMember!.uid);

    final calculatedAge = _selectedMember?.calculateAge(_selectedOccurrenceDate);

    return Dialog(
      backgroundColor: AppColors.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 660),
        child: Padding(
          padding: const EdgeInsets.all(AppStyles.space20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBrown.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.cake_rounded,
                        color: AppColors.primaryBrown, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Add Birthday to Bulletin',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryBrown,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 20),

              // Search Input
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search member',
                  hintText: 'Enter family number or member name...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
              ),
              const SizedBox(height: 12),

              // Results List (Scrollable)
              Expanded(
                child: matchingMembers.isEmpty
                    ? Center(
                        child: Text(
                          'No approved members found matching "$_searchQuery"',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 13),
                        ),
                      )
                    : ListView.builder(
                        itemCount: matchingMembers.length,
                        itemBuilder: (context, index) {
                          final m = matchingMembers[index];
                          final isSelected = _selectedMember?.uid == m.uid;
                          final existsInWeek = widget.existingBirthdays
                              .any((b) => b.memberUid == m.uid);

                          final dobStr = m.dateOfBirth != null
                              ? DateFormat('d MMM').format(m.dateOfBirth!)
                              : 'Not set';
                          final placeStr = m.place ?? m.familyInfo ?? '—';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryBrown.withValues(alpha: 0.08)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primaryBrown
                                    : AppColors.softBeige,
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: ListTile(
                              dense: true,
                              onTap: () => _onMemberSelected(m),
                              leading: MemberAvatar(
                                imageUrl: m.profileImageUrl,
                                radius: 18,
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      m.fullName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  if (existsInWeek)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.errorRed.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'Already added',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.errorRed,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Text(
                                'Family No: ${m.familyNumber} • Birthday: $dobStr • Place: $placeStr',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              trailing: Icon(
                                isSelected
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                color: isSelected
                                    ? AppColors.primaryBrown
                                    : Colors.grey.shade400,
                                size: 20,
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // Selected Details Panel
              if (_selectedMember != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isAlreadyAdded
                        ? AppColors.errorRed.withValues(alpha: 0.06)
                        : AppColors.backgroundIvory,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isAlreadyAdded
                          ? AppColors.errorRed.withValues(alpha: 0.3)
                          : AppColors.softBeige,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isAlreadyAdded) ...[
                        Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                size: 16, color: AppColors.errorRed),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${_selectedMember!.fullName} is already in this week\'s birthday bulletin.',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.errorRed,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Calculated Age: ${calculatedAge != null ? "$calculatedAge years" : "N/A"}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryBrown,
                                  ),
                                ),
                                Text(
                                  'Place: ${_selectedMember!.place ?? _selectedMember!.familyInfo ?? "Parish"}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                _selectedOccurrenceDate != null
                                    ? DateFormat('EEE, d MMM').format(_selectedOccurrenceDate!)
                                    : 'Pick Date',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Select occurrence date in week',
                                icon: const Icon(Icons.calendar_today_rounded,
                                    size: 18, color: AppColors.primaryBrown),
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _selectedOccurrenceDate ?? widget.weekMonday,
                                    firstDate: widget.weekMonday,
                                    lastDate: widget.weekSunday,
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      _selectedOccurrenceDate = picked;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              const Divider(height: 24),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBrown,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _selectedMember == null || isAlreadyAdded
                        ? null
                        : () {
                            final m = _selectedMember!;
                            final eventDate =
                                _selectedOccurrenceDate ?? widget.weekMonday;
                            final birthDate = m.dateOfBirth ?? DateTime(2000, 1, 1);

                            final entry = BirthdayEntry(
                              id: 'bday_${m.uid}_${eventDate.millisecondsSinceEpoch}',
                              memberUid: m.uid,
                              memberName: m.fullName,
                              eventDate: eventDate,
                              dateOfBirth: birthDate,
                              place: m.place ?? m.familyInfo,
                              profileImageUrl: m.profileImageUrl,
                            );
                            Navigator.pop(context, entry);
                          },
                    child: const Text('Add Birthday'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// DEDICATED ADD ANNIVERSARY DIALOG WITH SEARCHABLE COUPLE SELECTOR
// ============================================================================

class _AddAnniversaryDialog extends StatefulWidget {
  final List<MemberProfile> approvedMembers;
  final DateTime weekMonday;
  final DateTime weekSunday;
  final List<AnniversaryEntry> existingAnniversaries;

  const _AddAnniversaryDialog({
    required this.approvedMembers,
    required this.weekMonday,
    required this.weekSunday,
    required this.existingAnniversaries,
  });

  @override
  State<_AddAnniversaryDialog> createState() => _AddAnniversaryDialogState();
}

class _AddAnniversaryDialogState extends State<_AddAnniversaryDialog> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _coupleNameController = TextEditingController();
  String _searchQuery = '';
  MemberProfile? _selectedMember;
  DateTime? _selectedOccurrenceDate;

  @override
  void dispose() {
    _searchController.dispose();
    _coupleNameController.dispose();
    super.dispose();
  }

  void _onMemberSelected(MemberProfile member) {
    setState(() {
      _selectedMember = member;

      // Populate couple name (editable)
      if (member.spouseName != null && member.spouseName!.isNotEmpty) {
        _coupleNameController.text =
            '${member.fullName} & ${member.spouseName}';
      } else {
        _coupleNameController.text = '${member.fullName} & Spouse';
      }

      // Calculate occurrence date within current week Monday..Sunday
      if (member.weddingAnniversary != null) {
        final w = member.weddingAnniversary!;
        final occurrenceCandidate =
            DateTime(widget.weekMonday.year, w.month, w.day);
        if (!occurrenceCandidate.isBefore(widget.weekMonday) &&
            !occurrenceCandidate.isAfter(widget.weekSunday)) {
          _selectedOccurrenceDate = occurrenceCandidate;
        } else {
          _selectedOccurrenceDate = widget.weekMonday;
        }
      } else {
        _selectedOccurrenceDate = widget.weekMonday;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchQuery.trim().toLowerCase();
    final matchingMembers = widget.approvedMembers.where((m) {
      if (query.isEmpty) return true;
      final nameMatches = m.fullName.toLowerCase().contains(query);
      final spouseMatches =
          (m.spouseName ?? '').toLowerCase().contains(query);
      final familyMatches = m.familyNumber.toLowerCase().contains(query);
      return nameMatches || spouseMatches || familyMatches;
    }).toList();

    final isAlreadyAdded = _selectedMember != null &&
        widget.existingAnniversaries.any((a) => a.memberUid == _selectedMember!.uid);

    final calculatedYears =
        _selectedMember?.calculateAnniversaryYears(_selectedOccurrenceDate);

    return Dialog(
      backgroundColor: AppColors.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(AppStyles.space20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accentWine.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.favorite_rounded,
                        color: AppColors.accentWine, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Add Wedding Anniversary to Bulletin',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentWine,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 20),

              // Search Input
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search couple / member',
                  hintText: 'Enter family number or member name...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
              ),
              const SizedBox(height: 12),

              // Results List (Scrollable)
              Expanded(
                child: matchingMembers.isEmpty
                    ? Center(
                        child: Text(
                          'No approved members found matching "$_searchQuery"',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 13),
                        ),
                      )
                    : ListView.builder(
                        itemCount: matchingMembers.length,
                        itemBuilder: (context, index) {
                          final m = matchingMembers[index];
                          final isSelected = _selectedMember?.uid == m.uid;
                          final existsInWeek = widget.existingAnniversaries
                              .any((a) => a.memberUid == m.uid);

                          final annivStr = m.weddingAnniversary != null
                              ? DateFormat('d MMM').format(m.weddingAnniversary!)
                              : 'Not set';
                          final spouseStr = m.spouseName != null ? ' & ${m.spouseName}' : '';
                          final placeStr = m.place ?? m.familyInfo ?? '—';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.accentWine.withValues(alpha: 0.08)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.accentWine
                                    : AppColors.softBeige,
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: ListTile(
                              dense: true,
                              onTap: () => _onMemberSelected(m),
                              leading: MemberAvatar(
                                imageUrl: m.profileImageUrl,
                                radius: 18,
                                iconColor: AppColors.accentWine,
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${m.fullName}$spouseStr',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  if (existsInWeek)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.errorRed.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'Already added',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.errorRed,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Text(
                                'Family No: ${m.familyNumber} • Anniversary: $annivStr • Place: $placeStr',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              trailing: Icon(
                                isSelected
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                color: isSelected
                                    ? AppColors.accentWine
                                    : Colors.grey.shade400,
                                size: 20,
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // Selected Details & Editable Couple Display Name
              if (_selectedMember != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isAlreadyAdded
                        ? AppColors.errorRed.withValues(alpha: 0.06)
                        : AppColors.backgroundIvory,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isAlreadyAdded
                          ? AppColors.errorRed.withValues(alpha: 0.3)
                          : AppColors.softBeige,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isAlreadyAdded) ...[
                        Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                size: 16, color: AppColors.errorRed),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Anniversary for ${_selectedMember!.fullName} is already in this week\'s bulletin.',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.errorRed,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Couple Display Name (Editable as required by Part 2E)
                      TextField(
                        controller: _coupleNameController,
                        decoration: InputDecoration(
                          labelText: 'Couple Display Name (e.g. John & Mary)',
                          hintText: 'Enter couple names for bulletin card...',
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Calculated Anniversary: ${calculatedYears != null ? "$calculatedYears years" : "N/A"}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.accentWine,
                                  ),
                                ),
                                Text(
                                  'Place: ${_selectedMember!.place ?? _selectedMember!.familyInfo ?? "Parish"}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                _selectedOccurrenceDate != null
                                    ? DateFormat('EEE, d MMM').format(_selectedOccurrenceDate!)
                                    : 'Pick Date',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Select occurrence date in week',
                                icon: const Icon(Icons.calendar_today_rounded,
                                    size: 18, color: AppColors.accentWine),
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _selectedOccurrenceDate ?? widget.weekMonday,
                                    firstDate: widget.weekMonday,
                                    lastDate: widget.weekSunday,
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      _selectedOccurrenceDate = picked;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              const Divider(height: 24),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentWine,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _selectedMember == null || isAlreadyAdded
                        ? null
                        : () {
                            final m = _selectedMember!;
                            final eventDate =
                                _selectedOccurrenceDate ?? widget.weekMonday;
                            final weddingDate =
                                m.weddingAnniversary ?? DateTime(2015, 1, 1);
                            final coupleName =
                                _coupleNameController.text.trim().isNotEmpty
                                    ? _coupleNameController.text.trim()
                                    : '${m.fullName} & Spouse';

                            final entry = AnniversaryEntry(
                              id: 'anniv_${m.uid}_${eventDate.millisecondsSinceEpoch}',
                              memberUid: m.uid,
                              spouseUid: m.spouseUid,
                              coupleName: coupleName,
                              eventDate: eventDate,
                              weddingAnniversary: weddingDate,
                              place: m.place ?? m.familyInfo,
                              profileImageUrl: m.profileImageUrl,
                            );
                            Navigator.pop(context, entry);
                          },
                    child: const Text('Add Anniversary'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
