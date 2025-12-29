import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../config/theme.dart';
import '../../config/api_config.dart';
import '../../core/api/api_client.dart';
import '../../models/maintenance.dart';
import '../../models/accommodation.dart';
import '../../utils/responsive.dart';

class MaintenanceFormScreen extends StatefulWidget {
  final MaintenanceTask? task;

  const MaintenanceFormScreen({super.key, this.task});

  @override
  State<MaintenanceFormScreen> createState() => _MaintenanceFormScreenState();
}

class _MaintenanceFormScreenState extends State<MaintenanceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isLoadingData = true;

  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();

  // Form values
  int? _selectedAccommodationId;
  String _priority = 'medium';
  String _category = 'maintenance';
  DateTime? _dueDate;
  List<Accommodation> _accommodations = [];

  // Photos
  final List<File> _newPhotos = [];
  final List<String> _existingPhotos = [];
  final List<String> _photosToDelete = [];
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingPhotos = false;

  bool get isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    _loadAccommodations();
    if (isEditing) {
      _populateForm();
    }
  }

  void _populateForm() {
    final task = widget.task!;
    _titleController.text = task.title;
    _descriptionController.text = task.description ?? '';
    _notesController.text = task.notes ?? '';
    _selectedAccommodationId = task.accommodationId;
    _priority = task.priority;
    _category = task.category;
    _dueDate = task.dueDate;
    _existingPhotos.addAll(task.photos);
  }

  Future<void> _loadAccommodations() async {
    try {
      final response = await ApiClient.instance.get(ApiConfig.accommodations);

      List<dynamic> data;
      if (response.data is Map && response.data['data'] != null) {
        data = response.data['data'] as List;
      } else if (response.data is List) {
        data = response.data as List;
      } else {
        data = [];
      }

      setState(() {
        _accommodations = data.map((json) => Accommodation.fromJson(json)).toList();
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() => _isLoadingData = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? l10n.editTaskTitle : l10n.newMaintenanceTask),
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : _buildForm(),
    );
  }

  Widget _buildForm() {
    final l10n = AppLocalizations.of(context)!;
    final isTablet = Responsive.useWideLayout(context);
    final maxWidth = isTablet ? 600.0 : double.infinity;

    return Form(
      key: _formKey,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: ListView(
            padding: EdgeInsets.all(isTablet ? 24 : 16),
            children: [
          // Title
          _buildSectionTitle(l10n.titleLabel),
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: l10n.titleHint,
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.enterTitleError;
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Accommodation
          _buildSectionTitle(l10n.accommodationLabel),
          DropdownButtonFormField<int>(
            value: _selectedAccommodationId,
            decoration: InputDecoration(
              hintText: l10n.selectAccommodationOptional,
              border: const OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem<int>(
                value: null,
                child: Text(l10n.noSpecificAccommodation),
              ),
              ..._accommodations.map((acc) {
                return DropdownMenuItem(
                  value: acc.id,
                  child: Row(
                    children: [
                      if (acc.color != null)
                        Container(
                          width: 12,
                          height: 12,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: _parseColor(acc.color!),
                            shape: BoxShape.circle,
                          ),
                        ),
                      Expanded(child: Text(acc.name, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                );
              }),
            ],
            onChanged: (value) => setState(() => _selectedAccommodationId = value),
          ),
          const SizedBox(height: 24),

          // Description
          _buildSectionTitle(l10n.descriptionLabel),
          TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: l10n.descriptionHint,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),

          // Priority
          _buildSectionTitle(l10n.priorityLabel),
          _buildPrioritySelector(),
          const SizedBox(height: 24),

          // Category
          _buildSectionTitle(l10n.categoryLabel),
          _buildCategorySelector(),
          const SizedBox(height: 24),

          // Due date
          _buildSectionTitle(l10n.deadlineFieldLabel),
          _buildDateField(),
          const SizedBox(height: 24),

          // Photos
          _buildSectionTitle(l10n.photosLabel),
          _buildPhotoSection(),
          const SizedBox(height: 24),

          // Notes
          _buildSectionTitle(l10n.notesLabel),
          TextFormField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: l10n.notesHint,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 32),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitForm,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      isEditing ? l10n.save : l10n.createTask,
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
          ),
            const SizedBox(height: 32),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPrioritySelector() {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        _buildPriorityOption('low', l10n.priorityLowEmoji, Colors.green),
        const SizedBox(width: 8),
        _buildPriorityOption('medium', l10n.priorityMediumEmoji, Colors.amber[700]!),
        const SizedBox(width: 8),
        _buildPriorityOption('high', l10n.priorityHighEmoji, Colors.orange),
        const SizedBox(width: 8),
        _buildPriorityOption('urgent', l10n.priorityUrgentEmoji, Colors.red),
      ],
    );
  }

  Widget _buildPriorityOption(String value, String label, Color color) {
    final isSelected = _priority == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _priority = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.2) : Colors.grey[100],
            border: Border.all(
              color: isSelected ? color : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? color : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    final l10n = AppLocalizations.of(context)!;
    final categories = [
      {'value': 'repair', 'label': l10n.categoryRepair, 'icon': Icons.build},
      {'value': 'maintenance', 'label': l10n.categoryMaintenance, 'icon': Icons.settings},
      {'value': 'cleaning', 'label': l10n.categoryCleaning, 'icon': Icons.cleaning_services},
      {'value': 'inventory', 'label': l10n.categoryInventory, 'icon': Icons.inventory},
      {'value': 'inspection', 'label': l10n.categoryInspection, 'icon': Icons.search},
      {'value': 'other', 'label': l10n.categoryOther, 'icon': Icons.more_horiz},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((cat) {
        final isSelected = _category == cat['value'];
        return GestureDetector(
          onTap: () => setState(() => _category = cat['value'] as String),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor.withOpacity(0.15) : Colors.grey[100],
              border: Border.all(
                color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  cat['icon'] as IconData,
                  size: 16,
                  color: isSelected ? AppTheme.primaryColor : Colors.grey[600],
                ),
                const SizedBox(width: 6),
                Text(
                  cat['label'] as String,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppTheme.primaryColor : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateField() {
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: _showDatePicker,
      child: InputDecorator(
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_dueDate != null)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(() => _dueDate = null),
                ),
              const Icon(Icons.calendar_today),
              const SizedBox(width: 8),
            ],
          ),
        ),
        child: Text(
          _dueDate != null ? _formatDate(_dueDate!) : l10n.noDeadline,
          style: TextStyle(
            color: _dueDate != null ? Colors.black : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  void _showDatePicker() {
    final l10n = AppLocalizations.of(context)!;
    DateTime tempDate = _dueDate ?? DateTime.now();

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: Column(
            children: [
              Container(
                height: 50,
                color: CupertinoColors.systemGrey6.resolveFrom(context),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: Text(l10n.cancel),
                      onPressed: () => Navigator.pop(context),
                    ),
                    CupertinoButton(
                      child: Text(
                        l10n.readyButton,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        setState(() => _dueDate = tempDate);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: _dueDate ?? DateTime.now(),
                  minimumDate: DateTime.now().subtract(const Duration(days: 1)),
                  maximumDate: DateTime(DateTime.now().year + 2),
                  onDateTimeChanged: (DateTime newDate) {
                    tempDate = newDate;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Existing photos
        if (_existingPhotos.isNotEmpty) ...[
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _existingPhotos.length,
              itemBuilder: (context, index) {
                final photo = _existingPhotos[index];
                final isMarkedForDeletion = _photosToDelete.contains(photo);
                return Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[200],
                        image: DecorationImage(
                          image: NetworkImage(photo),
                          fit: BoxFit.cover,
                          opacity: isMarkedForDeletion ? 0.3 : 1.0,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 12,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isMarkedForDeletion) {
                              _photosToDelete.remove(photo);
                            } else {
                              _photosToDelete.add(photo);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isMarkedForDeletion ? Colors.green : Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isMarkedForDeletion ? Icons.undo : Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],

        // New photos
        if (_newPhotos.isNotEmpty) ...[
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _newPhotos.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[200],
                        image: DecorationImage(
                          image: FileImage(_newPhotos[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 12,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _newPhotos.removeAt(index);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Add photo buttons
        Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            return Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isUploadingPhotos ? null : () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: Text(l10n.cameraButton),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isUploadingPhotos ? null : () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: Text(l10n.galleryButton),
                  ),
                ),
              ],
            );
          },
        ),

        if (_isUploadingPhotos) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator(),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.uploadingPhotos,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ],
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _newPhotos.add(File(image.path));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.couldNotLoadPhotoError(e.toString()))),
        );
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // First, upload any new photos
      List<String> uploadedPhotoUrls = [];
      if (_newPhotos.isNotEmpty) {
        setState(() => _isUploadingPhotos = true);

        for (var photo in _newPhotos) {
          final fileName = photo.path.split('/').last;
          final formData = FormData.fromMap({
            'photo': await MultipartFile.fromFile(photo.path, filename: fileName),
          });

          final uploadResponse = await ApiClient.instance.post(
            '${ApiConfig.maintenance}/upload-photo',
            data: formData,
          );

          if (uploadResponse.data['url'] != null) {
            uploadedPhotoUrls.add(uploadResponse.data['url']);
          }
        }

        setState(() => _isUploadingPhotos = false);
      }

      // Prepare task data
      final data = {
        'title': _titleController.text,
        'description': _descriptionController.text.isEmpty ? null : _descriptionController.text,
        'accommodation_id': _selectedAccommodationId,
        'priority': _priority,
        'category': _category,
        'due_date': _dueDate?.toIso8601String().split('T')[0],
        'notes': _notesController.text.isEmpty ? null : _notesController.text,
      };

      // Handle photos
      final allPhotos = [
        ..._existingPhotos.where((p) => !_photosToDelete.contains(p)),
        ...uploadedPhotoUrls,
      ];
      if (allPhotos.isNotEmpty) {
        data['photos'] = allPhotos;
      }

      // Create or update
      if (isEditing) {
        await ApiClient.instance.put(
          '${ApiConfig.maintenance}/${widget.task!.id}',
          data: data,
        );
      } else {
        await ApiClient.instance.post(ApiConfig.maintenance, data: data);
      }

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? l10n.taskUpdatedSuccess : l10n.taskCreatedSuccess),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorWithMessage(e.toString()))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isUploadingPhotos = false;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'jan', 'feb', 'mrt', 'apr', 'mei', 'jun',
      'jul', 'aug', 'sep', 'okt', 'nov', 'dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Color _parseColor(String colorString) {
    try {
      if (colorString.startsWith('#')) {
        return Color(int.parse(colorString.substring(1), radix: 16) + 0xFF000000);
      }
      return AppTheme.primaryColor;
    } catch (e) {
      return AppTheme.primaryColor;
    }
  }
}
