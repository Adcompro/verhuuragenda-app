import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../core/api/api_client.dart';
import '../../config/api_config.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  List<dynamic> _accommodations = [];
  List<dynamic> _bookings = [];
  List<dynamic> _blockedDates = [];
  bool _isLoading = true;
  String? _error;

  DateTime _startDate = DateTime.now();
  final int _daysToShow = 14;

  @override
  void initState() {
    super.initState();
    _loadCalendarData();
  }

  Future<void> _loadCalendarData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final endDate = _startDate.add(Duration(days: _daysToShow + 7));
      final startDate = _startDate.subtract(const Duration(days: 2));
      final response = await ApiClient.instance.get(
        '${ApiConfig.calendar}?start=${_formatDate(startDate)}&end=${_formatDate(endDate)}',
      );

      final data = response.data;
      setState(() {
        _accommodations = data['accommodations'] ?? [];
        _bookings = data['bookings'] ?? [];
        _blockedDates = data['blocked_dates'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = '$e';
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorView()
                : _buildContent(),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red[50],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.wifi_off, size: 48, color: Colors.red[300]),
            ),
            const SizedBox(height: 24),
            const Text(
              'Kon niet laden',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadCalendarData,
              icon: const Icon(Icons.refresh),
              label: const Text('Opnieuw'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildHeader(),
        _buildQuickStats(),
        _buildDateNav(),
        Expanded(
          child: _accommodations.isEmpty
              ? _buildEmptyState()
              : _buildAccommodationCards(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bezetting',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1D26),
                  ),
                ),
                Text(
                  '${_accommodations.length} accommodaties',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: IconButton(
              onPressed: _loadCalendarData,
              icon: const Icon(Icons.refresh_rounded),
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final today = DateTime.now();
    final todayStr = _formatDate(today);

    int occupiedToday = 0;
    int checkInsToday = 0;
    int checkOutsToday = 0;

    for (var booking in _bookings) {
      final checkIn = booking['check_in'];
      final checkOut = booking['check_out'];

      if (checkIn == todayStr) checkInsToday++;
      if (checkOut == todayStr) checkOutsToday++;

      try {
        final checkInDate = DateTime.parse(checkIn);
        final checkOutDate = DateTime.parse(checkOut);
        if (!today.isBefore(checkInDate) && today.isBefore(checkOutDate)) {
          occupiedToday++;
        }
      } catch (e) {}
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          _statChip(
            Icons.home_rounded,
            '$occupiedToday/${_accommodations.length}',
            'Bezet',
            AppTheme.primaryColor,
          ),
          const SizedBox(width: 12),
          _statChip(
            Icons.login_rounded,
            '$checkInsToday',
            'Check-in',
            AppTheme.successColor,
          ),
          const SizedBox(width: 12),
          _statChip(
            Icons.logout_rounded,
            '$checkOutsToday',
            'Check-out',
            AppTheme.accentColor,
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateNav() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          _navButton(Icons.chevron_left_rounded, () {
            setState(() => _startDate = _startDate.subtract(const Duration(days: 7)));
            _loadCalendarData();
          }),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _startDate = DateTime.now());
                _loadCalendarData();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  children: [
                    Text(
                      _getDateRangeText(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Tik voor vandaag',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _navButton(Icons.chevron_right_rounded, () {
            setState(() => _startDate = _startDate.add(const Duration(days: 7)));
            _loadCalendarData();
          }),
        ],
      ),
    );
  }

  Widget _navButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: Colors.grey[700]),
        ),
      ),
    );
  }

  String _getDateRangeText() {
    final endDate = _startDate.add(Duration(days: _daysToShow - 1));
    final months = ['', 'jan', 'feb', 'mrt', 'apr', 'mei', 'jun', 'jul', 'aug', 'sep', 'okt', 'nov', 'dec'];

    if (_startDate.month == endDate.month) {
      return '${_startDate.day} - ${endDate.day} ${months[endDate.month]}';
    } else {
      return '${_startDate.day} ${months[_startDate.month]} - ${endDate.day} ${months[endDate.month]}';
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.villa_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Geen accommodaties',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccommodationCards() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: _accommodations.length,
      itemBuilder: (context, index) {
        return _buildAccommodationCard(_accommodations[index]);
      },
    );
  }

  Widget _buildAccommodationCard(dynamic accommodation) {
    final accId = accommodation['id'];
    final accColor = _parseColor(accommodation['color']);
    final accBookings = _bookings.where((b) => b['accommodation_id'] == accId).toList();
    final accBlocked = _blockedDates.where((b) => b['accommodation_id'] == accId).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: accColor, width: 4),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.home_rounded, color: accColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    accommodation['name'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                _getStatusBadge(accBookings, accBlocked),
              ],
            ),
          ),

          // Timeline
          Container(
            height: 60,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _buildTimeline(accBookings, accBlocked),
          ),
        ],
      ),
    );
  }

  Widget _getStatusBadge(List<dynamic> bookings, List<dynamic> blocked) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    for (var booking in bookings) {
      try {
        final checkIn = DateTime.parse(booking['check_in']);
        final checkOut = DateTime.parse(booking['check_out']);
        final checkInOnly = DateTime(checkIn.year, checkIn.month, checkIn.day);
        final checkOutOnly = DateTime(checkOut.year, checkOut.month, checkOut.day);

        if (!todayOnly.isBefore(checkInOnly) && todayOnly.isBefore(checkOutOnly)) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppTheme.successColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Bezet',
                  style: TextStyle(
                    color: AppTheme.successColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }
      } catch (e) {}
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Vrij',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(List<dynamic> bookings, List<dynamic> blocked) {
    final dates = List.generate(
      _daysToShow,
      (i) => _startDate.add(Duration(days: i)),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = constraints.maxWidth / _daysToShow;

        return Stack(
          children: [
            // Day indicators
            Row(
              children: dates.asMap().entries.map((entry) {
                final date = entry.value;
                final isToday = _isToday(date);
                final isWeekend = date.weekday >= 6;

                return SizedBox(
                  width: cellWidth,
                  child: Column(
                    children: [
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                          color: isToday ? AppTheme.primaryColor : Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: isToday
                                ? AppTheme.primaryColor.withOpacity(0.2)
                                : isWeekend
                                    ? Colors.grey[200]
                                    : Colors.grey[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

            // Booking bars (positioned on top)
            ...blocked.map((b) => _buildTimelineBar(b, dates, cellWidth, isBlocked: true)),
            ...bookings.map((b) => _buildTimelineBar(b, dates, cellWidth, isBlocked: false)),
          ],
        );
      },
    );
  }

  Widget _buildTimelineBar(
    dynamic event,
    List<DateTime> dates,
    double cellWidth, {
    required bool isBlocked,
  }) {
    final DateTime startDate;
    final DateTime endDate;
    final Color color;
    final String label;

    if (isBlocked) {
      startDate = DateTime.parse(event['start_date']);
      endDate = DateTime.parse(event['end_date']);
      final source = event['source'] ?? '';
      color = source == 'airbnb' ? AppTheme.sourceAirbnb :
              source == 'booking' ? AppTheme.sourceBooking : Colors.grey;
      label = source == 'airbnb' ? 'Airbnb' :
              source == 'booking' ? 'Booking' : 'Geblokkeerd';
    } else {
      startDate = DateTime.parse(event['check_in']);
      endDate = DateTime.parse(event['check_out']);
      color = _parseColor(event['color']);
      label = event['guest_name'] ?? '';
    }

    final startDay = DateTime(dates.first.year, dates.first.month, dates.first.day);
    final startOffset = startDate.difference(startDay).inDays;
    final duration = endDate.difference(startDate).inDays + (isBlocked ? 1 : 0);

    if (startOffset + duration < 0 || startOffset >= _daysToShow) {
      return const SizedBox.shrink();
    }

    final visibleStart = startOffset < 0 ? 0 : startOffset;
    final visibleEnd = (startOffset + duration) > _daysToShow ? _daysToShow : (startOffset + duration);
    final visibleDuration = visibleEnd - visibleStart;

    if (visibleDuration <= 0) return const SizedBox.shrink();

    return Positioned(
      left: visibleStart * cellWidth,
      top: 16,
      child: GestureDetector(
        onTap: isBlocked ? null : () => _showBookingDetails(event),
        child: Container(
          width: visibleDuration * cellWidth - 2,
          height: 28,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  void _showBookingDetails(dynamic booking) {
    final color = _parseColor(booking['color']);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.person, color: Colors.white, size: 26),
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
                        Text(
                          _getStatusLabel(booking['status']),
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _detailTile(Icons.login_rounded, 'Check-in', _formatDisplayDate(booking['check_in'])),
              _detailTile(Icons.logout_rounded, 'Check-out', _formatDisplayDate(booking['check_out'])),
              _detailTile(Icons.euro_rounded, 'Betaling', _getPaymentLabel(booking['payment_status'])),

              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _detailTile(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[400], size: 22),
          const SizedBox(width: 16),
          Text(label, style: TextStyle(color: Colors.grey[600])),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Color _parseColor(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) return Colors.grey;
    try {
      return Color(int.parse('FF${colorHex.replaceAll('#', '')}', radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  String _formatDisplayDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      const weekdays = ['', 'Ma', 'Di', 'Wo', 'Do', 'Vr', 'Za', 'Zo'];
      return '${weekdays[date.weekday]} ${date.day}/${date.month}';
    } catch (e) {
      return dateStr;
    }
  }

  String _getStatusLabel(String? status) {
    switch (status) {
      case 'confirmed': return 'Bevestigd';
      case 'option': return 'Optie';
      case 'inquiry': return 'Aanvraag';
      default: return status ?? 'Onbekend';
    }
  }

  String _getPaymentLabel(String? status) {
    switch (status) {
      case 'paid': return 'Betaald';
      case 'partial': return 'Aanbetaald';
      case 'unpaid': return 'Openstaand';
      default: return status ?? '-';
    }
  }
}
