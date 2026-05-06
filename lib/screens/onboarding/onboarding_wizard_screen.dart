import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/api_config.dart';
import '../../config/theme.dart';
import '../../core/api/api_client.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/module_visibility_provider.dart';
import '../../providers/onboarding_provider.dart';

class OnboardingWizardScreen extends ConsumerStatefulWidget {
  const OnboardingWizardScreen({super.key});

  @override
  ConsumerState<OnboardingWizardScreen> createState() =>
      _OnboardingWizardScreenState();
}

class _OnboardingWizardScreenState
    extends ConsumerState<OnboardingWizardScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Forms
  final _basicsFormKey = GlobalKey<FormState>();
  final _capacityFormKey = GlobalKey<FormState>();
  final _pricingFormKey = GlobalKey<FormState>();

  // Basics
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  String _propertyType = 'house';

  // Capacity
  final _maxGuestsController = TextEditingController(text: '4');
  final _bedroomsController = TextEditingController(text: '2');
  final _bathroomsController = TextEditingController(text: '1');

  // Features
  bool _hasPool = false;
  bool _hasGarden = false;
  bool _trackCleaning = true;
  bool _trackMaintenance = true;

  // Pricing
  String _pricingStrategy = 'seasonal'; // 'flat' | 'seasonal'
  bool _cleaningIncluded = true;
  final _flatPriceController = TextEditingController();
  final _lowPriceController = TextEditingController();
  final _midPriceController = TextEditingController();
  final _highPriceController = TextEditingController();
  final _cleaningFeeController = TextEditingController();

  // Seasons - lists of date ranges per season type (lets user
  // add e.g. two low-season periods: jan-apr and oct-dec).
  late int _seasonYear;
  late List<_DateRange> _lowRanges;
  late List<_DateRange> _midRanges;
  late List<_DateRange> _highRanges;

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _seasonYear = DateTime.now().year;
    _lowRanges = [
      _DateRange(DateTime(_seasonYear, 1, 1), DateTime(_seasonYear, 4, 30)),
    ];
    _midRanges = [
      _DateRange(DateTime(_seasonYear, 5, 1), DateTime(_seasonYear, 6, 30)),
    ];
    _highRanges = [
      _DateRange(DateTime(_seasonYear, 7, 1), DateTime(_seasonYear, 8, 31)),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _cityController.dispose();
    _maxGuestsController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _flatPriceController.dispose();
    _lowPriceController.dispose();
    _midPriceController.dispose();
    _highPriceController.dispose();
    _cleaningFeeController.dispose();
    super.dispose();
  }

  // 0=Welcome, 1=Basics, 2=Capacity, 3=Features, 4=Pricing, 5=Seasons (only if seasonal)
  int get _totalSteps => _pricingStrategy == 'seasonal' ? 6 : 5;
  bool get _isLastStep => _currentStep == _totalSteps - 1;

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 1:
        return _basicsFormKey.currentState?.validate() ?? false;
      case 2:
        return _capacityFormKey.currentState?.validate() ?? false;
      case 4:
        return _pricingFormKey.currentState?.validate() ?? false;
      default:
        return true;
    }
  }

  void _next() {
    if (!_validateCurrentStep()) return;
    if (_isLastStep) {
      _submit();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void _back() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _maybeLater() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.onboardingMaybeLater),
        content: Text(l10n.onboardingSkipMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.onboardingMaybeLater),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(onboardingDismissedProvider.notifier).dismiss();
      if (mounted) context.go('/dashboard');
    }
  }

  Future<DateTime?> _pickDate(DateTime initial) {
    final firstDate = DateTime(_seasonYear, 1, 1);
    final lastDate = DateTime(_seasonYear, 12, 31);
    return showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
    );
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _submitting = true);

    try {
      // 1. Build accommodation payload
      final data = <String, dynamic>{
        'name': _nameController.text.trim(),
        'property_type': _propertyType,
        'max_guests': int.parse(_maxGuestsController.text),
        'bedrooms': int.parse(_bedroomsController.text),
        'bathrooms': int.parse(_bathroomsController.text),
        if (_cityController.text.trim().isNotEmpty)
          'city': _cityController.text.trim(),
        'has_pool': _hasPool,
        'has_garden': _hasGarden,
        'is_active': true,
      };

      if (_pricingStrategy == 'flat') {
        final price = double.tryParse(
          _flatPriceController.text.replaceAll(',', '.'),
        );
        if (price != null) {
          data['base_price_low'] = price;
          data['base_price_mid'] = price;
          data['base_price_high'] = price;
        }
      } else {
        final low = double.tryParse(
          _lowPriceController.text.replaceAll(',', '.'),
        );
        final mid = double.tryParse(
          _midPriceController.text.replaceAll(',', '.'),
        );
        final high = double.tryParse(
          _highPriceController.text.replaceAll(',', '.'),
        );
        if (low != null) data['base_price_low'] = low;
        if (mid != null) data['base_price_mid'] = mid;
        if (high != null) data['base_price_high'] = high;
      }

      if (_cleaningIncluded) {
        data['cleaning_fee'] = 0;
      } else {
        final fee = double.tryParse(
          _cleaningFeeController.text.replaceAll(',', '.'),
        );
        if (fee != null) data['cleaning_fee'] = fee;
      }

      await ApiClient.instance.post(ApiConfig.accommodations, data: data);

      // 2. If seasonal pricing, create one season per range.
      if (_pricingStrategy == 'seasonal') {
        await _createSeasonsForType('low', _lowRanges);
        await _createSeasonsForType('mid', _midRanges);
        await _createSeasonsForType('high', _highRanges);
      }

      // 3. Apply module visibility
      final modules = ref.read(moduleVisibilityProvider.notifier);
      // Pool/garden visibility is derived from per-accommodation
      // has_pool / has_garden flags. After creating the wizard's
      // accommodation we still need to turn the tab on locally so
      // it shows up immediately without waiting for a refresh.
      if (_hasPool) await modules.setEnabled(AppModule.pool, true);
      if (_hasGarden) await modules.setEnabled(AppModule.garden, true);
      await modules.setEnabled(AppModule.cleaning, _trackCleaning);
      await modules.setEnabled(AppModule.maintenance, _trackMaintenance);

      // 4. Dismiss wizard
      await ref.read(onboardingDismissedProvider.notifier).dismiss();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.onboardingSuccessMessage),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createSeasonsForType(
    String type,
    List<_DateRange> ranges,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final baseName = switch (type) {
      'low' => l10n.onboardingSeasonLow,
      'mid' => l10n.onboardingSeasonMid,
      'high' => l10n.onboardingSeasonHigh,
      _ => type,
    };
    for (var i = 0; i < ranges.length; i++) {
      final r = ranges[i];
      final suffix = ranges.length > 1 ? ' (${i + 1})' : '';
      final name = '$baseName $_seasonYear$suffix';
      try {
        await ApiClient.instance.post(ApiConfig.seasons, data: {
          'name': name,
          'type': type,
          'year': _seasonYear,
          'start_date':
              '${r.start.year}-${_pad(r.start.month)}-${_pad(r.start.day)}',
          'end_date':
              '${r.end.year}-${_pad(r.end.month)}-${_pad(r.end.day)}',
        });
      } catch (_) {
        // Silently ignore individual conflicts; user can fix later.
      }
    }
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(l10n),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentStep = i),
                children: [
                  _buildWelcomeStep(l10n),
                  _buildBasicsStep(l10n),
                  _buildCapacityStep(l10n),
                  _buildFeaturesStep(l10n),
                  _buildPricingStep(l10n),
                  if (_pricingStrategy == 'seasonal') _buildSeasonsStep(l10n),
                ],
              ),
            ),
            _buildFooter(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / _totalSteps,
              minHeight: 4,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation(AppTheme.primaryColor),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '${_currentStep + 1} / $_totalSteps',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(AppLocalizations l10n) {
    final isFirst = _currentStep == 0;
    final isLast = _isLastStep;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (!isFirst)
              TextButton.icon(
                onPressed: _submitting ? null : _back,
                icon: const Icon(Icons.arrow_back),
                label: Text(l10n.back),
              )
            else
              TextButton(
                onPressed: _submitting ? null : _maybeLater,
                child: Text(l10n.onboardingMaybeLater),
              ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _submitting ? null : _next,
              icon: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(isLast ? Icons.check : Icons.arrow_forward),
              label: Text(
                isFirst
                    ? l10n.onboardingStart
                    : (isLast ? l10n.onboardingFinish : l10n.next),
              ),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeStep(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withOpacity(0.6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(Icons.home_work,
                size: 56, color: Colors.white),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.onboardingWelcomeTitle,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.onboardingWelcomeMessage,
            style: TextStyle(
                fontSize: 15, color: Colors.grey[700], height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bullet(l10n.onboardingWelcomeBullet1),
                _bullet(l10n.onboardingWelcomeBullet2),
                _bullet(l10n.onboardingWelcomeBullet3),
                _bullet(l10n.onboardingWelcomeBullet4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle,
              size: 18, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildBasicsStep(AppLocalizations l10n) {
    return Form(
      key: _basicsFormKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _SectionTitle(title: l10n.onboardingBasicsTitle),
          const SizedBox(height: 8),
          _SectionHint(text: l10n.onboardingBasicsHint),
          const SizedBox(height: 20),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: l10n.name,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.home_outlined),
            ),
            textInputAction: TextInputAction.next,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? l10n.required : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _propertyType,
            decoration: InputDecoration(
              labelText: l10n.type,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.category_outlined),
            ),
            items: [
              DropdownMenuItem(value: 'house', child: Text(l10n.houseLabel)),
              DropdownMenuItem(
                  value: 'apartment', child: Text(l10n.apartment)),
              DropdownMenuItem(value: 'villa', child: Text(l10n.villa)),
              DropdownMenuItem(value: 'cabin', child: Text(l10n.cabinLabel)),
              DropdownMenuItem(value: 'studio', child: Text(l10n.studio)),
            ],
            onChanged: (v) => setState(() => _propertyType = v ?? 'house'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _cityController,
            decoration: InputDecoration(
              labelText: l10n.city,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.place_outlined),
            ),
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
    );
  }

  Widget _buildCapacityStep(AppLocalizations l10n) {
    return Form(
      key: _capacityFormKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _SectionTitle(title: l10n.onboardingCapacityTitle),
          const SizedBox(height: 8),
          _SectionHint(text: l10n.onboardingCapacityHint),
          const SizedBox(height: 20),
          TextFormField(
            controller: _maxGuestsController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: l10n.maxGuests,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.people_outline),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return l10n.required;
              final n = int.tryParse(v);
              if (n == null || n < 1) return l10n.required;
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _bedroomsController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: l10n.bedrooms,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.bed_outlined),
            ),
            validator: (v) =>
                (v == null || v.isEmpty) ? l10n.required : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _bathroomsController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: l10n.bathrooms,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.bathtub_outlined),
            ),
            validator: (v) =>
                (v == null || v.isEmpty) ? l10n.required : null,
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesStep(AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _SectionTitle(title: l10n.onboardingFeaturesTitle),
        const SizedBox(height: 8),
        Text(
          l10n.onboardingModulesHint,
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),
        _ModuleSwitch(
          icon: Icons.pool_outlined,
          label: l10n.onboardingHasPool,
          value: _hasPool,
          onChanged: (v) => setState(() => _hasPool = v),
        ),
        _ModuleSwitch(
          icon: Icons.yard_outlined,
          label: l10n.onboardingHasGarden,
          value: _hasGarden,
          onChanged: (v) => setState(() => _hasGarden = v),
        ),
        const Divider(height: 32),
        _ModuleSwitch(
          icon: Icons.cleaning_services_outlined,
          label: l10n.onboardingTrackCleaning,
          value: _trackCleaning,
          onChanged: (v) => setState(() => _trackCleaning = v),
        ),
        _ModuleSwitch(
          icon: Icons.build_outlined,
          label: l10n.onboardingTrackMaintenance,
          value: _trackMaintenance,
          onChanged: (v) => setState(() => _trackMaintenance = v),
        ),
      ],
    );
  }

  Widget _buildPricingStep(AppLocalizations l10n) {
    return Form(
      key: _pricingFormKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _SectionTitle(title: l10n.onboardingPricingTitle),
          const SizedBox(height: 8),
          _SectionHint(text: l10n.onboardingPricingHint),
          const SizedBox(height: 20),
          // Strategy choice
          _StrategyCard(
            icon: Icons.tag_outlined,
            title: l10n.onboardingPricingFlat,
            subtitle: l10n.onboardingPricingFlatDesc,
            selected: _pricingStrategy == 'flat',
            onTap: () => setState(() => _pricingStrategy = 'flat'),
          ),
          const SizedBox(height: 12),
          _StrategyCard(
            icon: Icons.calendar_today_outlined,
            title: l10n.onboardingPricingSeasonal,
            subtitle: l10n.onboardingPricingSeasonalDesc,
            selected: _pricingStrategy == 'seasonal',
            onTap: () => setState(() => _pricingStrategy = 'seasonal'),
          ),
          const SizedBox(height: 24),
          // Price fields
          if (_pricingStrategy == 'flat')
            _priceField(
              controller: _flatPriceController,
              label: l10n.onboardingPricePerWeek,
              icon: Icons.euro,
              l10n: l10n,
            )
          else ...[
            _priceField(
              controller: _lowPriceController,
              label: l10n.onboardingPriceLow,
              icon: Icons.cloud_outlined,
              l10n: l10n,
            ),
            const SizedBox(height: 12),
            _priceField(
              controller: _midPriceController,
              label: l10n.onboardingPriceMid,
              icon: Icons.cloud_queue_outlined,
              l10n: l10n,
            ),
            const SizedBox(height: 12),
            _priceField(
              controller: _highPriceController,
              label: l10n.onboardingPriceHigh,
              icon: Icons.wb_sunny_outlined,
              l10n: l10n,
            ),
          ],
          const SizedBox(height: 24),
          // Cleaning fee
          Text(
            l10n.onboardingCleaningTitle,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          RadioListTile<bool>(
            value: true,
            groupValue: _cleaningIncluded,
            onChanged: (v) => setState(() => _cleaningIncluded = v ?? true),
            title: Text(l10n.onboardingCleaningIncluded),
            contentPadding: EdgeInsets.zero,
            activeColor: AppTheme.primaryColor,
          ),
          RadioListTile<bool>(
            value: false,
            groupValue: _cleaningIncluded,
            onChanged: (v) => setState(() => _cleaningIncluded = v ?? false),
            title: Text(l10n.onboardingCleaningSeparate),
            contentPadding: EdgeInsets.zero,
            activeColor: AppTheme.primaryColor,
          ),
          if (!_cleaningIncluded) ...[
            const SizedBox(height: 8),
            _priceField(
              controller: _cleaningFeeController,
              label: l10n.onboardingCleaningFee,
              icon: Icons.cleaning_services_outlined,
              l10n: l10n,
              required: false,
            ),
          ],
        ],
      ),
    );
  }

  Widget _priceField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required AppLocalizations l10n,
    bool required = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      ],
      decoration: InputDecoration(
        labelText: label,
        prefixText: '€ ',
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
      ),
      validator: (v) {
        if (!required) return null;
        if (v == null || v.trim().isEmpty) return l10n.required;
        final parsed = double.tryParse(v.replaceAll(',', '.'));
        if (parsed == null || parsed < 0) return l10n.required;
        return null;
      },
    );
  }

  Widget _buildSeasonsStep(AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _SectionTitle(title: l10n.onboardingSeasonsTitle),
        const SizedBox(height: 8),
        Text(
          l10n.onboardingSeasonsHint,
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),
        _SeasonGroup(
          icon: Icons.cloud_outlined,
          label: l10n.onboardingSeasonLow,
          ranges: _lowRanges,
          onChanged: () => setState(() {}),
          pickDate: _pickDate,
          fromLabel: l10n.onboardingFrom,
          toLabel: l10n.onboardingTo,
          addLabel: l10n.onboardingAddPeriod,
        ),
        const SizedBox(height: 12),
        _SeasonGroup(
          icon: Icons.cloud_queue_outlined,
          label: l10n.onboardingSeasonMid,
          ranges: _midRanges,
          onChanged: () => setState(() {}),
          pickDate: _pickDate,
          fromLabel: l10n.onboardingFrom,
          toLabel: l10n.onboardingTo,
          addLabel: l10n.onboardingAddPeriod,
        ),
        const SizedBox(height: 12),
        _SeasonGroup(
          icon: Icons.wb_sunny_outlined,
          label: l10n.onboardingSeasonHigh,
          ranges: _highRanges,
          onChanged: () => setState(() {}),
          pickDate: _pickDate,
          fromLabel: l10n.onboardingFrom,
          toLabel: l10n.onboardingTo,
          addLabel: l10n.onboardingAddPeriod,
        ),
        const SizedBox(height: 24),
        _CoveragePanel(
          year: _seasonYear,
          lowRanges: _lowRanges,
          midRanges: _midRanges,
          highRanges: _highRanges,
          onFillGaps: _fillGapsWithLow,
          l10n: l10n,
        ),
      ],
    );
  }

  /// For each gap day not covered by any season, append a low-season
  /// range that fills that gap. Adjacent gap days are merged into a
  /// single new range.
  void _fillGapsWithLow() {
    final coverage = _YearCoverage.compute(
      year: _seasonYear,
      lowRanges: _lowRanges,
      midRanges: _midRanges,
      highRanges: _highRanges,
    );
    final gaps = coverage.gapRanges();
    if (gaps.isEmpty) return;
    setState(() {
      for (final gap in gaps) {
        _lowRanges.add(gap);
      }
    });
  }
}

