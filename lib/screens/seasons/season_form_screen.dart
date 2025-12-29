import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../config/theme.dart';
import '../../config/api_config.dart';
import '../../core/api/api_client.dart';
import '../../models/season.dart';

class SeasonFormScreen extends StatefulWidget {
  final Season? season;

  const SeasonFormScreen({super.key, this.season});

  @override
  State<SeasonFormScreen> createState() => _SeasonFormScreenState();
}

class _SeasonFormScreenState extends State<SeasonFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  String _selectedType = 'mid';
  int _selectedYear = DateTime.now().year;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isSaving = false;

  bool get _isEditing => widget.season != null;

  @override
  void initState() {
    super.initState();
    if (widget.season != null) {
      _nameController.text = widget.season!.name;
      _selectedType = widget.season!.type;
      _selectedYear = widget.season!.year;
      _startDate = DateTime.tryParse(widget.season!.startDate);
      _endDate = DateTime.tryParse(widget.season!.endDate);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(bool isStart) async {
    final initialDate = isStart ? _startDate : _endDate;
    final firstDate = DateTime(_selectedYear, 1, 1);
    final lastDate = DateTime(_selectedYear, 12, 31);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime(_selectedYear, isStart ? 1 : 12, isStart ? 1 : 31),
      firstDate: firstDate,
      lastDate: lastDate,
      locale: const Locale('nl', 'NL'),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          // If end date is before start date, reset it
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.selectStartAndEndDate), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final data = {
        'name': _nameController.text.trim(),
        'type': _selectedType,
        'year': _selectedYear,
        'start_date': _formatDateForApi(_startDate!),
        'end_date': _formatDateForApi(_endDate!),
      };

      if (_isEditing) {
        await ApiClient.instance.put('${ApiConfig.seasons}/${widget.season!.id}', data: data);
      } else {
        await ApiClient.instance.post(ApiConfig.seasons, data: data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? l10n.seasonUpdated : l10n.seasonAdded),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.couldNotSaveError(e.toString())), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatDateForApi(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    final months = ['januari', 'februari', 'maart', 'april', 'mei', 'juni',
                    'juli', 'augustus', 'september', 'oktober', 'november', 'december'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l10n.editSeason : l10n.newSeason),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Season name
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.name,
                hintText: l10n.nameHint,
                prefixIcon: const Icon(Icons.label_outline),
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.enterNameValidation;
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Year selector
            DropdownButtonFormField<int>(
              value: _selectedYear,
              decoration: InputDecoration(
                labelText: l10n.yearLabel,
                prefixIcon: const Icon(Icons.calendar_today),
                border: const OutlineInputBorder(),
              ),
              items: [
                for (int year = DateTime.now().year - 1; year <= DateTime.now().year + 2; year++)
                  DropdownMenuItem(value: year, child: Text('$year')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedYear = value;
                    // Reset dates when year changes
                    _startDate = null;
                    _endDate = null;
                  });
                }
              },
            ),
            const SizedBox(height: 24),

            // Season type
            Text(
              l10n.seasonTypeLabel,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildTypeOption('low', l10n.lowSeason, Icons.ac_unit, Colors.blue)),
                const SizedBox(width: 8),
                Expanded(child: _buildTypeOption('mid', l10n.midSeason, Icons.cloud, Colors.grey)),
                const SizedBox(width: 8),
                Expanded(child: _buildTypeOption('high', l10n.highSeason, Icons.wb_sunny, Colors.orange)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _getTypeDescription(l10n),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 24),

            // Date range
            Text(
              l10n.period,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDateButton(
                    label: l10n.startDate,
                    date: _startDate,
                    onTap: () => _selectDate(true),
                    l10n: l10n,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.arrow_forward, color: Colors.grey),
                ),
                Expanded(
                  child: _buildDateButton(
                    label: l10n.endDate,
                    date: _endDate,
                    onTap: () => _selectDate(false),
                    l10n: l10n,
                  ),
                ),
              ],
            ),

            if (_startDate != null && _endDate != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      l10n.daysCount(_endDate!.difference(_startDate!).inDays + 1),
                      style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Explanation
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        l10n.howDoSeasonsWork,
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[800]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.seasonsExplanation,
                    style: TextStyle(color: Colors.blue[700], fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Save button
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check),
                label: Text(_isSaving ? l10n.saving : l10n.save),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeOption(String type, String label, IconData icon, Color color) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey[400], size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getTypeDescription(AppLocalizations l10n) {
    switch (_selectedType) {
      case 'low':
        return l10n.lowSeasonDescription;
      case 'high':
        return l10n.highSeasonDescription;
      default:
        return l10n.midSeasonDescription;
    }
  }

  Widget _buildDateButton({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    required AppLocalizations l10n,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: date != null ? AppTheme.primaryColor : Colors.grey[400],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    date != null ? _formatDate(date) : l10n.selectDate,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: date != null ? Colors.black87 : Colors.grey[500],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
