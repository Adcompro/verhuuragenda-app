import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../config/api_config.dart';
import '../../core/api/api_client.dart';

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

  @override
  void initState() {
    super.initState();
    _loadSubscription();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Abonnement'),
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
              child: const Text('Opnieuw proberen'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard() {
    // API field names
    final tier = _subscription['subscription_tier'] ?? 'free';
    final isPremium = _subscription['is_premium'] == true;
    final isOnTrial = _subscription['is_on_trial'] == true;
    final subscriptionEndsAt = _subscription['subscription_ends_at'];
    final trialEndsAt = _subscription['trial_ends_at'];
    final trialDaysRemaining = _subscription['trial_days_remaining'];

    // Determine plan name
    String planName;
    if (isPremium) {
      planName = 'Premium';
    } else if (isOnTrial) {
      planName = 'Proefperiode';
    } else {
      planName = 'Gratis';
    }

    // Determine expiry date and days remaining
    DateTime? expiryDate;
    int daysRemaining = 0;

    if (subscriptionEndsAt != null) {
      expiryDate = DateTime.tryParse(subscriptionEndsAt);
      if (expiryDate != null) {
        daysRemaining = expiryDate.difference(DateTime.now()).inDays;
        if (daysRemaining < 0) daysRemaining = 0;
      }
    } else if (trialEndsAt != null) {
      expiryDate = DateTime.tryParse(trialEndsAt);
      daysRemaining = trialDaysRemaining ?? 0;
    }

    final isActive = isPremium || isOnTrial;

    return Card(
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: isActive
                ? [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)]
                : [Colors.grey[600]!, Colors.grey[500]!],
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
                    const Text(
                      'Huidig abonnement',
                      style: TextStyle(
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
                    color: isActive ? Colors.white24 : Colors.red[400],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isActive ? (isOnTrial ? 'Proef' : 'Actief') : 'Gratis',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            if (expiryDate != null || daysRemaining > 0) ...[
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
                          isOnTrial ? 'Proef eindigt' : 'Geldig tot',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          expiryDate != null
                              ? _formatDate(expiryDate)
                              : 'Onbekend',
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
            if (daysRemaining > 0 && daysRemaining < 30) ...[
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
                  child: const Icon(Icons.payment, color: Colors.green),
                ),
                const SizedBox(width: 12),
                Text(
                  isPremium ? 'Abonnement beheren' : 'Upgrade naar Premium',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              isPremium
                  ? 'Beheer je abonnement of bekijk je facturen op de website.'
                  : 'Krijg toegang tot alle functies zonder beperkingen.',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openPaymentPage,
                icon: Icon(isPremium ? Icons.settings : Icons.star),
                label: Text(isPremium ? 'Beheer abonnement' : 'Upgrade nu'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
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
