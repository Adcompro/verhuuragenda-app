import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../core/api/api_client.dart';
import '../../config/api_config.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiClient.instance.get(ApiConfig.dashboard);
      setState(() {
        _dashboardData = response.data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Kon dashboard niet laden';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dashboard'),
            if (user != null)
              Text(
                'Welkom, ${user.name}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboard,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDashboard,
              child: const Text('Opnieuw proberen'),
            ),
          ],
        ),
      );
    }

    final stats = _dashboardData?['stats'] ?? {};
    final recentBookings = _dashboardData?['recent_bookings'] ?? [];

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Stats Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _StatCard(
                title: 'Actieve boekingen',
                value: '${stats['current_bookings'] ?? 0}',
                icon: Icons.calendar_today,
                color: AppTheme.primaryColor,
              ),
              _StatCard(
                title: 'Check-ins',
                value: '${stats['upcoming_checkins'] ?? 0}',
                subtitle: 'komende 7 dagen',
                icon: Icons.login,
                color: AppTheme.successColor,
              ),
              _StatCard(
                title: 'Check-outs',
                value: '${stats['upcoming_checkouts'] ?? 0}',
                subtitle: 'komende 7 dagen',
                icon: Icons.logout,
                color: AppTheme.accentColor,
              ),
              _StatCard(
                title: 'Omzet deze maand',
                value: '€${(stats['monthly_revenue'] ?? 0).toStringAsFixed(0)}',
                icon: Icons.euro,
                color: AppTheme.secondaryColor,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Recent Bookings
          Text(
            'Recente boekingen',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),

          if (recentBookings.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text('Nog geen boekingen'),
                ),
              ),
            )
          else
            ...recentBookings.map<Widget>((booking) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    child: const Icon(Icons.person, color: AppTheme.primaryColor),
                  ),
                  title: Text(booking['guest_name'] ?? 'Onbekend'),
                  subtitle: Text(
                    '${booking['check_in']} - ${booking['check_out']}',
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(booking['status']).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusLabel(booking['status']),
                      style: TextStyle(
                        fontSize: 12,
                        color: _getStatusColor(booking['status']),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'confirmed':
        return AppTheme.statusConfirmed;
      case 'option':
        return AppTheme.statusOption;
      case 'inquiry':
        return AppTheme.statusInquiry;
      case 'cancelled':
        return AppTheme.statusCancelled;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String? status) {
    switch (status) {
      case 'confirmed':
        return 'Bevestigd';
      case 'option':
        return 'Optie';
      case 'inquiry':
        return 'Aanvraag';
      case 'cancelled':
        return 'Geannuleerd';
      default:
        return status ?? 'Onbekend';
    }
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.grey[400],
                    ),
              ),
          ],
        ),
      ),
    );
  }
}
