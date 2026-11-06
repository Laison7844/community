import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_styles.dart';
import '../../../../core/widgets/member_avatar.dart';
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
  String? _originalCreatedBy;
  String? _originalCreatedByName;
  DateTime? _originalCreatedAt;

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
          _originalCreatedBy = week.createdBy;
          _originalCreatedByName = week.createdByName;
          _originalCreatedAt = week.createdAt;
        } else {
          _isPublished = false;
          _birthdays = [];
          _anniversaries = [];
          _originalCreatedBy = null;
          _originalCreatedByName = null;
          _originalCreatedAt = null;
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
      createdBy: _originalCreatedBy ?? staffUid,
      createdByName: _originalCreatedByName ?? staffName,
      createdAt: _originalCreatedAt,
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

  void _openAddBirthdayDialog(List<MemberProfile> directoryMembers) async {
    final entry = await showDialog<BirthdayEntry>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AddBirthdayDialog(
        directoryMembers: directoryMembers,
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

  void _openAddAnniversaryDialog(List<MemberProfile> directoryMembers) async {
    final entry = await showDialog<AnniversaryEntry>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AddAnniversaryDialog(
        directoryMembers: directoryMembers,
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
    final directoryMembers = allMembersAsync.value ?? <MemberProfile>[];

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
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.subtleOlive.withValues(
                                  alpha: 0.15,
                                ),
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
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.cake_rounded, size: 18),
                        label: const Text('+ Add Birthday'),
                        onPressed: _isLoading || _errorMessage != null
                            ? null
                            : () => _openAddBirthdayDialog(directoryMembers),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentWine,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.favorite_rounded, size: 18),
                        label: const Text('+ Add Anniversary'),
                        onPressed: _isLoading || _errorMessage != null
                            ? null
                            : () => _openAddAnniversaryDialog(directoryMembers),
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
                              const Icon(
                                Icons.error_outline_rounded,
                                size: 48,
                                color: AppColors.errorRed,
                              ),
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
                    ? _buildCompletelyEmptyBulletinView(directoryMembers)
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left: Birthdays Column
                          Expanded(child: _buildBirthdaysListColumn()),
                          const VerticalDivider(width: 28),
                          // Right: Anniversaries Column
                          Expanded(child: _buildAnniversariesListColumn()),
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
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: AppStyles.space12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBrown,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
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
                        label: Text(
                          _isSaving
                              ? 'Saving Bulletin...'
                              : 'Save Weekly Bulletin',
                        ),
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

  Widget _buildCompletelyEmptyBulletinView(
    List<MemberProfile> directoryMembers,
  ) {
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
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppStyles.space20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(
                    Icons.cake_rounded,
                    color: AppColors.primaryBrown,
                  ),
                  label: const Text(
                    'Add Birthday',
                    style: TextStyle(color: AppColors.primaryBrown),
                  ),
                  onPressed: () => _openAddBirthdayDialog(directoryMembers),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  icon: const Icon(
                    Icons.favorite_rounded,
                    color: AppColors.accentWine,
                  ),
                  label: const Text(
                    'Add Anniversary',
                    style: TextStyle(color: AppColors.accentWine),
                  ),
                  onPressed: () => _openAddAnniversaryDialog(directoryMembers),
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
            const Icon(
              Icons.cake_rounded,
              size: 18,
              color: AppColors.primaryBrown,
            ),
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
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _birthdays.length,
                  itemBuilder: (context, i) {
                    final b = _birthdays[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: AppColors.cardSurface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: AppColors.softBeige),
                        ),
                        clipBehavior: Clip.antiAlias,
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
                            '${DateFormat('d MMM').format(b.eventDate)} • Age ${b.calculatedAge}${b.place != null && b.place!.isNotEmpty ? " • ${b.place}" : ""}${b.familyNumber != null && b.familyNumber!.isNotEmpty ? " • #${b.familyNumber}" : ""}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: IconButton(
                            tooltip: 'Remove',
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                              color: AppColors.errorRed,
                            ),
                            onPressed: () {
                              setState(() {
                                _birthdays.removeAt(i);
                              });
                            },
                          ),
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
            const Icon(
              Icons.favorite_rounded,
              size: 18,
              color: AppColors.accentWine,
            ),
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
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _anniversaries.length,
                  itemBuilder: (context, i) {
                    final a = _anniversaries[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: AppColors.cardSurface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: AppColors.softBeige),
                        ),
                        clipBehavior: Clip.antiAlias,
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
                            '${DateFormat('d MMM').format(a.eventDate)} • ${a.formattedAnniversaryOrdinal}${a.place != null && a.place!.isNotEmpty ? " • ${a.place}" : ""}${a.familyNumber != null && a.familyNumber!.isNotEmpty ? " • #${a.familyNumber}" : ""}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: IconButton(
                            tooltip: 'Remove',
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                              color: AppColors.errorRed,
                            ),
                            onPressed: () {
                              setState(() {
                                _anniversaries.removeAt(i);
                              });
                            },
                          ),
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
// DEDICATED ADD BIRTHDAY DIALOG
// ============================================================================

