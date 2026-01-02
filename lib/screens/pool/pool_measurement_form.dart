import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../config/api_config.dart';
import '../../core/api/api_client.dart';
import '../../models/pool/pool_measurement.dart';

class PoolMeasurementForm extends StatefulWidget {
  final int accommodationId;
  final String accommodationName;
  final PoolMeasurement? measurement;

  const PoolMeasurementForm({
    super.key,
    required this.accommodationId,
    required this.accommodationName,
    this.measurement,
  });

  @override
  State<PoolMeasurementForm> createState() => _PoolMeasurementFormState();
}

class _PoolMeasurementFormState extends State<PoolMeasurementForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  late DateTime _measuredAt;
  final _phController = TextEditingController();
  final _freeChlorineController = TextEditingController();
  final _totalChlorineController = TextEditingController();
  final _alkalinityController = TextEditingController();
  final _temperatureController = TextEditingController();
  final _cyanuricController = TextEditingController();
  final _calciumController = TextEditingController();
  final _tdsController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _measuredAt = widget.measurement?.measuredAt ?? DateTime.now();
    if (widget.measurement != null) {
      final m = widget.measurement!;
      _phController.text = m.phValue?.toString() ?? '';
      _freeChlorineController.text = m.freeChlorine?.toString() ?? '';
      _totalChlorineController.text = m.totalChlorine?.toString() ?? '';
      _alkalinityController.text = m.alkalinity?.toString() ?? '';
      _temperatureController.text = m.waterTemperature?.toString() ?? '';
      _cyanuricController.text = m.cyanuricAcid?.toString() ?? '';
      _calciumController.text = m.calciumHardness?.toString() ?? '';
      _tdsController.text = m.tds?.toString() ?? '';
      _notesController.text = m.notes ?? '';
    }
  }

  @override
  void dispose() {
    _phController.dispose();
    _freeChlorineController.dispose();
    _totalChlorineController.dispose();
    _alkalinityController.dispose();
    _temperatureController.dispose();
    _cyanuricController.dispose();
    _calciumController.dispose();
    _tdsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = widget.measurement != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? l10n.editMeasurement : l10n.newMeasurement),
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
                title: Text(_formatDateTime(_measuredAt)),
                subtitle: Text(l10n.measuredAt),
                trailing: const Icon(Icons.edit),
                onTap: () => _selectDateTime(),
              ),
            ),
            const SizedBox(height: 24),

            // Main measurements (pH, Chlorine, Temperature)
            Text(
              l10n.mainMeasurements,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildNumberField(
                    controller: _phController,
                    label: 'pH',
                    hint: '7.2 - 7.6',
                    min: 0,
                    max: 14,
                    decimals: 1,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildNumberField(
                    controller: _freeChlorineController,
                    label: '${l10n.freeChlorine} (ppm)',
                    hint: '1.0 - 3.0',
                    min: 0,
                    max: 20,
                    decimals: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildNumberField(
                    controller: _temperatureController,
                    label: '${l10n.temperature} (C)',
                    hint: '26 - 28',
                    min: 0,
                    max: 50,
                    decimals: 1,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildNumberField(
                    controller: _alkalinityController,
                    label: '${l10n.alkalinity} (ppm)',
                    hint: '80 - 120',
                    min: 0,
                    max: 500,
                    decimals: 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Optional measurements
            ExpansionTile(
              title: Text(l10n.additionalMeasurements),
              initiallyExpanded: false,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildNumberField(
                              controller: _totalChlorineController,
                              label: '${l10n.totalChlorine} (ppm)',
                              hint: '',
                              min: 0,
                              max: 20,
                              decimals: 2,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildNumberField(
                              controller: _cyanuricController,
                              label: '${l10n.cyanuricAcid} (ppm)',
                              hint: '30 - 50',
                              min: 0,
                              max: 200,
                              decimals: 0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildNumberField(
                              controller: _calciumController,
                              label: '${l10n.calciumHardness} (ppm)',
                              hint: '200 - 400',
                              min: 0,
                              max: 1000,
                              decimals: 0,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildNumberField(
                              controller: _tdsController,
                              label: 'TDS (ppm)',
                              hint: '< 1500',
                              min: 0,
                              max: 10000,
                              decimals: 0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

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
                onPressed: _isSaving ? null : _save,
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

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required double min,
    required double max,
    required int decimals,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        // Allow digits, dot, and comma
        FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
        // Replace comma with dot for consistent decimal handling
        TextInputFormatter.withFunction((oldValue, newValue) {
          return newValue.copyWith(
            text: newValue.text.replaceAll(',', '.'),
          );
        }),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) return null; // Optional
        // Replace comma with dot for parsing
        final normalized = value.replaceAll(',', '.');
        final num = double.tryParse(normalized);
        if (num == null) {
          return AppLocalizations.of(context)!.invalidNumber;
        }
        if (num < min || num > max) {
          return '${min.toInt()} - ${max.toInt()}';
        }
        return null;
      },
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _measuredAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null) return;

    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_measuredAt),
    );
    if (time == null) return;

    setState(() {
      _measuredAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  // Helper to parse decimal with comma or dot support
  double? _parseDecimal(String text) {
    if (text.isEmpty) return null;
    return double.tryParse(text.replaceAll(',', '.'));
  }

  int? _parseInt(String text) {
    if (text.isEmpty) return null;
    // Also handle comma for integers (e.g., "1,0" -> 1)
    final normalized = text.replaceAll(',', '.');
    final d = double.tryParse(normalized);
    return d?.toInt();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final data = {
        'accommodation_id': widget.accommodationId,
        'measured_at': _measuredAt.toIso8601String(),
        'ph_value': _parseDecimal(_phController.text),
        'free_chlorine': _parseDecimal(_freeChlorineController.text),
        'total_chlorine': _parseDecimal(_totalChlorineController.text),
        'alkalinity': _parseInt(_alkalinityController.text),
        'water_temperature': _parseDecimal(_temperatureController.text),
        'cyanuric_acid': _parseInt(_cyanuricController.text),
        'calcium_hardness': _parseInt(_calciumController.text),
        'tds': _parseInt(_tdsController.text),
        'notes': _notesController.text.isNotEmpty ? _notesController.text : null,
      };

      if (widget.measurement != null) {
        await ApiClient.instance.put(
          '${ApiConfig.poolMeasurements}/${widget.measurement!.id}',
          data: data,
        );
      } else {
        await ApiClient.instance.post(
          ApiConfig.poolMeasurements,
          data: data,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.measurementSaved)),
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