class _DateRange {
  DateTime start;
  DateTime end;
  _DateRange(this.start, this.end);
}

enum _SeasonKind { low, mid, high }

/// Per-day coverage for a single year. Each day gets a list of
/// season-kinds that overlap it; gaps are days with an empty list.
class _YearCoverage {
  final int year;
  final int totalDays;
  final List<List<_SeasonKind>> daySeasons;

  _YearCoverage._(this.year, this.totalDays, this.daySeasons);

  static _YearCoverage compute({
    required int year,
    required List<_DateRange> lowRanges,
    required List<_DateRange> midRanges,
    required List<_DateRange> highRanges,
  }) {
    final isLeap = (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;
    final total = isLeap ? 366 : 365;
    final days = List<List<_SeasonKind>>.generate(total, (_) => []);

    void mark(_SeasonKind kind, List<_DateRange> ranges) {
      for (final r in ranges) {
        if (r.start.year != year || r.end.year != year) continue;
        final si = _dayOfYear(r.start) - 1;
        final ei = _dayOfYear(r.end) - 1;
        if (si < 0 || ei < 0) continue;
        for (var i = si; i <= ei && i < total; i++) {
          days[i].add(kind);
        }
      }
    }

    mark(_SeasonKind.low, lowRanges);
    mark(_SeasonKind.mid, midRanges);
    mark(_SeasonKind.high, highRanges);

    return _YearCoverage._(year, total, days);
  }

  static int _dayOfYear(DateTime d) {
    return d.difference(DateTime(d.year, 1, 1)).inDays + 1;
  }

  int get coveredDays =>
      daySeasons.where((s) => s.isNotEmpty).length;
  int get gapDays => totalDays - coveredDays;
  int get overlapDays =>
      daySeasons.where((s) => s.length > 1).length;
  bool get isFullyCovered => gapDays == 0;
  bool get hasOverlap => overlapDays > 0;

  /// Build contiguous DateRanges for all days that have no season.
  List<_DateRange> gapRanges() {
    final result = <_DateRange>[];
    int? gapStart;
    for (var i = 0; i < daySeasons.length; i++) {
      final isGap = daySeasons[i].isEmpty;
      if (isGap && gapStart == null) gapStart = i;
      if (!isGap && gapStart != null) {
        result.add(_DateRange(
          DateTime(year, 1, 1).add(Duration(days: gapStart)),
          DateTime(year, 1, 1).add(Duration(days: i - 1)),
        ));
        gapStart = null;
      }
    }
    if (gapStart != null) {
      result.add(_DateRange(
        DateTime(year, 1, 1).add(Duration(days: gapStart)),
        DateTime(year, 1, 1).add(Duration(days: daySeasons.length - 1)),
      ));
    }
    return result;
  }
}

class _CoveragePanel extends StatelessWidget {
  final int year;
  final List<_DateRange> lowRanges;
  final List<_DateRange> midRanges;
  final List<_DateRange> highRanges;
  final VoidCallback onFillGaps;
  final AppLocalizations l10n;

