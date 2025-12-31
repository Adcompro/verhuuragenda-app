import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../config/api_config.dart';
import '../../core/api/api_client.dart';
import '../../models/pool/pool_chemical.dart';

class PoolChemicalForm extends StatefulWidget {
  final int accommodationId;
  final String accommodationName;
  final PoolChemical? chemical;

  const PoolChemicalForm({
    super.key,
    required this.accommodationId,
    required this.accommodationName,
    this.chemical,
  });

  @override
  State<PoolChemicalForm> createState() => _PoolChemicalFormState();
}

class _PoolChemicalFormState extends State<PoolChemicalForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  late DateTime _addedAt;
  String? _selectedChemicalType;
  String _selectedUnit = 'gram';
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _addedAt = widget.chemical?.addedAt ?? DateTime.now();
    _selectedChemicalType = widget.chemical?.chemicalType;
    _selectedUnit = widget.chemical?.unit ?? 'gram';
    _amountController.text = widget.chemical?.amount.toString() ?? '';
    _notesController.text = widget.chemical?.notes ?? '';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = widget.chemical != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? l10n.editChemical : l10n.addChemical),
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
                title: Text(_formatDateTime(_addedAt)),
                subtitle: Text(l10n.addedAt),
                trailing: const Icon(Icons.edit),
                onTap: () => _selectDateTime(),
              ),
            ),
            const SizedBox(height: 24),

            // Chemical type
            Text(
              l10n.chemicalType,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ChemicalType.defaultTypes.map((type) {
                final isSelected = _selectedChemicalType == type.value;
                return ChoiceChip(
                  label: Text(type.label),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedChemicalType = selected ? type.value : null;
                    });
                  },
                  selectedColor: Colors.purple.withOpacity(0.2),
                  avatar: isSelected ? const Icon(Icons.check, size: 18) : null,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Amount and unit
            Text(
              l10n.amount,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      labelText: l10n.amount,
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.required;
                      }
                      final num = double.tryParse(value);
                      if (num == null || num <= 0) {
                        return l10n.invalidNumber;
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    value: _selectedUnit,
                    decoration: InputDecoration(
                      labelText: l10n.unit,
                      border: const OutlineInputBorder(),
                    ),
                    items: ChemicalUnit.defaultUnits.map((unit) {
                      return DropdownMenuItem(
                        value: unit.value,
                        child: Text(unit.label),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedUnit = value);
                      }
                    },
                  ),
                ),
              ],
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
                onPressed: _isSaving || _selectedChemicalType == null ? null : _save,
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
      initialDate: _addedAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null) return;

    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_addedAt),
    );
    if (time == null) return;

    setState(() {
      _addedAt = DateTime(
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
    if (_selectedChemicalType == null) return;

    setState(() => _isSaving = true);

    try {
      final data = {
        'accommodation_id': widget.accommodationId,
        'chemical_type': _selectedChemicalType,
        'amount': double.parse(_amountController.text),
        'unit': _selectedUnit,
        'added_at': _addedAt.toIso8601String(),
        'notes': _notesController.text.isNotEmpty ? _notesController.text : null,
      };

      if (widget.chemical != null) {
        await ApiClient.instance.put(
          '${ApiConfig.poolChemicals}/${widget.chemical!.id}',
          data: data,
        );
      } else {
        await ApiClient.instance.post(
          ApiConfig.poolChemicals,
          data: data,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.chemicalSaved)),
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
