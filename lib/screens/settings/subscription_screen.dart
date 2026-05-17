import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../config/theme.dart';
import '../../config/api_config.dart';
import '../../core/api/api_client.dart';
import '../../services/apple_iap_service.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic> _subscription = {};
  Map<String, dynamic> _limits = {};

  // IAP state
  bool _iapInitialized = false;
  String? _purchasingProductId; // Track which product is being purchased
  bool _isRestoring = false;
  String? _purchaseError;
  List<ProductDetails> _iapProducts = [];

  /// Set by Codemagic's screenshot pipeline (--dart-define=SCREENSHOT_MODE=true)
  /// so the App Review screenshot looks like real production UI (with
  /// prices, auto-renew disclosure and EULA/Privacy links) instead of
  /// the "loading from App Store…" fallback that StoreKit shows in a
  /// plain simulator. Never enabled in TestFlight or release builds.
  static const bool _screenshotMode = bool.fromEnvironment(
    'SCREENSHOT_MODE',
    defaultValue: false,
  );

  @override
  void initState() {
    super.initState();
    _loadSubscription();
    _initializeIAP();
  }

  @override
  void dispose() {
    AppleIAPService.instance.onPurchaseUpdate = null;
    super.dispose();
  }

  Future<void> _initializeIAP() async {
    if (!Platform.isIOS) return;

    try {
      await AppleIAPService.instance.initialize();
      AppleIAPService.instance.onPurchaseUpdate = _handlePurchaseResult;

      if (mounted) {
        setState(() {
          _iapInitialized = AppleIAPService.instance.isAvailable;
          _iapProducts = AppleIAPService.instance.products;
        });
      }
    } catch (e) {
      debugPrint('IAP initialization error: $e');
    }
  }

  void _handlePurchaseResult(PurchaseResult result) {
    if (!mounted) return;

    setState(() {
      _purchasingProductId = null;
      _isRestoring = false;
      _purchaseError = result.error;
    });

    if (result.success) {
      // Refresh subscription data
      _loadSubscription();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Abonnement geactiveerd!'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (result.isPending) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Aankoop wordt verwerkt...'),
          backgroundColor: Colors.orange,
        ),
      );
    } else if (!result.isCanceled && result.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _purchaseProduct(String productId) async {
    setState(() {
      _purchasingProductId = productId;
      _purchaseError = null;
    });

    await AppleIAPService.instance.purchaseSubscription(productId);
  }

  Future<void> _restorePurchases() async {
    setState(() {
      _isRestoring = true;
      _purchaseError = null;
    });

    await AppleIAPService.instance.restorePurchases();

    // Give it some time, then reset loading state if no result
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _isRestoring) {
        setState(() => _isRestoring = false);
      }
    });
  }

  Future<void> _loadSubscription() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final responses = await Future.wait([
        ApiClient.instance.get(ApiConfig.subscription),
        ApiClient.instance.get('${ApiConfig.subscription}/limits'),
      ]);

      setState(() {
        _subscription = responses[0].data is Map
            ? Map<String, dynamic>.from(responses[0].data)
            : {};
        _limits = responses[1].data is Map
            ? Map<String, dynamic>.from(responses[1].data)
            : {};
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Kon abonnementsgegevens niet laden';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.subscription),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _loadSubscription,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSubscriptionCard(),
                        const SizedBox(height: 24),
                        _buildLimitsCard(),
                        const SizedBox(height: 24),
                        _buildPaymentSection(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildError() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSubscription,
              child: Text(l10n.tryAgain),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard() {
    final l10n = AppLocalizations.of(context)!;
    // API field names
    final isPremium = _subscription['is_premium'] == true;
    final isOnTrial = _subscription['is_on_trial'] == true;
    final subscriptionEndsAt = _subscription['subscription_ends_at'];
    final trialEndsAt = _subscription['trial_ends_at'];
    final trialDaysRemaining = _subscription['trial_days_remaining'];

    // Determine plan name and colors
    String planName;
    String statusText;
    List<Color> gradientColors;
    Color statusBgColor;

    if (isPremium) {
      planName = l10n.planPremium;
      statusText = l10n.active;
      gradientColors = [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)];
      statusBgColor = Colors.white24;
    } else if (isOnTrial) {
      planName = l10n.planPremiumTrial;
      statusText = l10n.trialPeriod;
      gradientColors = [Colors.purple[600]!, Colors.purple[400]!];
      statusBgColor = Colors.white24;
    } else {
      // Free plan - this is a valid permanent plan!
      planName = l10n.planFree;
      statusText = l10n.active;
      gradientColors = [Colors.teal[600]!, Colors.teal[400]!];
      statusBgColor = Colors.white24;
    }

    // Determine expiry date and days remaining (only for premium/trial)
    DateTime? expiryDate;
    int daysRemaining = 0;

    if (isPremium && subscriptionEndsAt != null) {
      expiryDate = DateTime.tryParse(subscriptionEndsAt);
      if (expiryDate != null) {
        daysRemaining = expiryDate.difference(DateTime.now()).inDays;
        if (daysRemaining < 0) daysRemaining = 0;
      }
    } else if (isOnTrial && trialEndsAt != null) {
      expiryDate = DateTime.tryParse(trialEndsAt);
      daysRemaining = trialDaysRemaining ?? 0;
    }

    return Card(
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.currentPlan,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      planName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            // Show free plan features
            if (!isPremium && !isOnTrial) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Inbegrepen:',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildFeatureRow(Icons.home, l10n.oneAccommodation),
                    _buildFeatureRow(Icons.calendar_today, l10n.tenBookingsPerYear),
                    _buildFeatureRow(Icons.sync, l10n.icalSync),
                    _buildFeatureRow(Icons.person, l10n.guestPortal),
                  ],
                ),
              ),
            ],
            // Show trial/premium expiry info
            if ((isPremium || isOnTrial) && expiryDate != null) ...[
              const SizedBox(height: 24),
              const Divider(color: Colors.white30),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isOnTrial ? l10n.trialEnds : l10n.validUntil,
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(expiryDate),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Dagen resterend',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$daysRemaining dagen',
                          style: TextStyle(
                            color: daysRemaining < 30 ? Colors.amber[200] : Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            // Warning for expiring subscriptions
            if ((isPremium || isOnTrial) && daysRemaining > 0 && daysRemaining < 30) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber[400]!.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.amber[200]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isOnTrial
                            ? 'Je proefperiode verloopt binnenkort. Upgrade naar Premium!'
                            : 'Je abonnement verloopt binnenkort. Verleng op tijd.',
                        style: TextStyle(color: Colors.amber[100], fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white70),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitsCard() {
    // API returns nested structure: limits.accommodations.used, etc.
    final limitsData = _limits['limits'] as Map<String, dynamic>? ?? {};
    final isPremium = _limits['is_premium'] == true;

    final accommodations = limitsData['accommodations'] as Map<String, dynamic>? ?? {};
    final bookings = limitsData['bookings_per_year'] as Map<String, dynamic>? ?? {};
    final users = limitsData['users'] as Map<String, dynamic>? ?? {};

    final accommodationsUsed = accommodations['used'] ?? 0;
    final accommodationsLimit = accommodations['limit'];
    final bookingsUsed = bookings['used'] ?? 0;
    final bookingsLimit = bookings['limit'];
    final usersUsed = users['used'] ?? 0;
    final usersLimit = users['limit'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.analytics, color: AppTheme.primaryColor),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Gebruik & Limieten',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildLimitItem(
              'Accommodaties',
              accommodationsUsed,
              accommodationsLimit,
              Icons.home,
            ),
            const SizedBox(height: 16),
            _buildLimitItem(
              'Boekingen dit jaar',
              bookingsUsed,
              bookingsLimit,
              Icons.calendar_today,
            ),
            const SizedBox(height: 16),
            _buildLimitItem(
              'Teamleden',
              usersUsed,
              usersLimit,
              Icons.people,
            ),
            if (!isPremium) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.star, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Upgrade naar Premium voor onbeperkt gebruik!',
                        style: TextStyle(color: Colors.blue[800], fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLimitItem(String label, int used, dynamic limit, IconData icon) {
    final isUnlimited = limit == null;
    final limitInt = limit is int ? limit : 0;
    final percentage = isUnlimited ? 0.0 : (used / limitInt).clamp(0.0, 1.0);
    final isNearLimit = percentage > 0.8;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Text(
              isUnlimited ? '$used / Onbeperkt' : '$used / $limit',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isNearLimit ? Colors.orange : Colors.grey[700],
              ),
            ),
          ],
        ),
        if (!isUnlimited) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation(
                isNearLimit ? Colors.orange : AppTheme.primaryColor,
              ),
              minHeight: 6,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPaymentSection() {
    final isPremium = _limits['is_premium'] == true;
    final isOnTrial = _subscription['is_on_trial'] == true;
    final appleSubscription = _subscription['apple_subscription'];
    final isAppleSubscription = appleSubscription != null;
    // Apple Guideline 3.1.1 — on iOS we must NEVER lead users to a web
    // payment flow. Hide every external "manage subscription on web"
    // and "view pricing on web" path when running on iOS.
    final isIOS = Platform.isIOS;

    // Debug info for iOS — only in debug builds, never in TestFlight/release
    Widget? iapDebugWidget;
    if (Platform.isIOS && kDebugMode) {
      iapDebugWidget = Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.apple, color: Colors.blue[700], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Apple IAP Debug',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[900], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Store: ${_iapInitialized ? "✓ Beschikbaar" : "✗ Niet beschikbaar"}\n'
              'Producten: ${_iapProducts.length} geladen\n'
              '${_iapProducts.map((p) => "• ${p.id}\n  Prijs: ${p.price}\n  Valuta: ${p.currencyCode}\n  Raw: ${p.rawPrice}").join("\n")}',
              style: TextStyle(fontSize: 11, color: Colors.blue[800], fontFamily: 'monospace'),
            ),
          ],
        ),
      );
    }

    if (isPremium) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.settings, color: Colors.green),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Abonnement beheren',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (isAppleSubscription && Platform.isIOS) ...[
                Text(
                  'Je hebt een Apple App Store abonnement.',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Beheer je abonnement via de iOS Instellingen app onder "Abonnementen".',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _openSubscriptionSettings,
                    icon: const Icon(Icons.settings),
                    label: const Text('Open iOS Instellingen'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ] else if (!isIOS) ...[
                // Non-iOS: managing via web is allowed.
                Text(
                  'Beheer je abonnement of bekijk je facturen op de website.',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _openPaymentPage,
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Beheer abonnement'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ] else ...[
                // iOS + non-Apple subscription: Apple Guideline 3.1.1
                // forbids steering users to an external purchase flow.
                // We can still confirm the subscription is active.
                Text(
                  'Je abonnement is actief. Beheer of opzeggen kan via het '
                  'kanaal waarmee je het hebt afgesloten.',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
              // Show IAP debug info for premium users too
              if (iapDebugWidget != null) ...[
                const SizedBox(height: 16),
                iapDebugWidget,
              ],
            ],
          ),
        ),
      );
    }

    // Show upgrade options for free users and trial users
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.star, color: Colors.amber),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isOnTrial ? 'Upgrade naar Premium' : 'Meer mogelijkheden nodig?',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Premium benefits
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Premium voordelen:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  _buildBenefitRow('Onbeperkt accommodaties'),
                  _buildBenefitRow('Onbeperkt boekingen'),
                  _buildBenefitRow('Meerdere teamleden'),
                  _buildBenefitRow('E-mailcampagnes'),
                  _buildBenefitRow('Prioriteit support'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Apple Guideline 3.1.1: on iOS, only IAP. No web fallback.
            if (isIOS && _iapInitialized && _iapProducts.isNotEmpty) ...[
              _buildIAPPurchaseOptions(),
            ] else if (isIOS && _screenshotMode) ...[
              // Screenshot-mode only: simulator can't talk to StoreKit,
              // so we render a presentation-only copy of the IAP UI with
              // mock prices + Apple Guideline 3.1.2(c) disclosure for the
              // App Review IAP screenshot.
              _buildMockIAPPurchaseOptions(),
            ] else if (isIOS) ...[
              // iOS, but the App Store products did not load yet.
              // Apple Guideline 3.1.1 forbids us from offering a web
              // alternative here \u2014 show a retry instead.
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.amber[800]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Abonnementen worden geladen vanuit de App Store\u2026',
                            style: TextStyle(
                                color: Colors.amber[900],
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Lukt het niet? Controleer je internetverbinding en '
                      'probeer het opnieuw.',
                      style: TextStyle(
                          color: Colors.amber[900], fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _initializeIAP,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Opnieuw laden'),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Non-iOS (Android / web): web checkout is still allowed.
              Row(
                children: [
                  Expanded(
                    child: _buildPricingOption(
                      'Maandelijks',
                      '\u20AC9,99',
                      '/maand',
                      'Flexibel opzegbaar',
                      false,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPricingOption(
                      'Jaarlijks',
                      '\u20AC99',
                      '/jaar',
                      '17% korting',
                      true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _openPaymentPage,
                  icon: const Icon(Icons.rocket_launch),
                  label: const Text('Bekijk alle opties'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.amber[700],
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIAPPurchaseOptions() {
    final monthlyProduct = _iapProducts.where((p) => p.id == AppleIAPService.productMonthly).firstOrNull;
    final yearlyProduct = _iapProducts.where((p) => p.id == AppleIAPService.productYearly).firstOrNull;

    return Column(
      children: [
        // Yearly option (recommended)
        if (yearlyProduct != null)
          _buildIAPProductCard(
            product: yearlyProduct,
            title: 'Premium Jaarlijks',
            subtitle: 'Bespaar 17%',
            isPopular: true,
          ),
        const SizedBox(height: 12),
        // Monthly option
        if (monthlyProduct != null)
          _buildIAPProductCard(
            product: monthlyProduct,
            title: 'Premium Maandelijks',
            subtitle: 'Flexibel opzegbaar',
            isPopular: false,
          ),
        const SizedBox(height: 16),
        // Apple Guideline 3.1.2(c) — auto-renewable subscription
        // disclosure that must accompany the purchase UI.
        _buildAutoRenewDisclosure(monthlyProduct, yearlyProduct),
        const SizedBox(height: 12),
        // Apple Guideline 3.1.2(c) — functional links to EULA + Privacy
        // Policy, visible in the purchase flow itself.
        _buildLegalLinksRow(),
        const SizedBox(height: 8),
        // Restore purchases button
        TextButton.icon(
          onPressed: (_purchasingProductId != null || _isRestoring) ? null : _restorePurchases,
          icon: _isRestoring
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.restore, size: 18),
          label: Text(_isRestoring ? 'Herstellen...' : 'Aankopen herstellen'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey[600],
          ),
        ),
        if (_purchaseError != null) ...[
          const SizedBox(height: 8),
          Text(
            _purchaseError!,
            style: TextStyle(color: Colors.red[700], fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  /// Screenshot-mode mirror of [_buildIAPPurchaseOptions] using static
  /// prices, so the Codemagic-driven simulator screenshot for the IAP
  /// App Review submission shows real-looking content (prices + Apple
  /// Guideline 3.1.2(c) disclosure + EULA/Privacy links) even though
  /// StoreKit cannot load actual products inside the simulator.
  Widget _buildMockIAPPurchaseOptions() {
    return Column(
      children: [
        _buildMockProductCard(
          title: 'Premium Jaarlijks',
          subtitle: 'Bespaar 17%',
          price: '€99,00',
          period: '/jaar',
          isPopular: true,
        ),
        const SizedBox(height: 12),
        _buildMockProductCard(
          title: 'Premium Maandelijks',
          subtitle: 'Flexibel opzegbaar',
          price: '€9,99',
          period: '/maand',
          isPopular: false,
        ),
        const SizedBox(height: 16),
        // Apple Guideline 3.1.2(c) disclosure (same text as production).
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Abonnementsdetails',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '• Premium Maandelijks — €9,99 per maand, verlengt '
                'automatisch elke maand.\n'
                '• Premium Jaarlijks — €99,00 per jaar, verlengt '
                'automatisch elk jaar.',
                style: TextStyle(
                    fontSize: 11.5, color: Colors.grey[800], height: 1.35),
              ),
              const SizedBox(height: 4),
              Text(
                'Betaling wordt afgeschreven van je Apple ID bij '
                'aankoopbevestiging. Het abonnement verlengt automatisch '
                'tenzij je het minstens 24 uur vóór het einde van de '
                'huidige periode opzegt. Beheer of opzegging kan via '
                'Instellingen → Apple ID → Abonnementen.',
                style: TextStyle(
                    fontSize: 11.5, color: Colors.grey[700], height: 1.35),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildLegalLinksRow(),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.restore, size: 18),
          label: const Text('Aankopen herstellen'),
          style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildMockProductCard({
    required String title,
    required String subtitle,
    required String price,
    required String period,
    required bool isPopular,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPopular ? AppTheme.primaryColor.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPopular ? AppTheme.primaryColor : Colors.grey[300]!,
          width: isPopular ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          if (isPopular)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Aanbevolen',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: isPopular
                            ? AppTheme.primaryColor
                            : Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(price,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 20)),
                  Text(period,
                      style:
                          TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor:
                    isPopular ? AppTheme.primaryColor : Colors.grey[800],
                foregroundColor: Colors.white,
              ),
              child: const Text('Koop nu'),
            ),
          ),
        ],
      ),
    );
  }

  /// Apple Guideline 3.1.2(c) — disclosure of subscription title, length,
  /// price and auto-renewal terms, shown inline with the purchase buttons.
  Widget _buildAutoRenewDisclosure(
    ProductDetails? monthly,
    ProductDetails? yearly,
  ) {
    final lines = <String>[];
    if (monthly != null) {
      lines.add('• Premium Maandelijks — ${monthly.price} per maand, '
          'verlengt automatisch elke maand.');
    }
    if (yearly != null) {
      lines.add('• Premium Jaarlijks — ${yearly.price} per jaar, '
          'verlengt automatisch elk jaar.');
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Abonnementsdetails',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 6),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                line,
                style: TextStyle(fontSize: 11.5, color: Colors.grey[800], height: 1.35),
              ),
            ),
          Text(
            'Betaling wordt afgeschreven van je Apple ID bij aankoopbevestiging. '
            'Het abonnement verlengt automatisch tenzij je het minstens 24 uur '
            'vóór het einde van de huidige periode opzegt. Beheer of opzegging '
            'kan via Instellingen → Apple ID → Abonnementen.',
            style: TextStyle(
                fontSize: 11.5, color: Colors.grey[700], height: 1.35),
          ),
        ],
      ),
    );
  }

  /// Apple Guideline 3.1.2(c) — required EULA + Privacy links inside
  /// the auto-renewable subscription purchase flow.
  Widget _buildLegalLinksRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton.icon(
          onPressed: () => _openExternalUrl(
              'https://verhuuragenda.nl/algemene-voorwaarden'),
          icon: const Icon(Icons.description_outlined, size: 16),
          label: const Text('Voorwaarden (EULA)'),
          style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
        ),
        Text('•', style: TextStyle(color: Colors.grey[500])),
        TextButton.icon(
          onPressed: () =>
              _openExternalUrl('https://verhuuragenda.nl/privacy'),
          icon: const Icon(Icons.privacy_tip_outlined, size: 16),
          label: const Text('Privacybeleid'),
          style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
        ),
      ],
    );
  }

  Future<void> _openExternalUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildIAPProductCard({
    required ProductDetails product,
    required String title,
    required String subtitle,
    required bool isPopular,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPopular ? AppTheme.primaryColor.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPopular ? AppTheme.primaryColor : Colors.grey[300]!,
          width: isPopular ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          if (isPopular)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Aanbevolen',
                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: isPopular ? AppTheme.primaryColor : Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    product.price,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    product.id.contains('yearly') ? '/jaar' : '/maand',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _purchasingProductId != null ? null : () => _purchaseProduct(product.id),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: isPopular ? AppTheme.primaryColor : Colors.grey[800],
                foregroundColor: Colors.white,
              ),
              child: _purchasingProductId == product.id
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Koop nu'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openSubscriptionSettings() async {
    // Open iOS subscription settings
    final url = Uri.parse('https://apps.apple.com/account/subscriptions');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildBenefitRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.green[600]),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildPricingOption(String title, String price, String period, String subtitle, bool isPopular) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPopular ? AppTheme.primaryColor.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPopular ? AppTheme.primaryColor : Colors.grey[300]!,
          width: isPopular ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          if (isPopular)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Populair',
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              style: TextStyle(color: Colors.grey[800]),
              children: [
                TextSpan(
                  text: price,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: period,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: isPopular ? AppTheme.primaryColor : Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Future<void> _openPaymentPage() async {
    final url = Uri.parse('https://verhuuragenda.nl/verhuurder/abonnement');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kon website niet openen')),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'januari', 'februari', 'maart', 'april', 'mei', 'juni',
      'juli', 'augustus', 'september', 'oktober', 'november', 'december'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
