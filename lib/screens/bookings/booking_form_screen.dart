import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../core/api/api_client.dart';
import '../../config/api_config.dart';
import '../../models/accommodation.dart';
import '../../models/guest.dart';

class BookingFormScreen extends StatefulWidget {
  const BookingFormScreen({super.key});

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isLoadingData = true;
  String? _error;

  // Form fields
  int? _selectedAccommodationId;
  int? _selectedGuestId;
  DateTime? _checkIn;
  DateTime? _checkOut;
  int _adults = 2;
  int _children = 0;
  int _babies = 0;
  String _status = 'inquiry';
  String _source = 'direct';
  final _totalAmountController = TextEditingController();
  final _depositController = TextEditingController();
  final _cleaningFeeController = TextEditingController();
  final _notesController = TextEditingController();

  // Data
  List<Accommodation> _accommodations = [];
  List<Guest> _guests = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _totalAmountController.dispose();
    _depositController.dispose();
    _cleaningFeeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoadingData = true);

    try {
      final responses = await Future.wait([
        ApiClient.instance.get(ApiConfig.accommodations),
        ApiClient.instance.get(ApiConfig.guests),
      ]);

      // Parse accommodations
      List<dynamic> accData;
      if (responses[0].data is Map && responses[0].data['data'] != null) {
        accData = responses[0].data['data'] as List;
      } else if (responses[0].data is List) {
        accData = responses[0].data as List;
      } else {
        accData = [];
      }

      // Parse guests
      List<dynamic> guestData;
      if (responses[1].data is Map && responses[1].data['data'] != null) {
        guestData = responses[1].data['data'] as List;
      } else if (responses[1].data is List) {
        guestData = responses[1].data as List;
      } else {
        guestData = [];
      }

      setState(() {
        _accommodations = accData.map((json) => Accommodation.fromJson(json)).toList();
        _guests = guestData.map((json) => Guest.fromJson(json)).toList();
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Kon gegevens niet laden: $e';
        _isLoadingData = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nieuwe boeking'),
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Opnieuw proberen'),
                      ),
                    ],
                  ),
                )
              : _buildForm(),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Accommodation selection
          _buildSectionTitle('Accommodatie'),
          _buildAccommodationDropdown(),
          const SizedBox(height: 24),

          // Guest selection
          _buildSectionTitle('Gast'),
          _buildGuestDropdown(),
          const SizedBox(height: 24),

          // Dates
          _buildSectionTitle('Periode'),
          Row(
            children: [
              Expanded(child: _buildDateField('Check-in', _checkIn, (date) => setState(() => _checkIn = date))),
              const SizedBox(width: 16),
              Expanded(child: _buildDateField('Check-out', _checkOut, (date) => setState(() => _checkOut = date))),
            ],
          ),
          if (_checkIn != null && _checkOut != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${_checkOut!.difference(_checkIn!).inDays} nachten',
                style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w500),
              ),
            ),
          const SizedBox(height: 24),

          // Guests count
          _buildSectionTitle('Aantal personen'),
          Row(
            children: [
              Expanded(child: _buildCounterField('Volwassenen', _adults, (v) => setState(() => _adults = v), min: 1)),
              const SizedBox(width: 12),
              Expanded(child: _buildCounterField('Kinderen', _children, (v) => setState(() => _children = v))),
              const SizedBox(width: 12),
              Expanded(child: _buildCounterField("Baby's", _babies, (v) => setState(() => _babies = v))),
            ],
          ),
          const SizedBox(height: 24),

          // Status and source
          _buildSectionTitle('Status & Bron'),
          Row(
            children: [
              Expanded(child: _buildStatusDropdown()),
              const SizedBox(width: 16),
              Expanded(child: _buildSourceDropdown()),
            ],
          ),
          const SizedBox(height: 24),

          // Financial
          _buildSectionTitle('Financieel'),
          TextFormField(
            controller: _totalAmountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Totaalbedrag *',
              prefixText: '€ ',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Voer een bedrag in';
              }
              if (double.tryParse(value.replaceAll(',', '.')) == null) {
                return 'Voer een geldig bedrag in';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _depositController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Aanbetaling',
                    prefixText: '€ ',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _cleaningFeeController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Schoonmaak',
                    prefixText: '€ ',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Notes
          _buildSectionTitle('Notities'),
          TextFormField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Interne notities...',
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
                  : const Text('Boeking opslaan', style: TextStyle(fontSize: 16)),
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

  Widget _buildAccommodationDropdown() {
    return DropdownButtonFormField<int>(
      value: _selectedAccommodationId,
      decoration: const InputDecoration(
        labelText: 'Selecteer accommodatie *',
        border: OutlineInputBorder(),
      ),
      items: _accommodations.map((acc) {
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
      }).toList(),
      onChanged: (value) {
        setState(() => _selectedAccommodationId = value);
        // Auto-fill cleaning fee
        final acc = _accommodations.firstWhere((a) => a.id == value);
        if (acc.cleaningFee != null) {
          _cleaningFeeController.text = acc.cleaningFee!.toStringAsFixed(2);
        }
      },
      validator: (value) => value == null ? 'Selecteer een accommodatie' : null,
    );
  }

  Widget _buildGuestDropdown() {
    return DropdownButtonFormField<int>(
      value: _selectedGuestId,
      decoration: InputDecoration(
        labelText: 'Selecteer gast *',
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: const Icon(Icons.person_add),
          onPressed: _showAddGuestDialog,
          tooltip: 'Nieuwe gast',
        ),
      ),
      items: _guests.map((guest) {
        return DropdownMenuItem(
          value: guest.id,
          child: Text(guest.fullName, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedGuestId = value),
      validator: (value) => value == null ? 'Selecteer een gast' : null,
    );
  }

  Widget _buildDateField(String label, DateTime? value, Function(DateTime) onChanged) {
    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? now,
          firstDate: DateTime(2020),
          lastDate: DateTime(now.year + 3),
          locale: const Locale('nl', 'NL'),
        );
        if (picked != null) {
          onChanged(picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          value != null ? _formatDate(value) : 'Selecteer datum',
          style: TextStyle(
            color: value != null ? Colors.black : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildCounterField(String label, int value, Function(int) onChanged, {int min = 0, int max = 20}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[400]!),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: value > min ? () => onChanged(value - 1) : null,
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '$value',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: value < max ? () => onChanged(value + 1) : null,
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      value: _status,
      decoration: const InputDecoration(
        labelText: 'Status',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 'inquiry', child: Text('Aanvraag')),
        DropdownMenuItem(value: 'option', child: Text('Optie')),
        DropdownMenuItem(value: 'confirmed', child: Text('Bevestigd')),
      ],
      onChanged: (value) => setState(() => _status = value!),
    );
  }

  Widget _buildSourceDropdown() {
    return DropdownButtonFormField<String>(
      value: _source,
      decoration: const InputDecoration(
        labelText: 'Bron',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 'direct', child: Text('Direct')),
        DropdownMenuItem(value: 'website', child: Text('Website')),
        DropdownMenuItem(value: 'airbnb', child: Text('Airbnb')),
        DropdownMenuItem(value: 'booking', child: Text('Booking.com')),
        DropdownMenuItem(value: 'other', child: Text('Anders')),
      ],
      onChanged: (value) => setState(() => _source = value!),
    );
  }

  void _showAddGuestDialog() {
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nieuwe gast'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: firstNameController,
                decoration: const InputDecoration(labelText: 'Voornaam *'),
              ),
              TextField(
                controller: lastNameController,
                decoration: const InputDecoration(labelText: 'Achternaam'),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email *'),
                keyboardType: TextInputType.emailAddress,
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Telefoon'),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuleren'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (firstNameController.text.isEmpty || emailController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Voornaam en email zijn verplicht')),
                );
                return;
              }

              try {
                final response = await ApiClient.instance.post(
                  ApiConfig.guests,
                  data: {
                    'first_name': firstNameController.text,
                    'last_name': lastNameController.text,
                    'email': emailController.text,
                    'phone': phoneController.text,
                  },
                );

                final newGuest = Guest.fromJson(response.data);
                setState(() {
                  _guests.add(newGuest);
                  _selectedGuestId = newGuest.id;
                });

                if (mounted) Navigator.pop(context);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Fout: $e')),
                  );
                }
              }
            },
            child: const Text('Toevoegen'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_checkIn == null || _checkOut == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecteer check-in en check-out datum')),
      );
      return;
    }

    if (_checkOut!.isBefore(_checkIn!) || _checkOut!.isAtSameMomentAs(_checkIn!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check-out moet na check-in zijn')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = {
        'accommodation_id': _selectedAccommodationId,
        'guest_id': _selectedGuestId,
        'check_in': _formatDateForApi(_checkIn!),
        'check_out': _formatDateForApi(_checkOut!),
        'adults': _adults,
        'children': _children,
        'babies': _babies,
        'status': _status,
        'source': _source,
        'total_amount': double.parse(_totalAmountController.text.replaceAll(',', '.')),
      };

      if (_depositController.text.isNotEmpty) {
        data['deposit_amount'] = double.parse(_depositController.text.replaceAll(',', '.'));
      }
      if (_cleaningFeeController.text.isNotEmpty) {
        data['cleaning_fee'] = double.parse(_cleaningFeeController.text.replaceAll(',', '.'));
      }
      if (_notesController.text.isNotEmpty) {
        data['internal_notes'] = _notesController.text;
      }

      final response = await ApiClient.instance.post(ApiConfig.bookings, data: data);
      final bookingId = response.data['id'];

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Boeking aangemaakt!')),
        );
        context.go('/bookings/$bookingId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}-${date.month}-${date.year}';
  }

  String _formatDateForApi(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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
