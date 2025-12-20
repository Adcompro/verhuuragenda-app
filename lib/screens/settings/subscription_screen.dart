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
    final planName = _subscription['plan_name'] ?? 'Onbekend';
    final status = _subscription['status'] ?? 'unknown';
    final expiresAt = _subscription['expires_at'];
    final isActive = status == 'active';
    final daysRemaining = _subscription['days_remaining'] ?? 0;

    DateTime? expiryDate;
    if (expiresAt != null) {
      expiryDate = DateTime.tryParse(expiresAt);
    }

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
                    isActive ? 'Actief' : 'Verlopen',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(color: Colors.white30),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Geldig tot',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
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
            if (daysRemaining < 30 && daysRemaining > 0) ...[
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
                        'Je abonnement verloopt binnenkort. Verleng op tijd om toegang te behouden.',
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
    final accommodationsUsed = _limits['accommodations_used'] ?? 0;
    final accommodationsLimit = _limits['accommodations_limit'] ?? 0;
    final bookingsUsed = _limits['bookings_used'] ?? 0;
    final bookingsLimit = _limits['bookings_limit'] ?? 0;
    final teamMembersUsed = _limits['team_members_used'] ?? 0;
    final teamMembersLimit = _limits['team_members_limit'] ?? 0;

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
              teamMembersUsed,
              teamMembersLimit,
              Icons.people,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLimitItem(String label, int used, int limit, IconData icon) {
    final isUnlimited = limit == -1 || limit == 0;
    final percentage = isUnlimited ? 0.0 : (used / limit).clamp(0.0, 1.0);
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
                const Text(
                  'Betaling & Verlengen',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Verleng je abonnement of bekijk je facturen op de website.',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openPaymentPage,
                icon: const Icon(Icons.open_in_new),
                label: const Text('Naar betaling op website'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _openInvoicesPage,
                icon: const Icon(Icons.receipt_long),
                label: const Text('Bekijk facturen'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPaymentPage() async {
    final url = Uri.parse('https://verhuuragenda.nl/abonnement/verlengen');
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

  Future<void> _openInvoicesPage() async {
    final url = Uri.parse('https://verhuuragenda.nl/verhuurder/facturen');
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
