import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../config/theme.dart';
import '../../core/api/api_client.dart';
import '../../config/api_config.dart';
import '../../models/accommodation.dart';

class AccommodationEditScreen extends StatefulWidget {
  final int? accommodationId; // null = new accommodation

  const AccommodationEditScreen({super.key, this.accommodationId});

  @override
  State<AccommodationEditScreen> createState() => _AccommodationEditScreenState();
}

class _AccommodationEditScreenState extends State<AccommodationEditScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isLoadingData = false;
  String? _error;
  Accommodation? _accommodation;

  // Controllers
  final _nameController = TextEditingController();
  final _maxGuestsController = TextEditingController();
  final _bedroomsController = TextEditingController();
  final _bathroomsController = TextEditingController();
  final _priceLowController = TextEditingController();
  final _priceMidController = TextEditingController();
  final _priceHighController = TextEditingController();
  final _cleaningFeeController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _wifiNetworkController = TextEditingController();
  final _wifiPasswordController = TextEditingController();
  final _alarmCodeController = TextEditingController();
  final _checkinFromController = TextEditingController();
  final _checkinUntilController = TextEditingController();
  final _checkoutController = TextEditingController();
  final _houseRulesController = TextEditingController();
  final _arrivalController = TextEditingController();
  final _icalAirbnbController = TextEditingController();
  final _icalBookingController = TextEditingController();
  final _icalVrboController = TextEditingController();
  final _icalGoogleController = TextEditingController();
  final _icalHoliduController = TextEditingController();
  final _icalBelvillaController = TextEditingController();
  final _icalOtherController = TextEditingController();

  String _propertyType = 'house';
  String _selectedColor = '#3B82F6';
  bool _isActive = true;
  bool _hasPool = false;
  bool _hasGarden = false;
  int? _sharedPoolWithId;
  int? _sharedGardenWithId;
  final _poolGroupNameController = TextEditingController();
  final _gardenGroupNameController = TextEditingController();
  List<Accommodation> _otherPoolOwners = [];
  List<Accommodation> _otherGardenOwners = [];

  // Photos
  List<Map<String, dynamic>> _photos = [];
  bool _photoUploading = false;

  bool get isEditing => widget.accommodationId != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _loadAccommodation();
    } else {
      // Set defaults for new accommodation
      _maxGuestsController.text = '4';
      _bedroomsController.text = '2';
      _bathroomsController.text = '1';
      _checkinFromController.text = '15:00';
      _checkinUntilController.text = '20:00';
      _checkoutController.text = '10:00';
    }
    _loadShareCandidates();
  }

  /// Fetch other accommodations whose pool / garden can be shared.
  Future<void> _loadShareCandidates() async {
    try {
      final response =
          await ApiClient.instance.get(ApiConfig.accommodations);
      final list = (response.data as List)
          .map((e) => Accommodation.fromJson(e as Map<String, dynamic>))
          .toList();
      // Exclude self when editing, exclude accommodations that
      // themselves share (avoid 2-hop chains).
      final pools = list
          .where((a) =>
              a.id != widget.accommodationId &&
              a.hasPool &&
              a.sharedPoolWithId == null)
          .toList();
      final gardens = list
          .where((a) =>
              a.id != widget.accommodationId &&
              a.hasGarden &&
              a.sharedGardenWithId == null)
          .toList();
      if (mounted) {
        setState(() {
          _otherPoolOwners = pools;
          _otherGardenOwners = gardens;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _maxGuestsController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _priceLowController.dispose();
    _priceMidController.dispose();
    _priceHighController.dispose();
    _cleaningFeeController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _wifiNetworkController.dispose();
    _wifiPasswordController.dispose();
    _alarmCodeController.dispose();
    _checkinFromController.dispose();
    _checkinUntilController.dispose();
    _checkoutController.dispose();
    _houseRulesController.dispose();
    _arrivalController.dispose();
    _icalAirbnbController.dispose();
    _icalBookingController.dispose();
    _icalVrboController.dispose();
    _icalGoogleController.dispose();
    _icalHoliduController.dispose();
    _icalBelvillaController.dispose();
    _icalOtherController.dispose();
    _poolGroupNameController.dispose();
    _gardenGroupNameController.dispose();
    super.dispose();
  }

  Future<void> _loadAccommodation() async {
    setState(() => _isLoadingData = true);

    try {
      final response = await ApiClient.instance.get('${ApiConfig.accommodations}/${widget.accommodationId}');
      final acc = Accommodation.fromJson(response.data);

      // Extract raw photo objects (with id) — Accommodation model only keeps urls
      final rawPhotos = response.data['photos'];
      final photoList = rawPhotos is List
          ? rawPhotos
              .whereType<Map>()
              .map<Map<String, dynamic>>((p) => Map<String, dynamic>.from(p))
              .toList()
          : <Map<String, dynamic>>[];

      setState(() {
        _accommodation = acc;
        _photos = photoList;
        _nameController.text = acc.name;
        _maxGuestsController.text = acc.maxGuests?.toString() ?? '';
        _bedroomsController.text = acc.bedrooms?.toString() ?? '';
        _bathroomsController.text = acc.bathrooms?.toString() ?? '';
        _priceLowController.text = acc.basePriceLow?.toStringAsFixed(0) ?? '';
        _priceMidController.text = acc.basePriceMid?.toStringAsFixed(0) ?? '';
        _priceHighController.text = acc.basePriceHigh?.toStringAsFixed(0) ?? '';
        _cleaningFeeController.text = acc.cleaningFee?.toStringAsFixed(0) ?? '';
        _addressController.text = acc.address ?? '';
        _cityController.text = acc.city ?? '';
        _wifiNetworkController.text = acc.wifiNetwork ?? '';
        _wifiPasswordController.text = acc.wifiPassword ?? '';
        _alarmCodeController.text = acc.alarmCode ?? '';
        _checkinFromController.text = acc.checkinTimeFrom ?? '15:00';
        _checkinUntilController.text = acc.checkinTimeUntil ?? '20:00';
        _checkoutController.text = acc.checkoutTime ?? '10:00';
        _houseRulesController.text = acc.houseRules ?? '';
        _arrivalController.text = acc.arrivalInstructions ?? '';
        _icalAirbnbController.text = acc.icalAirbnbUrl ?? '';
        _icalBookingController.text = acc.icalBookingUrl ?? '';
        _icalVrboController.text = acc.icalVrboUrl ?? '';
        _icalGoogleController.text = acc.icalGoogleUrl ?? '';
        _icalHoliduController.text = acc.icalHoliduUrl ?? '';
        _icalBelvillaController.text = acc.icalBelvillaUrl ?? '';
        _icalOtherController.text = acc.icalOtherUrl ?? '';
        _propertyType = acc.propertyType ?? 'house';
        _hasPool = acc.hasPool;
        _hasGarden = acc.hasGarden;
        _sharedPoolWithId = acc.sharedPoolWithId;
        _sharedGardenWithId = acc.sharedGardenWithId;
        _poolGroupNameController.text = acc.poolGroupName ?? '';
        _gardenGroupNameController.text = acc.gardenGroupName ?? '';
        _selectedColor = acc.color ?? '#3B82F6';
        _isActive = acc.isActive;
        _isLoadingData = false;
      });
    } catch (e) {
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _error = l10n.couldNotLoadAccommodation;
        _isLoadingData = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? l10n.editAccommodation : l10n.newAccommodation),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _buildForm(),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveAccommodation,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(isEditing ? l10n.save : l10n.createAccommodation),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    final l10n = AppLocalizations.of(context)!;
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // General info section
          _buildSectionHeader(l10n.generalInfo, Icons.home),
          const SizedBox(height: 12),

          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: l10n.nameRequired,
              hintText: l10n.accommodationNameExample,
              border: const OutlineInputBorder(),
            ),
            validator: (v) => v?.isEmpty == true ? l10n.nameIsRequired : null,
          ),
          const SizedBox(height: 16),

          // Property type dropdown
          DropdownButtonFormField<String>(
            value: _propertyType,
            decoration: InputDecoration(
              labelText: l10n.type,
              border: const OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(value: 'house', child: Text(l10n.houseLabel)),
              DropdownMenuItem(value: 'apartment', child: Text(l10n.apartment)),
              DropdownMenuItem(value: 'villa', child: Text(l10n.villa)),
              DropdownMenuItem(value: 'cabin', child: Text(l10n.cabinLabel)),
              DropdownMenuItem(value: 'studio', child: Text(l10n.studio)),
            ],
            onChanged: (v) => setState(() => _propertyType = v!),
          ),
          const SizedBox(height: 16),

          // Capacity
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _maxGuestsController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: l10n.maxGuestsRequired,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.people),
                  ),
                  validator: (v) => v?.isEmpty == true ? l10n.required : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _bedroomsController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: l10n.bedrooms,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.bed),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _bathroomsController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: l10n.bathrooms,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.bathtub),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Color picker
          _buildColorPicker(l10n),
          const SizedBox(height: 16),

          // Active switch
          SwitchListTile(
            title: Text(l10n.active),
            subtitle: Text(l10n.accommodationAvailableForBookings),
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
            contentPadding: EdgeInsets.zero,
          ),

          // Pool / Garden toggles - per-accommodation
          SwitchListTile(
            secondary: const Icon(Icons.pool_outlined),
            title: Text(l10n.onboardingHasPool),
            value: _hasPool,
            onChanged: (v) => setState(() {
              _hasPool = v;
              if (!v) _sharedPoolWithId = null;
            }),
            contentPadding: EdgeInsets.zero,
          ),
          if (_hasPool && _otherPoolOwners.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 56, bottom: 8),
              child: DropdownButtonFormField<int?>(
                value: _sharedPoolWithId,
                decoration: InputDecoration(
                  labelText: l10n.onboardingSharedPool,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  DropdownMenuItem<int?>(
                    value: null,
                    child: Text(l10n.onboardingSharedOwn),
                  ),
                  ..._otherPoolOwners.map((a) => DropdownMenuItem<int?>(
                        value: a.id,
                        child: Text(a.name, overflow: TextOverflow.ellipsis),
                      )),
                ],
                onChanged: (v) =>
                    setState(() => _sharedPoolWithId = v),
              ),
            ),
          // Group name only relevant when this accommodation is the
          // pool "owner" (not sharing with another).
          if (_hasPool && _sharedPoolWithId == null)
            Padding(
              padding: const EdgeInsets.only(left: 56, bottom: 8),
              child: TextFormField(
                controller: _poolGroupNameController,
                decoration: InputDecoration(
                  labelText: l10n.poolGroupName,
                  helperText: l10n.poolGroupNameHelp,
                  isDense: true,
                ),
              ),
            ),
          SwitchListTile(
            secondary: const Icon(Icons.yard_outlined),
            title: Text(l10n.onboardingHasGarden),
            value: _hasGarden,
            onChanged: (v) => setState(() {
              _hasGarden = v;
              if (!v) _sharedGardenWithId = null;
            }),
            contentPadding: EdgeInsets.zero,
          ),
          if (_hasGarden && _otherGardenOwners.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 56, bottom: 8),
              child: DropdownButtonFormField<int?>(
                value: _sharedGardenWithId,
                decoration: InputDecoration(
                  labelText: l10n.onboardingSharedGarden,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  DropdownMenuItem<int?>(
                    value: null,
                    child: Text(l10n.onboardingSharedOwn),
                  ),
                  ..._otherGardenOwners.map((a) => DropdownMenuItem<int?>(
                        value: a.id,
                        child: Text(a.name, overflow: TextOverflow.ellipsis),
                      )),
                ],
                onChanged: (v) =>
                    setState(() => _sharedGardenWithId = v),
              ),
            ),
          if (_hasGarden && _sharedGardenWithId == null)
            Padding(
              padding: const EdgeInsets.only(left: 56, bottom: 8),
              child: TextFormField(
                controller: _gardenGroupNameController,
                decoration: InputDecoration(
                  labelText: l10n.gardenGroupName,
                  helperText: l10n.gardenGroupNameHelp,
                  isDense: true,
                ),
              ),
            ),

          const SizedBox(height: 24),

          // Photos section
          _buildSectionHeader('Foto\'s', Icons.photo_library),
          const SizedBox(height: 12),
          _buildPhotosSection(),

          const SizedBox(height: 24),

          // Pricing section
          _buildSectionHeader(l10n.pricesPerWeek, Icons.euro),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _priceLowController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.lowSeason,
                    border: const OutlineInputBorder(),
                    prefixText: ' ',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _priceMidController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.midSeasonShort,
                    border: const OutlineInputBorder(),
                    prefixText: ' ',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _priceHighController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.highSeason,
                    border: const OutlineInputBorder(),
                    prefixText: ' ',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _cleaningFeeController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.cleaningFee,
              border: const OutlineInputBorder(),
              prefixText: ' ',
            ),
          ),

          const SizedBox(height: 24),

          // Location section
          _buildSectionHeader(l10n.location, Icons.location_on),
          const SizedBox(height: 12),

          TextFormField(
            controller: _addressController,
            decoration: InputDecoration(
              labelText: l10n.address,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _cityController,
            decoration: InputDecoration(
              labelText: l10n.city,
              border: const OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 24),

          // Check-in/out section
          _buildSectionHeader(l10n.checkInCheckOut, Icons.access_time),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _checkinFromController,
                  decoration: InputDecoration(
                    labelText: l10n.checkInFrom,
                    border: const OutlineInputBorder(),
                    hintText: '15:00',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _checkinUntilController,
                  decoration: InputDecoration(
                    labelText: l10n.checkInUntil,
                    border: const OutlineInputBorder(),
                    hintText: '20:00',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _checkoutController,
                  decoration: InputDecoration(
                    labelText: l10n.checkOut,
                    border: const OutlineInputBorder(),
                    hintText: '10:00',
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // WiFi & Access section
          _buildSectionHeader(l10n.wifiAndAccess, Icons.wifi),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _wifiNetworkController,
                  decoration: InputDecoration(
                    labelText: l10n.wifiNetwork,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _wifiPasswordController,
                  decoration: InputDecoration(
                    labelText: l10n.wifiPassword,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _alarmCodeController,
            decoration: InputDecoration(
              labelText: l10n.alarmCodeKeybox,
              border: const OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 24),

          // iCal section
          _buildSectionHeader(l10n.calendarSync, Icons.sync),
          const SizedBox(height: 12),

          TextFormField(
            controller: _icalAirbnbController,
            decoration: InputDecoration(
              labelText: l10n.icalAirbnb,
              border: const OutlineInputBorder(),
              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5A5F).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.house, color: Color(0xFFFF5A5F), size: 20),
              ),
              hintText: 'https://www.airbnb.com/calendar/ical/...',
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _icalBookingController,
            decoration: InputDecoration(
              labelText: l10n.icalBooking,
              border: const OutlineInputBorder(),
              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF003580).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.hotel, color: Color(0xFF003580), size: 20),
              ),
              hintText: 'https://admin.booking.com/...',
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _icalVrboController,
            decoration: InputDecoration(
              labelText: l10n.icalVrbo,
              helperText: l10n.vrboHelperText,
              border: const OutlineInputBorder(),
              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B5998).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.villa, color: Color(0xFF3B5998), size: 20),
              ),
              hintText: 'https://www.vrbo.com/...',
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _icalGoogleController,
            decoration: InputDecoration(
              labelText: l10n.icalGoogle,
              helperText: l10n.googleHelperText,
              border: const OutlineInputBorder(),
              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4285F4).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.travel_explore, color: Color(0xFF4285F4), size: 20),
              ),
              hintText: 'https://...',
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _icalHoliduController,
            decoration: InputDecoration(
              labelText: l10n.icalHolidu,
              helperText: l10n.holiduHelperText,
              border: const OutlineInputBorder(),
              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00B4AB).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.search, color: Color(0xFF00B4AB), size: 20),
              ),
              hintText: 'https://www.holidu.com/...',
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _icalBelvillaController,
            decoration: InputDecoration(
              labelText: l10n.icalBelvilla,
              helperText: l10n.belvillaHelperText,
              border: const OutlineInputBorder(),
              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE85D04).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.beach_access, color: Color(0xFFE85D04), size: 20),
              ),
              hintText: 'https://www.belvilla.com/...',
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _icalOtherController,
            decoration: InputDecoration(
              labelText: l10n.otherIcalUrl,
              helperText: l10n.otherIcalHelperText,
              border: const OutlineInputBorder(),
              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.link, color: Colors.grey[600], size: 20),
              ),
              hintText: 'https://...',
            ),
          ),

          if (_accommodation?.icalExportUrl != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.download, color: Colors.green[700], size: 18),
                      const SizedBox(width: 8),
                      Text(
                        l10n.exportUrlLabel,
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[800]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _accommodation!.icalExportUrl!,
                    style: TextStyle(fontSize: 12, color: Colors.green[700]),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // House rules section
          _buildSectionHeader(l10n.houseRulesAndInstructions, Icons.rule),
          const SizedBox(height: 12),

          TextFormField(
            controller: _houseRulesController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: l10n.houseRules,
              border: const OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _arrivalController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: l10n.arrivalInstructions,
              border: const OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),

          const SizedBox(height: 80), // Space for bottom button
        ],
      ),
    );
  }

  Future<void> _pickAndUploadPhoto() async {
    if (!isEditing || widget.accommodationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sla de accommodatie eerst op voordat je foto\'s toevoegt.')),
      );
      return;
    }

    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2400,
      maxHeight: 2400,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _photoUploading = true);
    try {
      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(
          picked.path,
          filename: picked.name,
        ),
      });
      final response = await ApiClient.instance.post(
        '${ApiConfig.accommodations}/${widget.accommodationId}/photos',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      setState(() {
        _photos.add(Map<String, dynamic>.from(response.data as Map));
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload mislukt: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _photoUploading = false);
    }
  }

  Future<void> _deletePhoto(int photoId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Foto verwijderen?'),
        content: const Text('Deze actie kan niet ongedaan gemaakt worden.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuleren')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Verwijderen'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ApiClient.instance.delete(
        '${ApiConfig.accommodations}/${widget.accommodationId}/photos/$photoId',
      );
      setState(() => _photos.removeWhere((p) => p['id'] == photoId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verwijderen mislukt: $e')),
        );
      }
    }
  }

  Widget _buildPhotosSection() {
    if (!isEditing) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Sla de accommodatie eerst op om foto\'s toe te voegen.',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _photos.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == _photos.length) {
            return _buildAddPhotoTile();
          }
          final photo = _photos[index];
          return _buildPhotoTile(photo);
        },
      ),
    );
  }

  Widget _buildAddPhotoTile() {
    return InkWell(
      onTap: _photoUploading ? null : _pickAndUploadPhoto,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.4),
            style: BorderStyle.solid,
            width: 1.5,
          ),
        ),
        child: Center(
          child: _photoUploading
              ? const CircularProgressIndicator(strokeWidth: 2)
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo,
                        color: AppTheme.primaryColor, size: 28),
                    const SizedBox(height: 6),
                    Text(
                      'Foto\ntoevoegen',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildPhotoTile(Map<String, dynamic> photo) {
    final url = photo['url'] as String? ?? '';
    final id = photo['id'] as int?;
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: url,
            width: 110,
            height: 110,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              width: 110,
              height: 110,
              color: Colors.grey[200],
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            errorWidget: (_, __, ___) => Container(
              width: 110,
              height: 110,
              color: Colors.grey[200],
              child: Icon(Icons.broken_image, color: Colors.grey[500]),
            ),
          ),
        ),
        if (id != null)
          Positioned(
            top: 4,
            right: 4,
            child: Material(
              color: Colors.black54,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _deletePhoto(id),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildColorPicker(AppLocalizations l10n) {
    final colors = [
      '#3B82F6', // Blue
      '#10B981', // Green
      '#F59E0B', // Orange
      '#EF4444', // Red
      '#8B5CF6', // Purple
      '#EC4899', // Pink
      '#06B6D4', // Cyan
      '#84CC16', // Lime
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.color, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          children: colors.map((color) {
            final isSelected = _selectedColor == color;
            return GestureDetector(
              onTap: () => setState(() => _selectedColor = color),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _parseColor(color),
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: Colors.black, width: 3)
                      : null,
                  boxShadow: isSelected
                      ? [BoxShadow(color: Colors.black26, blurRadius: 4)]
                      : null,
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.substring(1), radix: 16) + 0xFF000000);
    } catch (e) {
      return AppTheme.primaryColor;
    }
  }

  Future<void> _saveAccommodation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final data = {
        'name': _nameController.text.trim(),
        'property_type': _propertyType,
        'max_guests': int.tryParse(_maxGuestsController.text) ?? 4,
        'bedrooms': int.tryParse(_bedroomsController.text),
        'bathrooms': int.tryParse(_bathroomsController.text),
        'base_price_low': double.tryParse(_priceLowController.text),
        'base_price_mid': double.tryParse(_priceMidController.text),
        'base_price_high': double.tryParse(_priceHighController.text),
        'cleaning_fee': double.tryParse(_cleaningFeeController.text),
        'has_pool': _hasPool,
        'has_garden': _hasGarden,
        'shared_pool_with_id': _hasPool ? _sharedPoolWithId : null,
        'shared_garden_with_id': _hasGarden ? _sharedGardenWithId : null,
        'pool_group_name': (_hasPool && _sharedPoolWithId == null &&
                _poolGroupNameController.text.trim().isNotEmpty)
            ? _poolGroupNameController.text.trim()
            : null,
        'garden_group_name': (_hasGarden && _sharedGardenWithId == null &&
                _gardenGroupNameController.text.trim().isNotEmpty)
            ? _gardenGroupNameController.text.trim()
            : null,
        'address': _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
        'city': _cityController.text.trim().isNotEmpty ? _cityController.text.trim() : null,
        'wifi_network': _wifiNetworkController.text.trim().isNotEmpty ? _wifiNetworkController.text.trim() : null,
        'wifi_password': _wifiPasswordController.text.trim().isNotEmpty ? _wifiPasswordController.text.trim() : null,
        'alarm_code': _alarmCodeController.text.trim().isNotEmpty ? _alarmCodeController.text.trim() : null,
        'checkin_time_from': _checkinFromController.text.trim().isNotEmpty ? _checkinFromController.text.trim() : null,
        'checkin_time_until': _checkinUntilController.text.trim().isNotEmpty ? _checkinUntilController.text.trim() : null,
        'checkout_time': _checkoutController.text.trim().isNotEmpty ? _checkoutController.text.trim() : null,
        'house_rules': _houseRulesController.text.trim().isNotEmpty ? _houseRulesController.text.trim() : null,
        'arrival_instructions': _arrivalController.text.trim().isNotEmpty ? _arrivalController.text.trim() : null,
        'color': _selectedColor,
        'is_active': _isActive,
        'ical_airbnb_url': _icalAirbnbController.text.trim().isNotEmpty ? _icalAirbnbController.text.trim() : null,
        'ical_booking_url': _icalBookingController.text.trim().isNotEmpty ? _icalBookingController.text.trim() : null,
        'ical_vrbo_url': _icalVrboController.text.trim().isNotEmpty ? _icalVrboController.text.trim() : null,
        'ical_google_url': _icalGoogleController.text.trim().isNotEmpty ? _icalGoogleController.text.trim() : null,
        'ical_holidu_url': _icalHoliduController.text.trim().isNotEmpty ? _icalHoliduController.text.trim() : null,
        'ical_belvilla_url': _icalBelvillaController.text.trim().isNotEmpty ? _icalBelvillaController.text.trim() : null,
        'ical_other_url': _icalOtherController.text.trim().isNotEmpty ? _icalOtherController.text.trim() : null,
      };

      if (isEditing) {
        await ApiClient.instance.put('${ApiConfig.accommodations}/${widget.accommodationId}', data: data);
      } else {
        await ApiClient.instance.post(ApiConfig.accommodations, data: data);
      }

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEditing ? l10n.accommodationUpdated : l10n.accommodationCreated)),
        );
        context.pop(true); // Return true to indicate changes were made
      }
    } on DioException catch (e) {
      if (!mounted) return;
      // Free-tier limit reached → friendly dialog with Upgrade CTA
      // instead of a raw "Error: 403" snackbar.
      final data = e.response?.data;
      if (e.response?.statusCode == 403 &&
          data is Map &&
          data['upgrade_required'] == true) {
        _showUpgradeDialog(
          data['message']?.toString() ??
              'Je hebt het maximale aantal accommodaties bereikt '
                  'voor het gratis abonnement.',
        );
      } else {
        final l10n = AppLocalizations.of(context)!;
        final msg = (data is Map && data['message'] is String)
            ? data['message'] as String
            : '$e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: $msg')),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showUpgradeDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.star_rounded, color: Colors.amber[700], size: 40),
        title: const Text('Limiet gratis abonnement bereikt'),
        content: Text(
          '$message\n\nUpgrade naar Premium voor onbeperkt accommodaties, '
          'boekingen en teamleden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Later'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/subscription');
            },
            icon: const Icon(Icons.rocket_launch),
            label: const Text('Bekijk Premium'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteAccommodationConfirm),
        content: Text(l10n.deleteAccommodationMessage(_nameController.text)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAccommodation();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccommodation() async {
    setState(() => _isLoading = true);

    try {
      await ApiClient.instance.delete('${ApiConfig.accommodations}/${widget.accommodationId}');

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.accommodationDeleted)),
        );
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.deleteError}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