class _AddBirthdayDialog extends StatefulWidget {
  final List<MemberProfile> directoryMembers;
  final DateTime weekMonday;
  final DateTime weekSunday;
  final List<BirthdayEntry> existingBirthdays;

  const _AddBirthdayDialog({
    required this.directoryMembers,
    required this.weekMonday,
    required this.weekSunday,
    required this.existingBirthdays,
  });

  @override
  State<_AddBirthdayDialog> createState() => _AddBirthdayDialogState();
}

class _AddBirthdayDialogState extends State<_AddBirthdayDialog> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _familyNumberController = TextEditingController();
  final TextEditingController _placeController = TextEditingController();

  String _searchQuery = '';
  DateTime? _selectedDob;
  String? _selectedMemberUid;
  String? _profileImageUrl;

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _familyNumberController.dispose();
    _placeController.dispose();
    super.dispose();
  }

  /// Calculates birthday occurrence within current bulletin week
  DateTime? _calculateOccurrence(DateTime dob) {
    final candidate1 = DateTime(widget.weekMonday.year, dob.month, dob.day);
    if (!candidate1.isBefore(widget.weekMonday) &&
        !candidate1.isAfter(widget.weekSunday)) {
      return candidate1;
    }
    if (widget.weekSunday.year != widget.weekMonday.year) {
      final candidate2 = DateTime(widget.weekSunday.year, dob.month, dob.day);
      if (!candidate2.isBefore(widget.weekMonday) &&
          !candidate2.isAfter(widget.weekSunday)) {
        return candidate2;
      }
    }
    return null;
  }

  int? _calculateAge(DateTime dob, DateTime occurrence) {
    int age = occurrence.year - dob.year;
    return age >= 0 ? age : 0;
  }

  void _onMemberSelected(MemberProfile member) {
    setState(() {
      _nameController.text = member.fullName;
      _familyNumberController.text = member.familyNumber;
      _placeController.text = member.place ?? member.familyInfo ?? '';
      _selectedMemberUid = member.uid.isNotEmpty ? member.uid : null;
      _profileImageUrl = member.profileImageUrl;

      if (member.dateOfBirth != null) {
        _selectedDob = member.dateOfBirth;
      }

      _searchQuery = '';
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchQuery.trim().toLowerCase();
    final matchingMembers = query.isEmpty
        ? <MemberProfile>[]
        : widget.directoryMembers
              .where((m) {
                final nameMatches = m.fullName.toLowerCase().contains(query);
                final familyMatches = m.familyNumber.toLowerCase().contains(
                  query,
                );
                return nameMatches || familyMatches;
              })
              .take(6)
              .toList();

    final nameTrimmed = _nameController.text.trim();
    final occurrence = _selectedDob != null
        ? _calculateOccurrence(_selectedDob!)
        : null;
    final isBirthdayInCurrentWeek = _selectedDob != null && occurrence != null;

    final isAlreadyAdded =
        nameTrimmed.isNotEmpty &&
        widget.existingBirthdays.any((b) {
          final matchUid =
              _selectedMemberUid != null &&
              _selectedMemberUid!.isNotEmpty &&
              b.memberUid == _selectedMemberUid;
          final matchName =
              b.memberName.trim().toLowerCase() == nameTrimmed.toLowerCase();
          return matchUid || matchName;
        });

    final canSave =
        nameTrimmed.isNotEmpty &&
        _selectedDob != null &&
        isBirthdayInCurrentWeek &&
        !isAlreadyAdded;

    return Dialog(
      backgroundColor: AppColors.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(AppStyles.space20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add Birthday',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryBrown,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 16),

              // Form Body
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search church directory (optional, visually secondary)
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Search existing church person (optional)',
                          hintText: 'Search by name or family number',
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            size: 20,
                          ),
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

                      if (_searchQuery.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        if (matchingMembers.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 6),
                            child: Text(
                              'No matching church records found.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          )
                        else
                          ...matchingMembers.map((m) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              child: Material(
                                color: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: const BorderSide(
                                    color: AppColors.softBeige,
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: ListTile(
                                  dense: true,
                                  onTap: () => _onMemberSelected(m),
                                  leading: MemberAvatar(
                                    imageUrl: m.profileImageUrl,
                                    radius: 18,
                                  ),
                                  title: Text(
                                    m.fullName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Family No: ${m.familyNumber}${m.dateOfBirth != null ? " • ${DateFormat('d MMM yyyy').format(m.dateOfBirth!)}" : ""}${m.place != null && m.place!.isNotEmpty ? " • ${m.place}" : ""}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        const Divider(height: 16),
                      ] else
                        const SizedBox(height: 14),

                      // Person Name *
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Person Name *',
                          hintText: 'Enter name',
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),

                      // Family Number (optional)
                      TextFormField(
                        controller: _familyNumberController,
                        decoration: InputDecoration(
                          labelText: 'Family Number',
                          hintText: 'Enter family number (optional)',
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),

                      // Date of Birth *
                      InkWell(
                        onTap: () async {
                          final initial =
                              _selectedDob ??
                              DateTime(
                                1995,
                                DateTime.now().month,
                                DateTime.now().day,
                              );
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: initial,
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() {
                              _selectedDob = picked;
                            });
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Date of Birth *',
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            suffixIcon: const Icon(
                              Icons.calendar_month_rounded,
                              size: 20,
                              color: AppColors.primaryBrown,
                            ),
                          ),
                          child: Text(
                            _selectedDob != null
                                ? DateFormat(
                                    'd MMMM yyyy',
                                  ).format(_selectedDob!)
                                : 'Select date',
                            style: TextStyle(
                              color: _selectedDob != null
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              fontSize: 14,
                              fontWeight: _selectedDob != null
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Place (optional)
                      TextFormField(
                        controller: _placeController,
                        decoration: InputDecoration(
                          labelText: 'Place',
                          hintText: 'Enter place (optional)',
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 14),

                      // Bulletin summary box
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundIvory,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.softBeige),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Birthday in bulletin:',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              occurrence != null
                                  ? DateFormat('EEEE, d MMM').format(occurrence)
                                  : (_selectedDob != null
                                        ? 'Not in current week'
                                        : 'Select date of birth'),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: occurrence != null
                                    ? AppColors.primaryBrown
                                    : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Age:',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _selectedDob != null && occurrence != null
                                  ? '${_calculateAge(_selectedDob!, occurrence)} years'
                                  : 'Automatically calculated',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color:
                                    _selectedDob != null && occurrence != null
                                    ? AppColors.subtleOlive
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Validation Warnings
                      if (_selectedDob != null && !isBirthdayInCurrentWeek) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.errorRed.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.errorRed.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                size: 18,
                                color: AppColors.errorRed,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Birthday (${DateFormat('d MMMM').format(_selectedDob!)}) is outside the current bulletin week (${DateFormat('d MMM').format(widget.weekMonday)} – ${DateFormat('d MMM').format(widget.weekSunday)}).",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.errorRed,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      if (isAlreadyAdded) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.errorRed.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.errorRed.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                size: 18,
                                color: AppColors.errorRed,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${_nameController.text.trim()} is already added for this week.',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.errorRed,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const Divider(height: 20),

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
                    onPressed: canSave
                        ? () {
                            final entry = BirthdayEntry(
                              id: 'bday_${DateTime.now().millisecondsSinceEpoch}_${_nameController.text.hashCode.abs()}',
                              memberUid: _selectedMemberUid,
                              memberName: _nameController.text.trim(),
                              familyNumber:
                                  _familyNumberController.text.trim().isNotEmpty
                                  ? _familyNumberController.text.trim()
                                  : null,
                              eventDate: occurrence,
                              dateOfBirth: _selectedDob!,
                              place: _placeController.text.trim().isNotEmpty
                                  ? _placeController.text.trim()
                                  : null,
                              profileImageUrl: _profileImageUrl,
                            );
                            Navigator.pop(context, entry);
                          }
                        : null,
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
// DEDICATED ADD ANNIVERSARY DIALOG
// ============================================================================

class _AddAnniversaryDialog extends StatefulWidget {
  final List<MemberProfile> directoryMembers;
  final DateTime weekMonday;
  final DateTime weekSunday;
  final List<AnniversaryEntry> existingAnniversaries;

  const _AddAnniversaryDialog({
    required this.directoryMembers,
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
  final TextEditingController _brideNameController = TextEditingController();
  final TextEditingController _groomNameController = TextEditingController();
  final TextEditingController _familyNumberController = TextEditingController();
  final TextEditingController _placeController = TextEditingController();

  String _searchQuery = '';
  DateTime? _selectedWeddingDate;
  String? _selectedMemberUid;
  String? _selectedSpouseUid;
  String? _profileImageUrl;

  @override
  void dispose() {
    _searchController.dispose();
    _coupleNameController.dispose();
    _brideNameController.dispose();
    _groomNameController.dispose();
    _familyNumberController.dispose();
    _placeController.dispose();
    super.dispose();
  }

  /// Calculates anniversary occurrence within current bulletin week
  DateTime? _calculateOccurrence(DateTime weddingDate) {
    final candidate1 = DateTime(
      widget.weekMonday.year,
      weddingDate.month,
      weddingDate.day,
    );
    if (!candidate1.isBefore(widget.weekMonday) &&
        !candidate1.isAfter(widget.weekSunday)) {
      return candidate1;
    }
    if (widget.weekSunday.year != widget.weekMonday.year) {
      final candidate2 = DateTime(
        widget.weekSunday.year,
        weddingDate.month,
        weddingDate.day,
      );
      if (!candidate2.isBefore(widget.weekMonday) &&
          !candidate2.isAfter(widget.weekSunday)) {
        return candidate2;
      }
    }
    return null;
  }

  int? _calculateYears(DateTime weddingDate, DateTime occurrence) {
    int years = occurrence.year - weddingDate.year;
    return years >= 0 ? years : 0;
  }

  String _formatAnniversaryOrdinal(int count) {
    if (count <= 0) return 'Wedding Anniversary';
    final remainder10 = count % 10;
    final remainder100 = count % 100;
    String suffix = 'th';
    if (remainder100 < 11 || remainder100 > 13) {
      if (remainder10 == 1) suffix = 'st';
      if (remainder10 == 2) suffix = 'nd';
      if (remainder10 == 3) suffix = 'rd';
    }
    return '$count$suffix Anniversary ($count years)';
  }

  void _onMemberSelected(MemberProfile member) {
    setState(() {
      final spouse = member.spouseName ?? '';
      if (spouse.isNotEmpty) {
        _coupleNameController.text = '${member.fullName} & $spouse';
        _brideNameController.text = spouse;
        _groomNameController.text = member.fullName;
      } else {
        _coupleNameController.text = '${member.fullName} & Spouse';
        _groomNameController.text = member.fullName;
      }
      _familyNumberController.text = member.familyNumber;
      _placeController.text = member.place ?? member.familyInfo ?? '';
      _selectedMemberUid = member.uid.isNotEmpty ? member.uid : null;
      _selectedSpouseUid = member.spouseUid;
      _profileImageUrl = member.profileImageUrl;

      if (member.weddingAnniversary != null) {
        _selectedWeddingDate = member.weddingAnniversary;
      }

      _searchQuery = '';
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchQuery.trim().toLowerCase();
    final matchingMembers = query.isEmpty
        ? <MemberProfile>[]
        : widget.directoryMembers
              .where((m) {
                final nameMatches = m.fullName.toLowerCase().contains(query);
                final spouseMatches = (m.spouseName ?? '')
                    .toLowerCase()
                    .contains(query);
                final familyMatches = m.familyNumber.toLowerCase().contains(
                  query,
                );
                return nameMatches || spouseMatches || familyMatches;
              })
              .take(6)
              .toList();

    final coupleTrimmed = _coupleNameController.text.trim();
    final occurrence = _selectedWeddingDate != null
        ? _calculateOccurrence(_selectedWeddingDate!)
        : null;
    final isAnniversaryInCurrentWeek =
        _selectedWeddingDate != null && occurrence != null;

    final isAlreadyAdded =
        coupleTrimmed.isNotEmpty &&
        widget.existingAnniversaries.any((a) {
          final matchUid =
              _selectedMemberUid != null &&
              _selectedMemberUid!.isNotEmpty &&
              a.memberUid == _selectedMemberUid;
          final matchCouple =
              a.coupleName.trim().toLowerCase() == coupleTrimmed.toLowerCase();
          return matchUid || matchCouple;
        });

    final canSave =
        coupleTrimmed.isNotEmpty &&
        _selectedWeddingDate != null &&
        isAnniversaryInCurrentWeek &&
        !isAlreadyAdded;

    return Dialog(
      backgroundColor: AppColors.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(AppStyles.space20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add Anniversary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentWine,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 16),

              // Form Body
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search church directory (optional, visually secondary)
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Search existing church couple (optional)',
                          hintText: 'Search by spouse names or family number',
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            size: 20,
                          ),
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

                      if (_searchQuery.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        if (matchingMembers.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 6),
                            child: Text(
                              'No matching church records found.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          )
                        else
                          ...matchingMembers.map((m) {
                            final spouseStr =
                                m.spouseName != null && m.spouseName!.isNotEmpty
                                ? ' & ${m.spouseName}'
                                : '';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              child: Material(
                                color: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: const BorderSide(
                                    color: AppColors.softBeige,
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: ListTile(
                                  dense: true,
                                  onTap: () => _onMemberSelected(m),
                                  leading: MemberAvatar(
                                    imageUrl: m.profileImageUrl,
                                    radius: 18,
                                    iconColor: AppColors.accentWine,
                                  ),
                                  title: Text(
                                    '${m.fullName}$spouseStr',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Family No: ${m.familyNumber}${m.weddingAnniversary != null ? " • ${DateFormat('d MMM yyyy').format(m.weddingAnniversary!)}" : ""}${m.place != null && m.place!.isNotEmpty ? " • ${m.place}" : ""}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        const Divider(height: 16),
                      ] else
                        const SizedBox(height: 14),

                      // Couple Display Name *
                      TextFormField(
                        controller: _coupleNameController,
                        decoration: InputDecoration(
                          labelText: 'Couple Display Name *',
                          hintText: 'e.g. John & Mary',
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),

                      // Wedding Date *
                      InkWell(
                        onTap: () async {
                          final initial =
                              _selectedWeddingDate ?? DateTime(2000, 1, 1);
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: initial,
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() {
                              _selectedWeddingDate = picked;
                            });
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Wedding Date *',
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            suffixIcon: const Icon(
                              Icons.calendar_month_rounded,
                              size: 20,
                              color: AppColors.accentWine,
                            ),
                          ),
                          child: Text(
                            _selectedWeddingDate != null
                                ? DateFormat(
                                    'd MMMM yyyy',
                                  ).format(_selectedWeddingDate!)
                                : 'Select date',
                            style: TextStyle(
                              color: _selectedWeddingDate != null
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              fontSize: 14,
                              fontWeight: _selectedWeddingDate != null
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Family Number (optional)
                      TextFormField(
                        controller: _familyNumberController,
                        decoration: InputDecoration(
                          labelText: 'Family Number',
                          hintText: 'Enter family number (optional)',
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),

                      // Place (optional)
                      TextFormField(
                        controller: _placeController,
                        decoration: InputDecoration(
                          labelText: 'Place',
                          hintText: 'Enter place (optional)',
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),

                      // Spouse Names (optional)
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _brideNameController,
                              decoration: InputDecoration(
                                labelText: 'Bride Name',
                                hintText: 'optional',
                                isDense: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _groomNameController,
                              decoration: InputDecoration(
                                labelText: 'Groom Name',
                                hintText: 'optional',
                                isDense: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Bulletin summary box
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundIvory,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.softBeige),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Anniversary in bulletin:',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              occurrence != null
                                  ? DateFormat('EEEE, d MMM').format(occurrence)
                                  : (_selectedWeddingDate != null
                                        ? 'Not in current week'
                                        : 'Select wedding date'),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: occurrence != null
                                    ? AppColors.accentWine
                                    : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Anniversary:',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _selectedWeddingDate != null && occurrence != null
                                  ? _formatAnniversaryOrdinal(
                                      _calculateYears(
                                        _selectedWeddingDate!,
                                        occurrence,
                                      )!,
                                    )
                                  : 'Automatically calculated',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color:
                                    _selectedWeddingDate != null &&
                                        occurrence != null
                                    ? AppColors.subtleOlive
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Validation Warnings
                      if (_selectedWeddingDate != null &&
                          !isAnniversaryInCurrentWeek) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.errorRed.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.errorRed.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                size: 18,
                                color: AppColors.errorRed,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Anniversary (${DateFormat('d MMMM').format(_selectedWeddingDate!)}) is outside the current bulletin week (${DateFormat('d MMM').format(widget.weekMonday)} – ${DateFormat('d MMM').format(widget.weekSunday)}).",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.errorRed,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      if (isAlreadyAdded) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.errorRed.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.errorRed.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                size: 18,
                                color: AppColors.errorRed,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Anniversary for ${_coupleNameController.text.trim()} is already added for this week.',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.errorRed,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const Divider(height: 20),

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
                    onPressed: canSave
                        ? () {
                            final entry = AnniversaryEntry(
                              id: 'anniv_${DateTime.now().millisecondsSinceEpoch}_${_coupleNameController.text.hashCode.abs()}',
                              memberUid: _selectedMemberUid,
                              spouseUid: _selectedSpouseUid,
                              coupleName: _coupleNameController.text.trim(),
                              brideName:
                                  _brideNameController.text.trim().isNotEmpty
                                  ? _brideNameController.text.trim()
                                  : null,
                              groomName:
                                  _groomNameController.text.trim().isNotEmpty
                                  ? _groomNameController.text.trim()
                                  : null,
                              familyNumber:
                                  _familyNumberController.text.trim().isNotEmpty
                                  ? _familyNumberController.text.trim()
                                  : null,
                              eventDate: occurrence,
                              weddingAnniversary: _selectedWeddingDate!,
                              place: _placeController.text.trim().isNotEmpty
                                  ? _placeController.text.trim()
                                  : null,
                              profileImageUrl: _profileImageUrl,
                            );
                            Navigator.pop(context, entry);
                          }
                        : null,
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
