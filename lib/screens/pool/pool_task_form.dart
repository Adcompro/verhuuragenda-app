import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../config/api_config.dart';
import '../../core/api/api_client.dart';
import '../../models/pool/pool_task.dart';

class PoolTaskForm extends StatefulWidget {
  final int accommodationId;
  final String accommodationName;
  final PoolTask? task;

  const PoolTaskForm({
    super.key,
    required this.accommodationId,
    required this.accommodationName,
    this.task,
  });

  @override
  State<PoolTaskForm> createState() => _PoolTaskFormState();
}

class _PoolTaskFormState extends State<PoolTaskForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  late DateTime _performedAt;
  String? _selectedTaskType;
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _performedAt = widget.task?.performedAt ?? DateTime.now();
    _selectedTaskType = widget.task?.taskType;
    _notesController.text = widget.task?.notes ?? '';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = widget.task != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? l10n.editTask : l10n.addTask),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Accommodation (read-only)
            Card(
              child: ListTile(
                leading: const Icon(Icons.home),
                title: Text(widget.accommodationName),
                subtitle: Text(l10n.accommodation),
              ),
            ),
            const SizedBox(height: 16),

            // Date/time
            Card(
              child: ListTile(
                leading: const Icon(Icons.schedule),
                title: Text(_formatDateTime(_performedAt)),
                subtitle: Text(l10n.performedAt),
                trailing: const Icon(Icons.edit),
                onTap: () => _selectDateTime(),
              ),
            ),
            const SizedBox(height: 24),

            // Task type
            Text(
              l10n.taskType,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: PoolTaskType.defaultTypes.map((type) {
                final isSelected = _selectedTaskType == type.value;
                return ChoiceChip(
                  label: Text(type.label),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedTaskType = selected ? type.value : null;
                    });
                  },
                  selectedColor: Colors.green.withOpacity(0.2),
                  avatar: isSelected ? const Icon(Icons.check, size: 18) : null,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: l10n.notes,
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving || _selectedTaskType == null ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.save),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _performedAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null) return;

    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_performedAt),
    );
    if (time == null) return;

    setState(() {
      _performedAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTaskType == null) return;

    setState(() => _isSaving = true);

    try {
      final data = {
        'accommodation_id': widget.accommodationId,
        'task_type': _selectedTaskType,
        'performed_at': _performedAt.toIso8601String(),
        'notes': _notesController.text.isNotEmpty ? _notesController.text : null,
      };

      if (widget.task != null) {
        await ApiClient.instance.put(
          '${ApiConfig.poolTasks}/${widget.task!.id}',
          data: data,
        );
      } else {
        await ApiClient.instance.post(
          ApiConfig.poolTasks,
          data: data,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.taskSaved)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.couldNotSave)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
