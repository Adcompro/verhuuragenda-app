import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../core/api/api_client.dart';
import '../../config/api_config.dart';
import '../../utils/responsive.dart';

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

    // Safety check for null dashboard data
    if (_dashboardData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Geen data beschikbaar', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDashboard,
              child: const Text('Vernieuwen'),
            ),
          ],
        ),
      );
    }

    final stats = _dashboardData?['stats'] as Map<String, dynamic>? ?? {};
    final upcomingCheckins = (_dashboardData?['upcoming_checkins_list'] as List?) ?? [];
    final upcomingCheckouts = (_dashboardData?['upcoming_checkouts_list'] as List?) ?? [];
    final recentBookings = (_dashboardData?['recent_bookings'] as List?) ?? [];
    final isWide = Responsive.useWideLayout(context);
    final padding = Responsive.getScreenPadding(context);

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: ListView(
        padding: padding,
        children: [
          // Stats Grid - 4 columns on tablet, 2 on phone
          GridView.count(
            crossAxisCount: isWide ? 4 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: isWide ? 1.1 : 1.1,
            children: [
              _StatCard(
                title: 'Actieve boekingen',
                value: '${stats['current_bookings'] ?? 0}',
                icon: Icons.calendar_today,
                color: AppTheme.primaryColor,
                onTap: () => _showStatDetails('active', upcomingCheckins, upcomingCheckouts),
              ),
              _StatCard(
                title: 'Check-ins',
                value: '${stats['upcoming_checkins'] ?? 0}',
                subtitle: 'komende 7 dagen',
                icon: Icons.login,
                color: AppTheme.successColor,
                onTap: () => _showStatDetails('checkins', upcomingCheckins, upcomingCheckouts),
              ),
              _StatCard(
                title: 'Check-outs',
                value: '${stats['upcoming_checkouts'] ?? 0}',
                subtitle: 'komende 7 dagen',
                icon: Icons.logout,
                color: AppTheme.accentColor,
                onTap: () => _showStatDetails('checkouts', upcomingCheckins, upcomingCheckouts),
              ),
              _StatCard(
                title: 'Omzet deze maand',
                value: '€${_formatAmount(stats['monthly_revenue'])}',
                icon: Icons.euro,
                color: AppTheme.secondaryColor,
                onTap: () => _showRevenueDetails(stats),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // On tablet: show check-ins and check-outs side by side
          if (isWide) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Check-ins column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // Check-outs column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            // Phone layout: stacked
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
          ],

          const SizedBox(height: 24),

          // Recent Bookings
          _buildSectionHeader(
            'Recente Boekingen',
            Icons.history,
            Colors.grey[600]!,
            recentBookings.length,
          ),
          const SizedBox(height: 8),
          // On tablet: show recent bookings in a grid
          if (isWide && recentBookings.isNotEmpty)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.0,
              ),
              itemCount: recentBookings.length,
              itemBuilder: (context, index) => _buildRecentBookingCard(recentBookings[index]),
            )
          else if (recentBookings.isEmpty)
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
    final totalAmount = _parseAmount(booking['total_amount']);
    final paidAmount = _parseAmount(booking['paid_amount']);
    final openAmount = totalAmount - paidAmount;
    final hasWishes = booking['special_requests'] != null &&
                       booking['special_requests'].toString().isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showBookingDetail(booking),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                ],
              ),
              // Payment info row
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    // Total
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            'Totaal: ',
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          ),
                          Text(
                            '€${_formatAmount(totalAmount)}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    // Paid
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '€${_formatAmount(paidAmount)}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.successColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Open
                    if (openAmount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '€${_formatAmount(openAmount)} open',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Special requests / wishes
              if (hasWishes) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.star, size: 14, color: Colors.amber[700]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          booking['special_requests'].toString(),
                          style: TextStyle(fontSize: 11, color: Colors.amber[900]),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
    final value = _parseAmount(amount);
    return value.toStringAsFixed(0);
  }

  double _parseAmount(dynamic amount) {
    if (amount == null) return 0.0;
    if (amount is num) return amount.toDouble();
    if (amount is String) {
      return double.tryParse(amount) ?? 0.0;
    }
    return 0.0;
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
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
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
                              Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: _parseColor(booking['accommodation_color']),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      booking['accommodation'] ?? '',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        _buildStatusBadge(booking['status']),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Source badge
                    if (booking['source'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getSourceColor(booking['source']).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_getSourceIcon(booking['source']), size: 16, color: _getSourceColor(booking['source'])),
                            const SizedBox(width: 6),
                            Text(
                              _getSourceLabel(booking['source']),
                              style: TextStyle(
                                color: _getSourceColor(booking['source']),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),

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
                                const Text('Check-in', style: TextStyle(color: Colors.grey)),
                                const SizedBox(height: 4),
                                Text(
                                  _formatDate(booking['check_in']),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                              style: const TextStyle(fontWeight: FontWeight.w500, color: AppTheme.primaryColor),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                const Text('Check-out', style: TextStyle(color: Colors.grey)),
                                const SizedBox(height: 4),
                                Text(
                                  _formatDate(booking['check_out']),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Guests info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Icon(Icons.person, color: Colors.grey[600]),
                              const SizedBox(height: 4),
                              Text('${booking['adults'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              Text('Volwassenen', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                            ],
                          ),
                          Column(
                            children: [
                              Icon(Icons.child_care, color: Colors.grey[600]),
                              const SizedBox(height: 4),
                              Text('${booking['children'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              Text('Kinderen', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Payment info
                    if (booking['total_amount'] != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _getPaymentStatusColor(booking['payment_status']).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _getPaymentStatusColor(booking['payment_status']).withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Totaalbedrag', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                const SizedBox(height: 4),
                                Text(
                                  '€${_formatAmount(booking['total_amount'])}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Betaald', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                const SizedBox(height: 4),
                                Text(
                                  '€${_formatAmount(booking['paid_amount'] ?? 0)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: _getPaymentStatusColor(booking['payment_status']),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),

                    // Contact info
                    if (booking['guest_email'] != null && booking['guest_email'].toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(Icons.email_outlined, size: 18, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Expanded(child: Text(booking['guest_email'], style: TextStyle(color: Colors.grey[700]))),
                          ],
                        ),
                      ),
                    if (booking['guest_phone'] != null && booking['guest_phone'].toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          children: [
                            Icon(Icons.phone_outlined, size: 18, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Text(booking['guest_phone'], style: TextStyle(color: Colors.grey[700])),
                          ],
                        ),
                      ),

                    // Actions
                    if (booking['guest_phone'] != null && booking['guest_phone'].toString().isNotEmpty)
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _callPhone(booking['guest_phone']);
                              },
                              icon: const Icon(Icons.phone),
                              label: const Text('Bellen'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _openWhatsApp(booking['guest_phone']);
                              },
                              icon: const Icon(Icons.message, color: Color(0xFF25D366)),
                              label: const Text('WhatsApp'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (booking['guest_email'] != null && booking['guest_email'].toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _sendEmail(booking['guest_email']);
                          },
                          icon: const Icon(Icons.email),
                          label: const Text('Email versturen'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
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

  Color _getPaymentStatusColor(String? status) {
    switch (status) {
      case 'paid':
        return AppTheme.successColor;
      case 'partial':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  String _getSourceLabel(String? source) {
    switch (source) {
      case 'direct':
        return 'Direct';
      case 'airbnb':
        return 'Airbnb';
      case 'booking':
        return 'Booking.com';
      case 'vrbo':
        return 'VRBO';
      default:
        return source ?? 'Onbekend';
    }
  }

  Color _getSourceColor(String? source) {
    switch (source) {
      case 'airbnb':
        return const Color(0xFFFF5A5F);
      case 'booking':
        return const Color(0xFF003580);
      case 'vrbo':
        return const Color(0xFF3D67CC);
      default:
        return AppTheme.primaryColor;
    }
  }

  IconData _getSourceIcon(String? source) {
    switch (source) {
      case 'airbnb':
        return Icons.house;
      case 'booking':
        return Icons.hotel;
      default:
        return Icons.calendar_today;
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('https://wa.me/$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _sendEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showStatDetails(String type, List checkins, List checkouts) {
    String title;
    String description;
    List items;
    Color color;
    IconData icon;

    switch (type) {
      case 'active':
        title = 'Actieve Boekingen';
        description = 'Huidige gasten die nu verblijven';
        items = [...checkins, ...checkouts].where((b) {
          final checkIn = DateTime.tryParse(b['check_in'] ?? '');
          final checkOut = DateTime.tryParse(b['check_out'] ?? '');
          final now = DateTime.now();
          return checkIn != null && checkOut != null &&
                 checkIn.isBefore(now) && checkOut.isAfter(now);
        }).toList();
        color = AppTheme.primaryColor;
        icon = Icons.calendar_today;
        break;
      case 'checkins':
        title = 'Aankomende Check-ins';
        description = 'Check-ins in de komende 7 dagen';
        items = checkins;
        color = AppTheme.successColor;
        icon = Icons.login;
        break;
      case 'checkouts':
        title = 'Aankomende Check-outs';
        description = 'Check-outs in de komende 7 dagen';
        items = checkouts;
        color = AppTheme.accentColor;
        icon = Icons.logout;
        break;
      default:
        return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
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
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          description,
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${items.length}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // List
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, size: 48, color: Colors.grey[300]),
                          const SizedBox(height: 12),
                          Text(
                            'Geen items',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final booking = items[index];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: color.withOpacity(0.1),
                              child: Text(
                                (booking['guest_name'] ?? 'O')[0].toUpperCase(),
                                style: TextStyle(color: color, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(
                              booking['guest_name'] ?? 'Onbekend',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(booking['accommodation'] ?? ''),
                                Text(
                                  type == 'checkouts'
                                      ? 'Check-out: ${_formatDate(booking['check_out'])}'
                                      : 'Check-in: ${_formatDate(booking['check_in'])}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                ),
                              ],
                            ),
                            trailing: booking['is_today'] == true
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'VANDAAG',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                : Text(
                                    '+${booking['days_until'] ?? 0}d',
                                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                                  ),
                            onTap: () {
                              Navigator.pop(context);
                              _showBookingDetail(booking);
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRevenueDetails(Map<String, dynamic> stats) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.euro, color: AppTheme.secondaryColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Omzet Deze Maand',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Gebaseerd op betalingen deze maand',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Revenue card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.secondaryColor,
                      AppTheme.secondaryColor.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Totale omzet',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '€${_formatAmount(stats['monthly_revenue'])}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getCurrentMonthName(),
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Additional info
              Row(
                children: [
                  Expanded(
                    child: _buildRevenueInfoCard(
                      'Boekingen',
                      '${stats['current_bookings'] ?? 0}',
                      Icons.calendar_today,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildRevenueInfoCard(
                      'Check-ins',
                      '${stats['upcoming_checkins'] ?? 0}',
                      Icons.login,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRevenueInfoCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.grey[600]),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  String _getCurrentMonthName() {
    const months = [
      'Januari', 'Februari', 'Maart', 'April', 'Mei', 'Juni',
      'Juli', 'Augustus', 'September', 'Oktober', 'November', 'December'
    ];
    final now = DateTime.now();
    return '${months[now.month - 1]} ${now.year}';
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 20),
                  if (onTap != null)
                    Icon(Icons.chevron_right, color: Colors.grey[400], size: 18),
                ],
              ),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey[400],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
