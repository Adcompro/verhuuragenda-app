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

  // Seasons (defaults to common Dutch holiday-rental ranges of current year)
  late int _seasonYear;
  late DateTime _lowStart, _lowEnd, _midStart, _midEnd, _highStart, _highEnd;

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _seasonYear = DateTime.now().year;
    _lowStart = DateTime(_seasonYear, 1, 1);
    _lowEnd = DateTime(_seasonYear, 4, 30);
    _midStart = DateTime(_seasonYear, 5, 1);
    _midEnd = DateTime(_seasonYear, 6, 30);
    _highStart = DateTime(_seasonYear, 7, 1);
    _highEnd = DateTime(_seasonYear, 8, 31);
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

      // 2. If seasonal pricing, create the 3 seasons
      if (_pricingStrategy == 'seasonal') {
        await _createSeasonSafe('low', _lowStart, _lowEnd);
        await _createSeasonSafe('mid', _midStart, _midEnd);
        await _createSeasonSafe('high', _highStart, _highEnd);
      }

      // 3. Apply module visibility
      final modules = ref.read(moduleVisibilityProvider.notifier);
      await modules.setEnabled(AppModule.pool, _hasPool);
      await modules.setEnabled(AppModule.garden, _hasGarden);
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

  Future<void> _createSeasonSafe(
    String type,
    DateTime start,
    DateTime end,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final name = switch (type) {
      'low' => '${l10n.onboardingSeasonLow} $_seasonYear',
      'mid' => '${l10n.onboardingSeasonMid} $_seasonYear',
      'high' => '${l10n.onboardingSeasonHigh} $_seasonYear',
      _ => '$type $_seasonYear',
    };
    try {
      await ApiClient.instance.post(ApiConfig.seasons, data: {
        'name': name,
        'type': type,
        'year': _seasonYear,
        'start_date':
            '${start.year}-${_pad(start.month)}-${_pad(start.day)}',
        'end_date': '${end.year}-${_pad(end.month)}-${_pad(end.day)}',
      });
    } catch (_) {
      // Silently ignore season conflicts; user can fix in Seasons screen later.
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
          const SizedBox(height: 24),
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
          const SizedBox(height: 24),
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
          const SizedBox(height: 24),
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
        const SizedBox(height: 24),
        _SeasonRangePicker(
          icon: Icons.cloud_outlined,
          label: l10n.onboardingSeasonLow,
          start: _lowStart,
          end: _lowEnd,
          onStartTap: () async {
            final p = await _pickDate(_lowStart);
            if (p != null) setState(() => _lowStart = p);
          },
          onEndTap: () async {
            final p = await _pickDate(_lowEnd);
            if (p != null) setState(() => _lowEnd = p);
          },
          fromLabel: l10n.onboardingFrom,
          toLabel: l10n.onboardingTo,
        ),
        const SizedBox(height: 12),
        _SeasonRangePicker(
          icon: Icons.cloud_queue_outlined,
          label: l10n.onboardingSeasonMid,
          start: _midStart,
          end: _midEnd,
          onStartTap: () async {
            final p = await _pickDate(_midStart);
            if (p != null) setState(() => _midStart = p);
          },
          onEndTap: () async {
            final p = await _pickDate(_midEnd);
            if (p != null) setState(() => _midEnd = p);
          },
          fromLabel: l10n.onboardingFrom,
          toLabel: l10n.onboardingTo,
        ),
        const SizedBox(height: 12),
        _SeasonRangePicker(
          icon: Icons.wb_sunny_outlined,
          label: l10n.onboardingSeasonHigh,
          start: _highStart,
          end: _highEnd,
          onStartTap: () async {
            final p = await _pickDate(_highStart);
            if (p != null) setState(() => _highStart = p);
          },
          onEndTap: () async {
            final p = await _pickDate(_highEnd);
            if (p != null) setState(() => _highEnd = p);
          },
          fromLabel: l10n.onboardingFrom,
          toLabel: l10n.onboardingTo,
        ),
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

class _SeasonRangePicker extends StatelessWidget {
  final IconData icon;
  final String label;
  final DateTime start;
  final DateTime end;
  final VoidCallback onStartTap;
  final VoidCallback onEndTap;
  final String fromLabel;
  final String toLabel;

  const _SeasonRangePicker({
    required this.icon,
    required this.label,
    required this.start,
    required this.end,
    required this.onStartTap,
    required this.onEndTap,
    required this.fromLabel,
    required this.toLabel,
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
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DateButton(
                  label: fromLabel,
                  date: _fmt(start),
                  onTap: onStartTap,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DateButton(
                  label: toLabel,
                  date: _fmt(end),
                  onTap: onEndTap,
                ),
              ),
            ],
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
