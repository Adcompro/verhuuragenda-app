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
  static const int _totalSteps = 4;

  // Form data
  final _basicsFormKey = GlobalKey<FormState>();
  final _capacityFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _maxGuestsController = TextEditingController(text: '4');
  final _bedroomsController = TextEditingController(text: '2');
  final _bathroomsController = TextEditingController(text: '1');
  String _propertyType = 'house';

  bool _hasPool = false;
  bool _hasGarden = false;
  bool _trackCleaning = true;
  bool _trackMaintenance = true;

  bool _submitting = false;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _cityController.dispose();
    _maxGuestsController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentStep == 1 &&
        !(_basicsFormKey.currentState?.validate() ?? false)) {
      return;
    }
    if (_currentStep == 2 &&
        !(_capacityFormKey.currentState?.validate() ?? false)) {
      return;
    }
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
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

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _submitting = true);

    try {
      await ApiClient.instance.post(ApiConfig.accommodations, data: {
        'name': _nameController.text.trim(),
        'property_type': _propertyType,
        'max_guests': int.parse(_maxGuestsController.text),
        'bedrooms': int.parse(_bedroomsController.text),
        'bathrooms': int.parse(_bathroomsController.text),
        if (_cityController.text.trim().isNotEmpty)
          'city': _cityController.text.trim(),
        'is_active': true,
      });

      // Apply module visibility based on choices
      final modules = ref.read(moduleVisibilityProvider.notifier);
      await modules.setEnabled(AppModule.pool, _hasPool);
      await modules.setEnabled(AppModule.garden, _hasGarden);
      await modules.setEnabled(AppModule.cleaning, _trackCleaning);
      await modules.setEnabled(AppModule.maintenance, _trackMaintenance);

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
                  _buildModulesStep(l10n),
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
    final isLast = _currentStep == _totalSteps - 1;

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
              onPressed: _submitting ? null : (isLast ? _submit : _next),
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
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
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
                size: 64, color: Colors.white),
          ),
          const SizedBox(height: 32),
          Text(
            l10n.onboardingWelcomeTitle,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.onboardingWelcomeMessage,
            style: TextStyle(fontSize: 16, color: Colors.grey[700], height: 1.4),
            textAlign: TextAlign.center,
          ),
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
            validator: (v) {
              if (v == null || v.isEmpty) return l10n.required;
              return null;
            },
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
            validator: (v) {
              if (v == null || v.isEmpty) return l10n.required;
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModulesStep(AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _SectionTitle(title: l10n.onboardingModulesTitle),
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
