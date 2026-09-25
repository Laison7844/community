import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../models/announcement.dart';
import '../../providers/announcement_provider.dart';

/// Modal dialog for authorized committee/staff to create or edit an announcement.
/// Tailored for Marriage, General, and Special announcement workflows.
class AnnouncementFormDialog extends ConsumerStatefulWidget {
  final Announcement? initialAnnouncement;
  final AnnouncementType initialType;

  const AnnouncementFormDialog({
    super.key,
    this.initialAnnouncement,
    this.initialType = AnnouncementType.general,
  });

  @override
  ConsumerState<AnnouncementFormDialog> createState() =>
      _AnnouncementFormDialogState();
}

class _AnnouncementFormDialogState
    extends ConsumerState<AnnouncementFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late AnnouncementType _type;
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _reasonController;

  // Marriage fields
  late final TextEditingController _brideNameController;
  late final TextEditingController _brideDetailsController;
  late final TextEditingController _groomNameController;
  late final TextEditingController _groomDetailsController;
  AnnouncementStage _marriageStage = AnnouncementStage.first;
  DateTime? _marriageDate;

  // General & Special fields
  DateTime? _scheduledDate;
  TimeOfDay? _scheduledTime;

  late bool _isPublished;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  String? _existingImageUrl;
  bool _isProcessing = false;

  bool get isEdit => widget.initialAnnouncement != null;

  @override
  void initState() {
    super.initState();
    final a = widget.initialAnnouncement;
    _type = a?.announcementType ?? widget.initialType;

    _titleController = TextEditingController(text: a?.title ?? '');
    _descriptionController = TextEditingController(text: a?.description ?? '');
    _reasonController = TextEditingController();

    _brideNameController = TextEditingController(text: a?.brideName ?? '');
    _brideDetailsController = TextEditingController(text: a?.brideDetails ?? '');
    _groomNameController = TextEditingController(text: a?.groomName ?? '');
    _groomDetailsController = TextEditingController(text: a?.groomDetails ?? '');
    _marriageStage = a?.announcementStage ?? AnnouncementStage.first;
    _marriageDate = a?.marriageDate;

    _scheduledDate = a?.scheduledDate;
    if (a?.scheduledTime != null && a!.scheduledTime!.isNotEmpty) {
      try {
        final df = DateFormat('h:mm a');
        final dt = df.parse(a.scheduledTime!);
        _scheduledTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
      } catch (_) {}
    }

    _isPublished = a?.isPublished ?? true;
    _existingImageUrl = a?.imageUrl;

    // Listen to bride/groom/stage changes to auto-update marriage title
    if (_type == AnnouncementType.marriage) {
      _brideNameController.addListener(_updateMarriageTitle);
      _groomNameController.addListener(_updateMarriageTitle);
      _updateMarriageTitle();
    }
  }

  void _updateMarriageTitle() {
    final bride = _brideNameController.text.trim();
    final groom = _groomNameController.text.trim();
    final couple = bride.isNotEmpty && groom.isNotEmpty
        ? '$bride & $groom'
        : (bride.isNotEmpty ? bride : (groom.isNotEmpty ? groom : 'Parish Couple'));

    final newTitle = 'Marriage Announcement: $couple (${_marriageStage.displayName})';
    if (_titleController.text != newTitle) {
      setState(() {
        _titleController.text = newTitle;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _reasonController.dispose();
    _brideNameController.dispose();
    _brideDetailsController.dispose();
    _groomNameController.dispose();
    _groomDetailsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 800,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      final validationError = Validators.validateImageFile(
        sizeInBytes: bytes.length,
        fileName: pickedFile.name,
      );
      if (validationError != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(validationError),
            backgroundColor: AppColors.errorRed,
          ),
        );
        return;
      }

      setState(() {
        _selectedImageBytes = bytes;
        _selectedImageName = pickedFile.name;
        _existingImageUrl = null;
      });
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImageBytes = null;
      _selectedImageName = null;
      _existingImageUrl = null;
    });
  }

  Future<void> _pickMarriageDate() async {
    final now = DateTime.now();
    final initial = _marriageDate ?? now.add(const Duration(days: 7));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (picked != null) {
      setState(() {
        _marriageDate = picked;
      });
    }
  }

  Future<void> _pickScheduledDate() async {
    final now = DateTime.now();
    final initial = _scheduledDate ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _scheduledDate = picked;
      });
    }
  }

  Future<void> _pickScheduledTime() async {
    final initial = _scheduledTime ?? const TimeOfDay(hour: 9, minute: 30);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      setState(() {
        _scheduledTime = picked;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_type == AnnouncementType.marriage && _marriageDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select the marriage date.'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    final auth = ref.read(authProvider);
    final staffUid = auth.uid ?? '';
    final staffName = auth.fullName ?? 'Staff Member';
    final staffRole = auth.profile?.role ?? 'committee';

    setState(() {
      _isProcessing = true;
    });

    final repo = ref.read(announcementRepositoryProvider);
    final storageRepo = ref.read(storageRepositoryProvider);

    try {
      final announcementId = widget.initialAnnouncement?.id ??
          repo.generateAnnouncementId();

      String? finalImageUrl = _existingImageUrl;
      if (_selectedImageBytes != null && _selectedImageName != null) {
        finalImageUrl = await storageRepo.uploadAnnouncementImage(
          announcementId: announcementId,
          bytes: _selectedImageBytes!,
          fileName: _selectedImageName!,
        );
      }

      final reason = _reasonController.text.trim();
      final scheduledTimeStr = _scheduledTime != null && mounted
          ? _scheduledTime!.format(context)
          : null;

      if (isEdit) {
        final existing = widget.initialAnnouncement!;
        if (existing.imageUrl != null && finalImageUrl == null) {
          await storageRepo.deleteAnnouncementImage(announcementId);
        }

        final updated = existing.copyWith(
          announcementType: _type,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          imageUrl: finalImageUrl,
          isPublished: _isPublished,
          createdByName: staffName,
          brideName: _type == AnnouncementType.marriage ? _brideNameController.text.trim() : null,
          brideDetails: _type == AnnouncementType.marriage ? _brideDetailsController.text.trim() : null,
          groomName: _type == AnnouncementType.marriage ? _groomNameController.text.trim() : null,
          groomDetails: _type == AnnouncementType.marriage ? _groomDetailsController.text.trim() : null,
          announcementStage: _type == AnnouncementType.marriage ? _marriageStage : null,
          marriageDate: _type == AnnouncementType.marriage ? _marriageDate : null,
          scheduledDate: _type != AnnouncementType.marriage ? _scheduledDate : null,
          scheduledTime: _type != AnnouncementType.marriage ? scheduledTimeStr : null,
        );

        await repo.updateAnnouncement(
          announcement: updated,
          performedByUid: staffUid,
          performedByRole: staffRole,
          reason: reason.isNotEmpty ? reason : 'Updated announcement details',
        );
      } else {
        final newAnnouncement = Announcement(
          id: announcementId,
          announcementType: _type,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          imageUrl: finalImageUrl,
          isPublished: _isPublished,
          churchId: 'csi_main',
          createdBy: staffUid,
          createdByName: staffName,
          brideName: _type == AnnouncementType.marriage ? _brideNameController.text.trim() : null,
          brideDetails: _type == AnnouncementType.marriage ? _brideDetailsController.text.trim() : null,
          groomName: _type == AnnouncementType.marriage ? _groomNameController.text.trim() : null,
          groomDetails: _type == AnnouncementType.marriage ? _groomDetailsController.text.trim() : null,
          announcementStage: _type == AnnouncementType.marriage ? _marriageStage : null,
          marriageDate: _type == AnnouncementType.marriage ? _marriageDate : null,
          scheduledDate: _type != AnnouncementType.marriage ? _scheduledDate : null,
          scheduledTime: _type != AnnouncementType.marriage ? scheduledTimeStr : null,
        );

        await repo.createAnnouncement(
          announcement: newAnnouncement,
          performedByUid: staffUid,
          performedByRole: staffRole,
          reason: reason.isNotEmpty ? reason : 'Created new announcement',
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEdit
                ? 'Announcement updated successfully.'
                : '${_type.displayName} created successfully.',
          ),
          backgroundColor: AppColors.subtleOlive,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Operation failed: $e'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String dialogTitle;
    Color headerColor;
    IconData headerIcon;

    switch (_type) {
      case AnnouncementType.marriage:
        dialogTitle = isEdit ? 'Edit Marriage Announcement' : 'New Marriage Announcement';
        headerColor = AppColors.accentWine;
        headerIcon = Icons.favorite_rounded;
        break;
      case AnnouncementType.special:
        dialogTitle = isEdit ? 'Edit Special Announcement' : 'New Special Announcement';
        headerColor = AppColors.mutedGoldDark;
        headerIcon = Icons.star_rounded;
        break;
      case AnnouncementType.general:
        dialogTitle = isEdit ? 'Edit General Announcement' : 'New General Announcement';
        headerColor = AppColors.primaryBrown;
        headerIcon = Icons.campaign_rounded;
        break;
    }

    return Dialog(
      backgroundColor: AppColors.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(AppStyles.space20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: headerColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(headerIcon, color: headerColor, size: 20),
                    ),
                    const SizedBox(width: AppStyles.space12),
                    Expanded(
                      child: Text(
                        dialogTitle,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: headerColor,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Scrollable Form Body
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_type == AnnouncementType.marriage)
                          _buildMarriageFields()
                        else
                          _buildGeneralSpecialFields(),

                        const SizedBox(height: AppStyles.space16),

                        // Image attachment section
                        _buildImageSection(),
                        const SizedBox(height: AppStyles.space16),

                        // Publication Status Toggle
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCream,
                            borderRadius: AppStyles.roundedMedium,
                            border: Border.all(color: AppColors.softBeige),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _isPublished
                                    ? Icons.public_rounded
                                    : Icons.lock_outline_rounded,
                                color: _isPublished
                                    ? AppColors.subtleOlive
                                    : AppColors.textSecondary,
                                size: 20,
                              ),
                              const SizedBox(width: AppStyles.space12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _isPublished
                                          ? 'Published Notice'
                                          : 'Save as Unpublished Draft',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      _isPublished
                                          ? 'Immediately visible to approved church members.'
                                          : 'Visible to parish committee/staff only.',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _isPublished,
                                activeThumbColor: Colors.white,
                                activeTrackColor: AppColors.primaryBrown,
                                onChanged: (val) {
                                  setState(() {
                                    _isPublished = val;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),

                        if (isEdit) ...[
                          const SizedBox(height: AppStyles.space16),
                          TextFormField(
                            controller: _reasonController,
                            decoration: const InputDecoration(
                              labelText: 'Audit Reason for Update (Optional)',
                              hintText: 'e.g., Corrected date or updated details',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppStyles.space16),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isProcessing ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: AppStyles.space12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: headerColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppStyles.roundedMedium,
                        ),
                      ),
                      onPressed: _isProcessing ? null : _handleSubmit,
                      child: _isProcessing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(isEdit ? 'Save Changes' : 'Publish Announcement'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Fields for Marriage Announcements
  Widget _buildMarriageFields() {
    final marriageDateStr = _marriageDate != null
        ? DateFormat('dd MMMM yyyy').format(_marriageDate!)
        : 'Select Marriage Date';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Auto-generated Title Preview
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.accentWine.withValues(alpha: 0.08),
            borderRadius: AppStyles.roundedMedium,
            border: Border.all(color: AppColors.accentWine.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, size: 14, color: AppColors.accentWine),
                  SizedBox(width: 6),
                  Text(
                    'Announcement Title (Auto-generated)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentWine,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _titleController.text.isNotEmpty
                    ? _titleController.text
                    : 'Marriage Announcement: [Bride] & [Groom] (${_marriageStage.displayName})',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryBrown,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppStyles.space16),

        // Announcement Stage Selector
        DropdownButtonFormField<AnnouncementStage>(
          initialValue: _marriageStage,
          decoration: const InputDecoration(
            labelText: 'Announcement Stage *',
            prefixIcon: Icon(Icons.format_list_numbered_rounded),
          ),
          items: AnnouncementStage.values.map((s) {
            return DropdownMenuItem(
              value: s,
              child: Text(s.displayName),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _marriageStage = val;
                _updateMarriageTitle();
              });
            }
          },
        ),
        const SizedBox(height: AppStyles.space16),

        // Bride Section
        TextFormField(
          controller: _brideNameController,
          decoration: const InputDecoration(
            labelText: 'Bride Name *',
            hintText: 'Enter full name of the bride',
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
          validator: (val) {
            if (val == null || val.trim().isEmpty) return 'Bride name is required';
            if (val.trim().length < 2) return 'Enter at least 2 characters';
            return null;
          },
        ),
        const SizedBox(height: AppStyles.space12),
        TextFormField(
          controller: _brideDetailsController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Bride Details',
            hintText: 'e.g., D/o Mr. & Mrs. Thomas, CSI Parish Member',
            prefixIcon: Icon(Icons.badge_outlined),
          ),
        ),
        const SizedBox(height: AppStyles.space16),

        // Groom Section
        TextFormField(
          controller: _groomNameController,
          decoration: const InputDecoration(
            labelText: 'Groom Name *',
            hintText: 'Enter full name of the groom',
            prefixIcon: Icon(Icons.person_rounded),
          ),
          validator: (val) {
            if (val == null || val.trim().isEmpty) return 'Groom name is required';
            if (val.trim().length < 2) return 'Enter at least 2 characters';
            return null;
          },
        ),
        const SizedBox(height: AppStyles.space12),
        TextFormField(
          controller: _groomDetailsController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Groom Details',
            hintText: 'e.g., S/o Mr. & Mrs. Joseph, St. Peter Church',
            prefixIcon: Icon(Icons.badge_outlined),
          ),
        ),
        const SizedBox(height: AppStyles.space16),

        // Marriage Date Selector
        InkWell(
          onTap: _pickMarriageDate,
          borderRadius: AppStyles.roundedMedium,
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Marriage Date *',
              hintText: 'Select marriage ceremony date',
              prefixIcon: Icon(Icons.calendar_month_rounded),
              suffixIcon: Icon(Icons.calendar_today_rounded, size: 18),
            ),
            child: Text(
              marriageDateStr,
              style: TextStyle(
                fontSize: 14,
                color: _marriageDate != null
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontWeight: _marriageDate != null
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Note: This notice will automatically disappear 1 day before the marriage date.',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.accentWine.withValues(alpha: 0.8),
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  /// Fields for General and Special Announcements
  Widget _buildGeneralSpecialFields() {
    final scheduledDateStr = _scheduledDate != null
        ? DateFormat('EEEE, MMM d, y').format(_scheduledDate!)
        : 'Select Scheduled Date';

    final scheduledTimeStr = _scheduledTime != null
        ? _scheduledTime!.format(context)
        : 'Select Time';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Announcement Title
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            labelText: _type == AnnouncementType.special
                ? 'Celebration / Event Name *'
                : 'Announcement Title *',
            hintText: _type == AnnouncementType.special
                ? 'e.g., Easter Sunday Resurrection Service & Feast'
                : 'e.g., Sunday School Annual Reopening',
            prefixIcon: Icon(
              _type == AnnouncementType.special
                  ? Icons.celebration_rounded
                  : Icons.campaign_rounded,
            ),
          ),
          validator: (val) {
            if (val == null || val.trim().isEmpty) return 'Title is required';
            if (val.trim().length < 3) return 'Enter at least 3 characters';
            return null;
          },
        ),
        const SizedBox(height: AppStyles.space16),

        // Description
        TextFormField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Description *',
            hintText: 'Provide complete details and church instructions...',
            alignLabelWithHint: true,
          ),
          validator: (val) {
            if (val == null || val.trim().isEmpty) return 'Description is required';
            if (val.trim().length < 5) return 'Enter at least 5 characters';
            return null;
          },
        ),
        const SizedBox(height: AppStyles.space16),

        // Scheduled Date & Time Row
        Row(
          children: [
            // Date Picker
            Expanded(
              child: InkWell(
                onTap: _pickScheduledDate,
                borderRadius: AppStyles.roundedMedium,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date (Optional)',
                    prefixIcon: Icon(Icons.event_rounded, size: 20),
                  ),
                  child: Text(
                    scheduledDateStr,
                    style: TextStyle(
                      fontSize: 12,
                      color: _scheduledDate != null
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppStyles.space12),

            // Time Picker
            Expanded(
              child: InkWell(
                onTap: _pickScheduledTime,
                borderRadius: AppStyles.roundedMedium,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Time (Optional)',
                    prefixIcon: Icon(Icons.schedule_rounded, size: 20),
                  ),
                  child: Text(
                    scheduledTimeStr,
                    style: TextStyle(
                      fontSize: 12,
                      color: _scheduledTime != null
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Notice will remain visible until the scheduled date/time has passed.',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Attached Image / Photo (Optional)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryBrown,
          ),
        ),
        const SizedBox(height: AppStyles.space8),
        if (_selectedImageBytes != null || _existingImageUrl != null)
          Stack(
            children: [
              ClipRRect(
                borderRadius: AppStyles.roundedMedium,
                child: _selectedImageBytes != null
                    ? Image.memory(
                        _selectedImageBytes!,
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Image.network(
                        _existingImageUrl!,
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.close_rounded, size: 18, color: Colors.white),
                    onPressed: _removeImage,
                  ),
                ),
              ),
            ],
          )
        else
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              side: const BorderSide(color: AppColors.softBeige),
              shape: RoundedRectangleBorder(
                borderRadius: AppStyles.roundedMedium,
              ),
            ),
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: const Text('Attach Banner / Photo'),
            onPressed: _pickImage,
          ),
      ],
    );
  }
}
