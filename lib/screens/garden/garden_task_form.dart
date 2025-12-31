import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../config/api_config.dart';
import '../../core/api/api_client.dart';
import '../../models/garden/garden_task.dart';

class GardenTaskForm extends StatefulWidget {
  final int? accommodationId;
  final String? accommodationName;
  final GardenTask? task;

  const GardenTaskForm({
    super.key,
    this.accommodationId,
    this.accommodationName,
    this.task,
  });

  @override
  State<GardenTaskForm> createState() => _GardenTaskFormState();
}

class _GardenTaskFormState extends State<GardenTaskForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  bool _isDeleting = false;

  List<Map<String, dynamic>> _accommodations = [];
  int? _selectedAccommodationId;
  String _selectedCategory = 'mowing';
  String _selectedPriority = 'medium';
  DateTime? _dueDate;
  bool _isRecurring = false;
  String? _recurringInterval;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _estimatedMinutesController = TextEditingController();
  final _notesController = TextEditingController();

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    _selectedAccommodationId = widget.accommodationId ?? widget.task?.accommodationId;

    if (widget.task != null) {
      final t = widget.task!;
      _titleController.text = t.title;
      _descriptionController.text = t.description ?? '';
      _selectedCategory = t.category;
      _selectedPriority = t.priority;
      _dueDate = t.dueDate;
      _estimatedMinutesController.text = t.estimatedMinutes?.toString() ?? '';
      _notesController.text = t.notes ?? '';
      _isRecurring = t.isRecurring;
      _recurringInterval = t.recurringInterval;
    }

    _loadAccommodations();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _estimatedMinutesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadAccommodations() async {
    try {
      final response = await ApiClient.instance.get(ApiConfig.accommodations);
      final data = response.data['data'] as List;
      setState(() {
        _accommodations = data.map((a) => {'id': a['id'], 'name': a['name']}).toList();
        if (_selectedAccommodationId == null && _accommodations.isNotEmpty) {
          _selectedAccommodationId = _accommodations.first['id'];
        }
      });
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l10n.editGardenTask : l10n.newGardenTask),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _isDeleting ? null : _deleteTask,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Accommodation
            DropdownButtonFormField<int>(
              value: _selectedAccommodationId,
              decoration: InputDecoration(
                labelText: l10n.accommodation,
                prefixIcon: const Icon(Icons.home_work),
                border: const OutlineInputBorder(),
              ),
              items: _accommodations.map((a) {
                return DropdownMenuItem<int>(
                  value: a['id'],
                  child: Text(a['name']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedAccommodationId = value;
                });
              },
              validator: (value) => value == null ? l10n.required : null,
            ),
            const SizedBox(height: 16),

            // Title
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: l10n.taskTitle,
                prefixIcon: const Icon(Icons.title),
                border: const OutlineInputBorder(),
              ),
              validator: (value) => value?.isEmpty == true ? l10n.required : null,
            ),
            const SizedBox(height: 16),

            // Category
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: l10n.category,
                prefixIcon: Icon(_getCategoryIcon(_selectedCategory)),
                border: const OutlineInputBorder(),
              ),
              items: GardenCategory.all.map((cat) {
                return DropdownMenuItem<String>(
                  value: cat,
                  child: Row(
                    children: [
                      Icon(_getCategoryIcon(cat), size: 20),
                      const SizedBox(width: 8),
                      Text(_getCategoryLabel(cat, l10n)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Priority
            DropdownButtonFormField<String>(
              value: _selectedPriority,
              decoration: InputDecoration(
                labelText: l10n.priority,
                prefixIcon: Icon(Icons.flag, color: _getPriorityColor(_selectedPriority)),
                border: const OutlineInputBorder(),
              ),
              items: GardenPriority.all.map((p) {
                return DropdownMenuItem<String>(
                  value: p,
                  child: Row(
                    children: [
                      Icon(Icons.flag, color: _getPriorityColor(p), size: 20),
                      const SizedBox(width: 8),
                      Text(_getPriorityLabel(p, l10n)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPriority = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Due date
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: Text(l10n.dueDate),
              subtitle: Text(_dueDate != null
                  ? '${_dueDate!.day}-${_dueDate!.month}-${_dueDate!.year}'
                  : l10n.notSet),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_dueDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _dueDate = null),
                    ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: _selectDueDate,
                  ),
                ],
              ),
            ),
            const Divider(),

            // Estimated time
            TextFormField(
              controller: _estimatedMinutesController,
              decoration: InputDecoration(
                labelText: l10n.estimatedTime,
                prefixIcon: const Icon(Icons.timer),
                suffixText: l10n.minutes,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: l10n.description,
                prefixIcon: const Icon(Icons.description),
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Recurring toggle
            SwitchListTile(
              title: Text(l10n.recurringTask),
              subtitle: Text(l10n.recurringTaskDescription),
              value: _isRecurring,
              onChanged: (value) {
                setState(() {
                  _isRecurring = value;
                  if (!value) {
                    _recurringInterval = null;
                  }
                });
              },
            ),

            // Recurring interval
            if (_isRecurring) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _recurringInterval,
                decoration: InputDecoration(
                  labelText: l10n.recurringInterval,
                  prefixIcon: const Icon(Icons.repeat),
                  border: const OutlineInputBorder(),
                ),
                items: RecurringInterval.all.map((interval) {
                  return DropdownMenuItem<String>(
                    value: interval,
                    child: Text(_getIntervalLabel(interval, l10n)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _recurringInterval = value;
                  });
                },
                validator: (value) =>
                    _isRecurring && value == null ? l10n.required : null,
              ),
            ],
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: l10n.notes,
                prefixIcon: const Icon(Icons.note),
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Submit button
            FilledButton.icon(
              onPressed: _isSaving ? null : _saveTask,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_isEditing ? l10n.save : l10n.create),
            ),

            // Complete button (for editing existing tasks)
            if (_isEditing && widget.task?.status != 'completed') ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _isSaving ? null : _completeTask,
                icon: const Icon(Icons.check_circle, color: Colors.green),
                label: Text(l10n.markComplete),
              ),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date != null) {
      setState(() {
        _dueDate = date;
      });
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAccommodationId == null) return;

    setState(() => _isSaving = true);

    try {
      final data = {
        'accommodation_id': _selectedAccommodationId,
        'title': _titleController.text,
        'description': _descriptionController.text.isEmpty ? null : _descriptionController.text,
        'category': _selectedCategory,
        'priority': _selectedPriority,
        'due_date': _dueDate?.toIso8601String().split('T')[0],
        'estimated_minutes': _estimatedMinutesController.text.isNotEmpty
            ? int.tryParse(_estimatedMinutesController.text)
            : null,
        'notes': _notesController.text.isEmpty ? null : _notesController.text,
        'is_recurring': _isRecurring,
        'recurring_interval': _isRecurring ? _recurringInterval : null,
      };

      if (_isEditing) {
        await ApiClient.instance.put(
          '${ApiConfig.gardenTasks}/${widget.task!.id}',
          data: data,
        );
      } else {
        await ApiClient.instance.post(ApiConfig.gardenTasks, data: data);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _completeTask() async {
    if (widget.task == null) return;

    setState(() => _isSaving = true);

    try {
      await ApiClient.instance.post(
        '${ApiConfig.gardenTasks}/${widget.task!.id}/complete',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.taskCompleted)),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _deleteTask() async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteTask),
        content: Text(l10n.deleteTaskConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);

    try {
      await ApiClient.instance.delete(
        '${ApiConfig.gardenTasks}/${widget.task!.id}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.taskDeleted)),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isDeleting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow[700]!;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'mowing':
        return Icons.grass;
      case 'pruning':
        return Icons.content_cut;
      case 'weeding':
        return Icons.eco;
      case 'fertilizing':
        return Icons.compost;
      case 'watering':
        return Icons.water_drop;
      case 'leaf_removal':
        return Icons.energy_savings_leaf;
      case 'hedge_trimming':
        return Icons.park;
      case 'planting':
        return Icons.local_florist;
      case 'seeding':
        return Icons.grain;
      case 'composting':
        return Icons.recycling;
      case 'tool_maintenance':
        return Icons.build;
      default:
        return Icons.more_horiz;
    }
  }

  String _getCategoryLabel(String category, AppLocalizations l10n) {
    switch (category) {
      case 'mowing':
        return l10n.mowing;
      case 'pruning':
        return l10n.pruning;
      case 'weeding':
        return l10n.weeding;
      case 'fertilizing':
        return l10n.fertilizing;
      case 'watering':
        return l10n.watering;
      case 'leaf_removal':
        return l10n.leafRemoval;
      case 'hedge_trimming':
        return l10n.hedgeTrimming;
      case 'planting':
        return l10n.planting;
      case 'seeding':
        return l10n.seeding;
      case 'composting':
        return l10n.composting;
      case 'tool_maintenance':
        return l10n.toolMaintenance;
      default:
        return l10n.other;
    }
  }

  String _getPriorityLabel(String priority, AppLocalizations l10n) {
    switch (priority) {
      case 'urgent':
        return l10n.urgent;
      case 'high':
        return l10n.high;
      case 'medium':
        return l10n.medium;
      case 'low':
        return l10n.low;
      default:
        return priority;
    }
  }

  String _getIntervalLabel(String interval, AppLocalizations l10n) {
    switch (interval) {
      case 'daily':
        return l10n.daily;
      case 'weekly':
        return l10n.weekly;
      case 'biweekly':
        return l10n.biweekly;
      case 'monthly':
        return l10n.monthly;
      case 'quarterly':
        return l10n.quarterly;
      case 'yearly':
        return l10n.yearly;
      default:
        return interval;
    }
  }
}
