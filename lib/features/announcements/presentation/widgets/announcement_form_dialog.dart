import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_styles.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../models/announcement.dart';
import '../../providers/announcement_provider.dart';

/// Modal dialog for authorized committee/staff to create or edit an announcement.
class AnnouncementFormDialog extends ConsumerStatefulWidget {
  final Announcement? initialAnnouncement;

  const AnnouncementFormDialog({
    super.key,
    this.initialAnnouncement,
  });

  @override
  ConsumerState<AnnouncementFormDialog> createState() =>
      _AnnouncementFormDialogState();
}

class _AnnouncementFormDialogState
    extends ConsumerState<AnnouncementFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _reasonController;
  late AnnouncementPriority _priority;
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
    _titleController = TextEditingController(text: a?.title ?? '');
    _descriptionController = TextEditingController(text: a?.description ?? '');
    _reasonController = TextEditingController();
    _priority = a?.priority ?? AnnouncementPriority.normal;
    _isPublished = a?.isPublished ?? true;
    _existingImageUrl = a?.imageUrl;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Banner image must be under 5 MB.'),
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

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = ref.read(authProvider);
    final staffUid = auth.uid ?? '';
    final staffRole = auth.profile?.role ?? 'committee';
    final staffName = auth.fullName ?? 'Parish Staff';

    setState(() {
      _isProcessing = true;
    });

    try {
      final repo = ref.read(announcementRepositoryProvider);
      final storageRepo = ref.read(storageRepositoryProvider);

      final announcementId = widget.initialAnnouncement?.id ??
          repo.generateAnnouncementId();

      // 1. Handle Banner Image Upload if new image was picked
      String? finalImageUrl = _existingImageUrl;
      if (_selectedImageBytes != null && _selectedImageName != null) {
        finalImageUrl = await storageRepo.uploadAnnouncementImage(
          announcementId: announcementId,
          bytes: _selectedImageBytes!,
          fileName: _selectedImageName!,
        );
      }

      final reason = _reasonController.text.trim();

      if (isEdit) {
        // Edit existing announcement
        final updated = widget.initialAnnouncement!.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          imageUrl: finalImageUrl,
          priority: _priority,
          isPublished: _isPublished,
          createdByName: staffName,
        );

        await repo.updateAnnouncement(
          announcement: updated,
          performedByUid: staffUid,
          performedByRole: staffRole,
          reason: reason.isNotEmpty ? reason : 'Updated announcement details',
        );
      } else {
        // Create new announcement
        final newAnnouncement = Announcement(
          id: announcementId,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          imageUrl: finalImageUrl,
          priority: _priority,
          isPublished: _isPublished,
          churchId: 'csi_main',
          createdBy: staffUid,
          createdByName: staffName,
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
                : 'Announcement created successfully.',
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
          content: Text(e.toString()),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: AppStyles.roundedXLarge,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 780),
        child: Padding(
          padding: const EdgeInsets.all(AppStyles.space24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dialog Header
                Row(
                  children: [
                    Icon(
                      isEdit ? Icons.edit_note_rounded : Icons.campaign_rounded,
                      color: AppColors.primaryBrown,
                      size: 26,
                    ),
                    const SizedBox(width: AppStyles.space12),
                    Expanded(
                      child: Text(
                        isEdit ? 'Edit Announcement' : 'Post Parish Announcement',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryBrown,
                            ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(height: AppStyles.space20),

                // Form Fields Body
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        TextFormField(
                          controller: _titleController,
                          validator: (val) {
                            if (val == null || val.trim().length < 3) {
                              return 'Title must be at least 3 characters.';
                            }
                            if (val.trim().length > 150) {
                              return 'Title cannot exceed 150 characters.';
                            }
                            return null;
                          },
                          decoration: const InputDecoration(
                            labelText: 'Announcement Title *',
                            hintText: 'e.g. Special Communion Service This Sunday',
                            filled: true,
                            fillColor: AppColors.surfaceCream,
                            border: OutlineInputBorder(
                              borderRadius: AppStyles.roundedMedium,
                              borderSide: BorderSide(color: AppColors.softBeige),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppStyles.space16),

                        // Priority Dropdown
                        DropdownButtonFormField<AnnouncementPriority>(
                          initialValue: _priority,
                          decoration: const InputDecoration(
                            labelText: 'Priority Level',
                            filled: true,
                            fillColor: AppColors.surfaceCream,
                            border: OutlineInputBorder(
                              borderRadius: AppStyles.roundedMedium,
                              borderSide: BorderSide(color: AppColors.softBeige),
                            ),
                          ),
                          items: AnnouncementPriority.values.map((p) {
                            return DropdownMenuItem(
                              value: p,
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 5,
                                    backgroundColor: p == AnnouncementPriority.urgent
                                        ? AppColors.errorRed
                                        : (p == AnnouncementPriority.high
                                            ? AppColors.warningAmber
                                            : AppColors.primaryBrown),
                                  ),
                                  const SizedBox(width: AppStyles.space8),
                                  Text(p.displayName),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _priority = val;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: AppStyles.space16),

                        // Description Body
                        TextFormField(
                          controller: _descriptionController,
                          validator: (val) {
                            if (val == null || val.trim().length < 5) {
                              return 'Please provide announcement details (min 5 characters).';
                            }
                            return null;
                          },
                          maxLines: 5,
                          decoration: const InputDecoration(
                            labelText: 'Announcement Details / Body *',
                            hintText: 'Write the complete parish notice...',
                            filled: true,
                            fillColor: AppColors.surfaceCream,
                            border: OutlineInputBorder(
                              borderRadius: AppStyles.roundedMedium,
                              borderSide: BorderSide(color: AppColors.softBeige),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppStyles.space16),

                        // Banner Image Selector
                        const Text(
                          'Optional Banner Flyer / Image',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryBrown,
                          ),
                        ),
                        const SizedBox(height: AppStyles.space8),
                        if (_selectedImageBytes != null ||
                            (_existingImageUrl != null &&
                                _existingImageUrl!.isNotEmpty)) ...[
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: AppStyles.roundedMedium,
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 150,
                                  child: _selectedImageBytes != null
                                      ? Image.memory(
                                          _selectedImageBytes!,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.network(
                                          _existingImageUrl!,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: CircleAvatar(
                                  backgroundColor: Colors.black54,
                                  radius: 16,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    onPressed: _removeImage,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primaryBrown,
                              side: const BorderSide(color: AppColors.softBeige),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            icon: const Icon(Icons.add_photo_alternate_outlined),
                            label: const Text('Attach Flyer / Image (Max 5MB)'),
                            onPressed: _pickImage,
                          ),
                        ],
                        const SizedBox(height: AppStyles.space16),

                        // Publish Switch
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Publish Immediately',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            _isPublished
                                ? 'Visible to approved church members immediately.'
                                : 'Saved as draft. Only visible to staff.',
                            style: const TextStyle(fontSize: 12),
                          ),
                          value: _isPublished,
                          activeThumbColor: AppColors.subtleOlive,
                          onChanged: (val) {
                            setState(() {
                              _isPublished = val;
                            });
                          },
                        ),
                        const SizedBox(height: AppStyles.space12),

                        // Reason / Audit Notes
                        TextFormField(
                          controller: _reasonController,
                          decoration: const InputDecoration(
                            labelText: 'Staff Audit Note (Optional)',
                            hintText: 'e.g. Authorized by Church Committee Meeting #4',
                            filled: true,
                            fillColor: AppColors.surfaceCream,
                            border: OutlineInputBorder(
                              borderRadius: AppStyles.roundedMedium,
                              borderSide: BorderSide(color: AppColors.softBeige),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: AppStyles.space20),

                // Dialog Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isProcessing
                          ? null
                          : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: AppStyles.space12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBrown,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onPressed: _isProcessing ? null : _handleSubmit,
                      child: _isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(isEdit ? 'Save Changes' : 'Publish Notice'),
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
}
