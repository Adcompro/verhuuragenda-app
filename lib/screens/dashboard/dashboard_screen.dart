import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
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
    final upcomingCheckins = (_dashboardData?['upcoming_checkins_list'] as List?) ?? [];
    final upcomingCheckouts = (_dashboardData?['upcoming_checkouts_list'] as List?) ?? [];
    final recentBookings = (_dashboardData?['recent_bookings'] as List?) ?? [];

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
                value: '€${_formatAmount(stats['monthly_revenue'])}',
                icon: Icons.euro,
                color: AppTheme.secondaryColor,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Upcoming Check-ins
          _buildSectionHeader(
            'Aankomende Check-ins',
            Icons.login,
            AppTheme.successColor,
            upcomingCheckins.length,
          ),
          const SizedBox(height: 8),
          if (upcomingCheckins.isEmpty)
            _buildEmptyCard('Geen check-ins gepland')
          else
            ...upcomingCheckins.map<Widget>((booking) => _buildCheckinCard(booking)).toList(),

          const SizedBox(height: 24),

          // Upcoming Check-outs
          _buildSectionHeader(
            'Aankomende Check-outs',
            Icons.logout,
            AppTheme.accentColor,
            upcomingCheckouts.length,
          ),
          const SizedBox(height: 8),
          if (upcomingCheckouts.isEmpty)
            _buildEmptyCard('Geen check-outs gepland')
          else
            ...upcomingCheckouts.map<Widget>((booking) => _buildCheckoutCard(booking)).toList(),

          const SizedBox(height: 24),

          // Recent Bookings
          _buildSectionHeader(
            'Recente Boekingen',
            Icons.history,
            Colors.grey[600]!,
            recentBookings.length,
          ),
          const SizedBox(height: 8),
          if (recentBookings.isEmpty)
            _buildEmptyCard('Nog geen boekingen')
          else
            ...recentBookings.map<Widget>((booking) => _buildRecentBookingCard(booking)).toList(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color, int count) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(width: 8),
        if (count > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyCard(String message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            message,
            style: TextStyle(color: Colors.grey[500]),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckinCard(dynamic booking) {
    final isToday = booking['is_today'] == true;
    final daysUntil = booking['days_until'] ?? 0;
    final accommodationColor = _parseColor(booking['accommodation_color']);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isToday
            ? BorderSide(color: AppTheme.successColor, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showBookingDetail(booking),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Day indicator
              Container(
                width: 50,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isToday ? AppTheme.successColor : AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      isToday ? 'NU' : '+$daysUntil',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isToday ? Colors.white : AppTheme.successColor,
                      ),
                    ),
                    if (!isToday)
                      Text(
                        daysUntil == 1 ? 'dag' : 'dagen',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.successColor,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Booking info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            booking['guest_name'] ?? 'Onbekend',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        _buildStatusBadge(booking['status']),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: accommodationColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            booking['accommodation'] ?? '',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.nights_stay, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          '${booking['nights'] ?? 0} nachten',
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.people, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          '${booking['adults'] ?? 0} volw.',
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                        if ((booking['children'] ?? 0) > 0) ...[
                          Text(
                            ' + ${booking['children']} kind.',
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Call button
              if (booking['guest_phone'] != null && booking['guest_phone'].toString().isNotEmpty)
                IconButton(
                  icon: Icon(Icons.phone, color: AppTheme.successColor),
                  onPressed: () => _callPhone(booking['guest_phone']),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckoutCard(dynamic booking) {
    final isToday = booking['is_today'] == true;
    final daysUntil = booking['days_until'] ?? 0;
    final accommodationColor = _parseColor(booking['accommodation_color']);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isToday
            ? BorderSide(color: AppTheme.accentColor, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showBookingDetail(booking),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Day indicator
              Container(
                width: 50,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isToday ? AppTheme.accentColor : AppTheme.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      isToday ? 'NU' : '+$daysUntil',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isToday ? Colors.white : AppTheme.accentColor,
                      ),
                    ),
                    if (!isToday)
                      Text(
                        daysUntil == 1 ? 'dag' : 'dagen',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.accentColor,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Booking info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking['guest_name'] ?? 'Onbekend',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: accommodationColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            booking['accommodation'] ?? '',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Check-out: ${_formatDate(booking['check_out'])}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              // Call button
              if (booking['guest_phone'] != null && booking['guest_phone'].toString().isNotEmpty)
                IconButton(
                  icon: Icon(Icons.phone, color: AppTheme.accentColor),
                  onPressed: () => _callPhone(booking['guest_phone']),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentBookingCard(dynamic booking) {
    final accommodationColor = _parseColor(booking['accommodation_color']);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showBookingDetail(booking),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                child: Text(
                  (booking['guest_name'] ?? 'O')[0].toUpperCase(),
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            booking['guest_name'] ?? 'Onbekend',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _buildStatusBadge(booking['status']),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: accommodationColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            booking['accommodation'] ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_formatDate(booking['check_in'])} - ${_formatDate(booking['check_out'])} (${booking['nights']} nachten)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              // Amount
              if (booking['total_amount'] != null)
                Text(
                  '€${_formatAmount(booking['total_amount'])}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String? status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getStatusLabel(status),
        style: TextStyle(
          fontSize: 11,
          color: _getStatusColor(status),
          fontWeight: FontWeight.w500,
        ),
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

  Color _parseColor(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) {
      return AppTheme.primaryColor;
    }
    try {
      String hex = colorHex.replaceAll('#', '');
      if (hex.length == 6) {
        hex = 'FF$hex';
      }
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      return AppTheme.primaryColor;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final months = ['jan', 'feb', 'mrt', 'apr', 'mei', 'jun', 'jul', 'aug', 'sep', 'okt', 'nov', 'dec'];
      return '${date.day} ${months[date.month - 1]}';
    } catch (e) {
      return dateStr;
    }
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '0';
    final num value = amount is num ? amount : 0;
    return value.toStringAsFixed(0);
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showBookingDetail(dynamic booking) {
    // Navigate to booking detail or show bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Header
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                          child: Text(
                            (booking['guest_name'] ?? 'O')[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                booking['guest_name'] ?? 'Onbekend',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                booking['accommodation'] ?? '',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildStatusBadge(booking['status']),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Dates
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                const Text(
                                  'Check-in',
                                  style: TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatDate(booking['check_in']),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '${booking['nights'] ?? 0} nachten',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                const Text(
                                  'Check-out',
                                  style: TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatDate(booking['check_out']),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Actions
                    if (booking['guest_phone'] != null && booking['guest_phone'].toString().isNotEmpty)
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _callPhone(booking['guest_phone']);
                        },
                        icon: const Icon(Icons.phone),
                        label: Text('Bel ${booking['guest_name']}'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