  const _CoveragePanel({
    required this.year,
    required this.lowRanges,
    required this.midRanges,
    required this.highRanges,
    required this.onFillGaps,
    required this.l10n,
  });

  static const _lowColor = Color(0xFF60A5FA);
  static const _midColor = Color(0xFFFBBF24);
  static const _highColor = Color(0xFFEF4444);
  static const _gapColor = Color(0xFFE5E7EB);
  static const _overlapColor = Color(0xFF7C3AED);

  Color _colorForDay(List<_SeasonKind> kinds) {
    if (kinds.isEmpty) return _gapColor;
    if (kinds.length > 1) return _overlapColor;
    switch (kinds.first) {
      case _SeasonKind.low:
        return _lowColor;
      case _SeasonKind.mid:
        return _midColor;
      case _SeasonKind.high:
        return _highColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cov = _YearCoverage.compute(
      year: year,
      lowRanges: lowRanges,
      midRanges: midRanges,
      highRanges: highRanges,
    );
    final dayColors =
        cov.daySeasons.map(_colorForDay).toList(growable: false);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today,
                  size: 18, color: Colors.grey[700]),
              const SizedBox(width: 8),
              Text(
                '${l10n.onboardingCoverageTitle} $year',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 22,
              child: CustomPaint(
                painter: _CoveragePainter(dayColors),
                size: Size.infinite,
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Month markers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D']
                .map((m) => Text(m,
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey[500],
                    )))
                .toList(),
          ),
          const SizedBox(height: 12),
          // Legend
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _LegendDot(color: _lowColor, label: l10n.onboardingSeasonLow),
              _LegendDot(color: _midColor, label: l10n.onboardingSeasonMid),
              _LegendDot(color: _highColor, label: l10n.onboardingSeasonHigh),
              if (cov.hasOverlap)
                _LegendDot(
                    color: _overlapColor,
                    label: l10n.onboardingCoverageOverlapLabel),
              if (cov.gapDays > 0)
                _LegendDot(
                    color: _gapColor,
                    label: l10n.onboardingCoverageGapLabel),
            ],
          ),
          const SizedBox(height: 12),
          // Stats
          if (cov.isFullyCovered && !cov.hasOverlap)
            Row(
              children: [
                Icon(Icons.check_circle,
                    color: Colors.green.shade600, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.onboardingCoverageOk,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            )
          else ...[
            if (cov.gapDays > 0)
              Row(
                children: [
                  Icon(Icons.error_outline,
                      color: Colors.orange.shade700, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.onboardingCoverageMissing(cov.gapDays),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            if (cov.hasOverlap) ...[
              if (cov.gapDays > 0) const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.warning_amber_outlined,
                      color: Colors.orange.shade700, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.onboardingCoverageOverlap(cov.overlapDays),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (cov.gapDays > 0) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onFillGaps,
                  icon: const Icon(Icons.auto_fix_high, size: 18),
                  label: Text(l10n.onboardingFillGaps),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _CoveragePainter extends CustomPainter {
  final List<Color> dayColors;
  _CoveragePainter(this.dayColors);

  @override
  void paint(Canvas canvas, Size size) {
    if (dayColors.isEmpty) return;
    final dayWidth = size.width / dayColors.length;
    final paint = Paint();
    for (var i = 0; i < dayColors.length; i++) {
      paint.color = dayColors[i];
      canvas.drawRect(
        Rect.fromLTWH(i * dayWidth, 0, dayWidth + 0.5, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CoveragePainter old) {
    if (old.dayColors.length != dayColors.length) return true;
    for (var i = 0; i < dayColors.length; i++) {
      if (old.dayColors[i].value != dayColors[i].value) return true;
    }
    return false;
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey[700])),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
    );
  }
}

class _SectionHint extends StatelessWidget {
  final String text;
  const _SectionHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.4),
    );
  }
}

class _ModuleSwitch extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ModuleSwitch({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Text(label),
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppTheme.primaryColor),
      ),
      activeColor: AppTheme.primaryColor,
      contentPadding: EdgeInsets.zero,
    );
  }
}

class _StrategyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _StrategyCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryColor.withOpacity(0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppTheme.primaryColor
                : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: selected ? AppTheme.primaryColor : Colors.grey[700],
                size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? AppTheme.primaryColor
                          : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: selected ? AppTheme.primaryColor : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}

class _SeasonGroup extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<_DateRange> ranges;
  final VoidCallback onChanged;
  final Future<DateTime?> Function(DateTime) pickDate;
  final String fromLabel;
  final String toLabel;
  final String addLabel;

  const _SeasonGroup({
    required this.icon,
    required this.label,
    required this.ranges,
    required this.onChanged,
    required this.pickDate,
    required this.fromLabel,
    required this.toLabel,
    required this.addLabel,
  });

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryColor, size: 22),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          ...ranges.asMap().entries.map((entry) {
            final i = entry.key;
            final r = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: _DateButton(
                      label: fromLabel,
                      date: _fmt(r.start),
                      onTap: () async {
                        final p = await pickDate(r.start);
                        if (p != null) {
                          r.start = p;
                          onChanged();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _DateButton(
                      label: toLabel,
                      date: _fmt(r.end),
                      onTap: () async {
                        final p = await pickDate(r.end);
                        if (p != null) {
                          r.end = p;
                          onChanged();
                        }
                      },
                    ),
                  ),
                  if (ranges.length > 1)
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      color: Colors.red.shade400,
                      tooltip: 'Verwijderen',
                      onPressed: () {
                        ranges.removeAt(i);
                        onChanged();
                      },
                    ),
                ],
              ),
            );
          }),
          TextButton.icon(
            onPressed: () {
              // Default: 1 day after the last range's end
              final last = ranges.last.end;
              final start = last.add(const Duration(days: 1));
              final end = DateTime(
                start.year,
                start.month,
                start.day + 30,
              );
              ranges.add(_DateRange(start, end));
              onChanged();
            },
            icon: const Icon(Icons.add, size: 18),
            label: Text(addLabel),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final String date;
  final VoidCallback onTap;

  const _DateButton({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
            const SizedBox(height: 2),
            Text(
              date,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
