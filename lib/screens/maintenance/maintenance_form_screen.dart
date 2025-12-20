import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../config/theme.dart';
import '../../config/api_config.dart';
import '../../core/api/api_client.dart';
import '../../models/maintenance.dart';
import '../../models/accommodation.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Taak bewerken' : 'Nieuwe onderhoudstaak'),
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : _buildForm(),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Title
          _buildSectionTitle('Titel'),
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              hintText: 'Bijv. Lekkende kraan badkamer',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Voer een titel in';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Accommodation
          _buildSectionTitle('Accommodatie'),
          DropdownButtonFormField<int>(
            value: _selectedAccommodationId,
            decoration: const InputDecoration(
              hintText: 'Selecteer accommodatie (optioneel)',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<int>(
                value: null,
                child: Text('Geen specifieke accommodatie'),
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
          _buildSectionTitle('Beschrijving'),
          TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Beschrijf het probleem of de taak...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),

          // Priority
          _buildSectionTitle('Prioriteit'),
          _buildPrioritySelector(),
          const SizedBox(height: 24),

          // Due date
          _buildSectionTitle('Deadline'),
          _buildDateField(),
          const SizedBox(height: 24),

          // Photos
          _buildSectionTitle("Foto's"),
          _buildPhotoSection(),
          const SizedBox(height: 24),

          // Notes
          _buildSectionTitle('Notities'),
          TextFormField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Extra opmerkingen...',
              border: OutlineInputBorder(),
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
                      isEditing ? 'Opslaan' : 'Taak aanmaken',
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
          ),
          const SizedBox(height: 32),
        ],
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
    return Row(
      children: [
        _buildPriorityOption('low', 'Laag', Colors.green),
        const SizedBox(width: 8),
        _buildPriorityOption('medium', 'Gemiddeld', Colors.amber[700]!),
        const SizedBox(width: 8),
        _buildPriorityOption('high', 'Hoog', Colors.orange),
        const SizedBox(width: 8),
        _buildPriorityOption('urgent', 'Spoed', Colors.red),
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

  Widget _buildDateField() {
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
          _dueDate != null ? _formatDate(_dueDate!) : 'Geen deadline',
          style: TextStyle(
            color: _dueDate != null ? Colors.black : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  void _showDatePicker() {
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
                      child: const Text('Annuleren'),
                      onPressed: () => Navigator.pop(context),
                    ),
                    CupertinoButton(
                      child: const Text(
                        'Gereed',
                        style: TextStyle(fontWeight: FontWeight.bold),
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
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isUploadingPhotos ? null : () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Camera'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isUploadingPhotos ? null : () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Galerij'),
              ),
            ),
          ],
        ),

        if (_isUploadingPhotos) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator(),
          const SizedBox(height: 8),
          Text(
            "Foto's uploaden...",
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ],
    );
  }

  Future<void> _pickImage(ImageSource source) async {
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
          SnackBar(content: Text('Kon foto niet laden: $e')),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Taak bijgewerkt' : 'Taak aangemaakt'),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout: $e')),
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
