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

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 1));
  int _daysToShow = 14;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadCalendarData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCalendarData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final endDate = _startDate.add(Duration(days: _daysToShow + 5));
      final response = await ApiClient.instance.get(
        '${ApiConfig.calendar}?start=${_formatDate(_startDate)}&end=${_formatDate(endDate)}',
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Bezettingskalender'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCalendarData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorView()
              : _buildContent(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Kon kalender niet laden',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadCalendarData,
              icon: const Icon(Icons.refresh),
              label: const Text('Opnieuw proberen'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Navigation bar
        _buildNavigationBar(),

        // Calendar grid
        Expanded(
          child: _accommodations.isEmpty
              ? _buildEmptyState()
              : _buildCalendarGrid(),
        ),

        // Legend
        _buildLegend(),
      ],
    );
  }

  Widget _buildNavigationBar() {
    final endDate = _startDate.add(Duration(days: _daysToShow - 1));
    final dateRange = '${_startDate.day}/${_startDate.month} - ${endDate.day}/${endDate.month}/${endDate.year}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              setState(() => _startDate = _startDate.subtract(const Duration(days: 7)));
              _loadCalendarData();
            },
            icon: const Icon(Icons.chevron_left),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey[100],
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _startDate = DateTime.now().subtract(const Duration(days: 1)));
                _loadCalendarData();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    Text(
                      dateRange,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Tik voor vandaag',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() => _startDate = _startDate.add(const Duration(days: 7)));
              _loadCalendarData();
            },
            icon: const Icon(Icons.chevron_right),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey[100],
            ),
          ),
          const SizedBox(width: 8),
          // Days selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<int>(
              value: _daysToShow,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 7, child: Text('7 dagen')),
                DropdownMenuItem(value: 14, child: Text('14 dagen')),
                DropdownMenuItem(value: 21, child: Text('21 dagen')),
                DropdownMenuItem(value: 28, child: Text('28 dagen')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _daysToShow = value);
                  _loadCalendarData();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.home_work_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Geen accommodaties',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final dates = List.generate(
      _daysToShow,
      (i) => _startDate.add(Duration(days: i)),
    );

    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        children: [
          // Date header
          _buildDateHeader(dates),

          // Accommodation rows
          ..._accommodations.map((acc) => _buildAccommodationRow(acc, dates)),
        ],
      ),
    );
  }

  Widget _buildDateHeader(List<DateTime> dates) {
    return Container(
      height: 52,
      margin: const EdgeInsets.only(left: 100),
      child: Row(
        children: dates.map((date) {
          final isToday = _isToday(date);
          final isWeekend = date.weekday >= 6;

          return Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isToday
                    ? AppTheme.primaryColor
                    : isWeekend
                        ? Colors.grey[200]
                        : Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.grey[300]!),
                  right: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getDayName(date.weekday),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isToday ? Colors.white : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                      color: isToday ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAccommodationRow(dynamic accommodation, List<DateTime> dates) {
    final accId = accommodation['id'];
    final accColor = _parseColor(accommodation['color']);

    final accBookings = _bookings.where((b) => b['accommodation_id'] == accId).toList();
    final accBlocked = _blockedDates.where((b) => b['accommodation_id'] == accId).toList();

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          // Accommodation name
          Container(
            width: 100,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(
                right: BorderSide(color: Colors.grey[300]!),
                left: BorderSide(color: accColor, width: 4),
              ),
            ),
            child: Text(
              accommodation['name'] ?? '',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Days grid with bookings
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cellWidth = constraints.maxWidth / _daysToShow;
                return Stack(
                  children: [
                    // Background cells
                    Row(
                      children: dates.map((date) {
                        final isToday = _isToday(date);
                        final isWeekend = date.weekday >= 6;
                        return Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: isToday
                                  ? AppTheme.primaryColor.withOpacity(0.08)
                                  : isWeekend
                                      ? Colors.grey[100]
                                      : Colors.transparent,
                              border: Border(
                                right: BorderSide(color: Colors.grey[200]!),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    // Blocked dates
                    ...accBlocked.map((blocked) =>
                        _buildEventBar(blocked, dates, cellWidth, isBlocked: true)),

                    // Bookings
                    ...accBookings.map((booking) =>
                        _buildEventBar(booking, dates, cellWidth, isBlocked: false)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventBar(
    dynamic event,
    List<DateTime> dates,
    double cellWidth, {
    required bool isBlocked,
  }) {
    final DateTime startDate;
    final DateTime endDate;
    final String label;
    final Color color;

    if (isBlocked) {
      startDate = DateTime.parse(event['start_date']);
      endDate = DateTime.parse(event['end_date']);
      final source = event['source'] ?? '';
      if (source == 'airbnb') {
        color = AppTheme.sourceAirbnb;
        label = 'Airbnb';
      } else if (source == 'booking') {
        color = AppTheme.sourceBooking;
        label = 'Booking';
      } else {
        color = Colors.grey;
        label = event['reason'] ?? 'Geblokkeerd';
      }
    } else {
      startDate = DateTime.parse(event['check_in']);
      endDate = DateTime.parse(event['check_out']);
      label = event['guest_name'] ?? '';
      color = _parseColor(event['color']);
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

    final startsBeforeView = startOffset < 0;
    final endsAfterView = (startOffset + duration) > _daysToShow;

    return Positioned(
      left: visibleStart * cellWidth + 2,
      top: 10,
      child: GestureDetector(
        onTap: isBlocked ? null : () => _showBookingDetails(event),
        child: Container(
          width: visibleDuration * cellWidth - 4,
          height: 36,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.85)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.horizontal(
              left: startsBeforeView ? Radius.zero : const Radius.circular(6),
              right: endsAfterView ? Radius.zero : const Radius.circular(6),
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _legendItem(AppTheme.paymentPaid, 'Betaald'),
            _legendItem(AppTheme.paymentPartial, 'Aanbetaald'),
            _legendItem(AppTheme.paymentUnpaid, 'Openstaand'),
            _legendItem(AppTheme.sourceAirbnb, 'Airbnb'),
            _legendItem(AppTheme.sourceBooking, 'Booking'),
            _legendItem(Colors.grey, 'Geblokkeerd'),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  void _showBookingDetails(dynamic booking) {
    final color = _parseColor(booking['color']);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
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

              // Guest name with color
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking['guest_name'] ?? 'Onbekende gast',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _getStatusLabel(booking['status']),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Details
              _detailRow(Icons.login, 'Check-in', _formatDisplayDate(booking['check_in'])),
              _detailRow(Icons.logout, 'Check-out', _formatDisplayDate(booking['check_out'])),
              _detailRow(Icons.euro, 'Betaling', _getPaymentLabel(booking['payment_status'])),
              _detailRow(Icons.source, 'Bron', _getSourceLabel(booking['source'])),

              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: Colors.grey[600]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) return Colors.grey;
    try {
      final hex = colorHex.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  String _getDayName(int weekday) {
    const days = ['', 'Ma', 'Di', 'Wo', 'Do', 'Vr', 'Za', 'Zo'];
    return days[weekday];
  }

  String _formatDisplayDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      const weekdays = ['', 'Ma', 'Di', 'Wo', 'Do', 'Vr', 'Za', 'Zo'];
      return '${weekdays[date.weekday]} ${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  String _getStatusLabel(String? status) {
    switch (status) {
      case 'confirmed': return 'Bevestigd';
      case 'option': return 'Optie';
      case 'inquiry': return 'Aanvraag';
      case 'cancelled': return 'Geannuleerd';
      case 'completed': return 'Afgerond';
      default: return status ?? 'Onbekend';
    }
  }

  String _getPaymentLabel(String? status) {
    switch (status) {
      case 'paid': return 'Volledig betaald';
      case 'partial': return 'Aanbetaald';
      case 'unpaid': return 'Openstaand';
      default: return status ?? 'Onbekend';
    }
  }

  String _getSourceLabel(String? source) {
    switch (source) {
      case 'direct': return 'Direct';
      case 'airbnb': return 'Airbnb';
      case 'booking': return 'Booking.com';
      case 'vrbo': return 'VRBO';
      default: return source ?? 'Onbekend';
    }
  }
}
