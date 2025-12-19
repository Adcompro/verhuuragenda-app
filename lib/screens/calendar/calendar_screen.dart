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

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 2));
  final int _daysToShow = 21; // 3 weeks

  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadCalendarData();
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  Future<void> _loadCalendarData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final endDate = _startDate.add(Duration(days: _daysToShow));
      final response = await ApiClient.instance.get(
        '${ApiConfig.calendar}?start=${_formatDate(_startDate)}&end=${_formatDate(endDate)}',
      );

      final data = response.data;
      List<dynamic> accommodations = [];
      List<dynamic> bookings = [];
      List<dynamic> blockedDates = [];

      if (data is Map) {
        accommodations = data['accommodations'] ?? [];
        bookings = data['bookings'] ?? [];
        blockedDates = data['blocked_dates'] ?? [];
      }

      setState(() {
        _accommodations = accommodations;
        _bookings = bookings;
        _blockedDates = blockedDates;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Kon kalender niet laden: $e';
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _goToPreviousWeek() {
    setState(() {
      _startDate = _startDate.subtract(const Duration(days: 7));
    });
    _loadCalendarData();
  }

  void _goToNextWeek() {
    setState(() {
      _startDate = _startDate.add(const Duration(days: 7));
    });
    _loadCalendarData();
  }

  void _goToToday() {
    setState(() {
      _startDate = DateTime.now().subtract(const Duration(days: 2));
    });
    _loadCalendarData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalender'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _goToPreviousWeek,
            tooltip: 'Vorige week',
          ),
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: _goToToday,
            tooltip: 'Vandaag',
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _goToNextWeek,
            tooltip: 'Volgende week',
          ),
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
              : _buildCalendarView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(_error!, style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadCalendarData,
            child: const Text('Opnieuw proberen'),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarView() {
    const double accommodationColumnWidth = 120;
    const double dayCellWidth = 45;
    const double rowHeight = 60;

    final dates = List.generate(
      _daysToShow,
      (i) => _startDate.add(Duration(days: i)),
    );

    // Build month spans
    final monthSpans = _buildMonthSpans(dates);

    return Column(
      children: [
        // Month header row
        SizedBox(
          height: 24,
          child: Row(
            children: [
              Container(
                width: accommodationColumnWidth,
                color: AppTheme.primaryColor,
                alignment: Alignment.center,
                child: const Text(
                  'Accommodatie',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  child: Row(
                    children: monthSpans.map((span) {
                      return Container(
                        width: span['days'] * dayCellWidth,
                        color: AppTheme.primaryColor,
                        alignment: Alignment.center,
                        child: Text(
                          '${_getMonthNameFull(span['month'])} ${span['year']}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Header with dates
        SizedBox(
          height: 40,
          child: Row(
            children: [
              // Empty corner cell
              Container(
                width: accommodationColumnWidth,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[300]!),
                    right: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
              ),
              // Date headers
              Expanded(
                child: SingleChildScrollView(
                  controller: _horizontalController,
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: dates.map((date) {
                      final isToday = _isToday(date);
                      final isWeekend = date.weekday >= 6;
                      final isMonday = date.weekday == 1;
                      return Container(
                        width: dayCellWidth,
                        decoration: BoxDecoration(
                          color: isToday
                              ? AppTheme.primaryColor.withOpacity(0.15)
                              : isWeekend
                                  ? Colors.grey[100]
                                  : Colors.white,
                          border: Border(
                            bottom: BorderSide(color: Colors.grey[300]!),
                            left: isMonday
                                ? BorderSide(color: AppTheme.primaryColor, width: 2)
                                : BorderSide.none,
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
                                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                color: isToday
                                    ? AppTheme.primaryColor
                                    : isWeekend
                                        ? Colors.grey[500]
                                        : Colors.grey[600],
                              ),
                            ),
                            Text(
                              '${date.day}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isToday
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isToday
                                    ? AppTheme.primaryColor
                                    : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Calendar body with accommodations and bookings
        Expanded(
          child: Row(
            children: [
              // Accommodation names column
              SizedBox(
                width: accommodationColumnWidth,
                child: ListView.builder(
                  controller: _verticalController,
                  itemCount: _accommodations.length,
                  itemBuilder: (context, index) {
                    final acc = _accommodations[index];
                    return Container(
                      height: rowHeight,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        border: Border(
                          bottom: BorderSide(color: Colors.grey[300]!),
                          right: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _parseColor(acc['color']),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              acc['name'] ?? '',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Bookings grid
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollUpdateNotification) {
                      _horizontalController.jumpTo(
                        (notification.metrics as ScrollMetrics).pixels,
                      );
                    }
                    return false;
                  },
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: dayCellWidth * _daysToShow,
                      child: ListView.builder(
                        itemCount: _accommodations.length,
                        itemBuilder: (context, accIndex) {
                          final acc = _accommodations[accIndex];
                          return _buildAccommodationRow(
                            acc,
                            dates,
                            rowHeight,
                            dayCellWidth,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccommodationRow(
    dynamic accommodation,
    List<DateTime> dates,
    double rowHeight,
    double cellWidth,
  ) {
    final accId = accommodation['id'];

    // Get bookings for this accommodation
    final accBookings = _bookings
        .where((b) => b['accommodation_id'] == accId)
        .toList();

    // Get blocked dates for this accommodation
    final accBlocked = _blockedDates
        .where((b) => b['accommodation_id'] == accId)
        .toList();

    return Container(
      height: rowHeight,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Stack(
        children: [
          // Day cell backgrounds
          Row(
            children: dates.map((date) {
              final isToday = _isToday(date);
              final isWeekend = date.weekday >= 6;
              return Container(
                width: cellWidth,
                decoration: BoxDecoration(
                  color: isToday
                      ? AppTheme.primaryColor.withOpacity(0.05)
                      : isWeekend
                          ? Colors.grey[50]
                          : Colors.white,
                  border: Border(
                    right: BorderSide(
                      color: date.weekday == 7
                          ? AppTheme.primaryColor.withOpacity(0.3)
                          : Colors.grey[200]!,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          // Blocked dates
          ...accBlocked.map((blocked) {
            return _buildBlockedBar(blocked, dates, cellWidth, rowHeight);
          }),

          // Booking bars
          ...accBookings.map((booking) {
            return _buildBookingBar(booking, dates, cellWidth, rowHeight);
          }),
        ],
      ),
    );
  }

  Widget _buildBookingBar(
    dynamic booking,
    List<DateTime> dates,
    double cellWidth,
    double rowHeight,
  ) {
    final checkIn = DateTime.parse(booking['check_in']);
    final checkOut = DateTime.parse(booking['check_out']);
    final startDay = DateTime(dates.first.year, dates.first.month, dates.first.day);

    // Calculate position
    final startOffset = checkIn.difference(startDay).inDays;
    final duration = checkOut.difference(checkIn).inDays;

    // Check if booking is visible in current date range
    if (startOffset + duration < 0 || startOffset >= _daysToShow) {
      return const SizedBox.shrink();
    }

    // Adjust for bookings that start before or end after visible range
    final visibleStart = startOffset < 0 ? 0 : startOffset;
    final visibleEnd = (startOffset + duration) > _daysToShow
        ? _daysToShow
        : (startOffset + duration);
    final visibleDuration = visibleEnd - visibleStart;

    if (visibleDuration <= 0) return const SizedBox.shrink();

    final color = _parseColor(booking['color']);
    final guestName = booking['guest_name'] ?? 'Onbekend';

    return Positioned(
      left: visibleStart * cellWidth + 2,
      top: 8,
      child: GestureDetector(
        onTap: () => _showBookingDetails(booking),
        child: Container(
          width: visibleDuration * cellWidth - 4,
          height: rowHeight - 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.horizontal(
              left: startOffset >= visibleStart
                  ? const Radius.circular(4)
                  : Radius.zero,
              right: (startOffset + duration) <= visibleEnd
                  ? const Radius.circular(4)
                  : Radius.zero,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                guestName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              if (visibleDuration > 2)
                Text(
                  '${checkIn.day}/${checkIn.month} - ${checkOut.day}/${checkOut.month}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 9,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlockedBar(
    dynamic blocked,
    List<DateTime> dates,
    double cellWidth,
    double rowHeight,
  ) {
    final startDate = DateTime.parse(blocked['start_date']);
    final endDate = DateTime.parse(blocked['end_date']);
    final startDay = DateTime(dates.first.year, dates.first.month, dates.first.day);

    final startOffset = startDate.difference(startDay).inDays;
    final duration = endDate.difference(startDate).inDays + 1;

    if (startOffset + duration < 0 || startOffset >= _daysToShow) {
      return const SizedBox.shrink();
    }

    final visibleStart = startOffset < 0 ? 0 : startOffset;
    final visibleEnd = (startOffset + duration) > _daysToShow
        ? _daysToShow
        : (startOffset + duration);
    final visibleDuration = visibleEnd - visibleStart;

    if (visibleDuration <= 0) return const SizedBox.shrink();

    final source = blocked['source'] ?? '';
    Color color;
    String label;

    if (source == 'airbnb') {
      color = AppTheme.sourceAirbnb;
      label = 'Airbnb';
    } else if (source == 'booking') {
      color = AppTheme.sourceBooking;
      label = 'Booking.com';
    } else {
      color = Colors.grey;
      label = blocked['reason'] ?? 'Geblokkeerd';
    }

    return Positioned(
      left: visibleStart * cellWidth + 2,
      top: 8,
      child: Container(
        width: visibleDuration * cellWidth - 4,
        height: rowHeight - 16,
        decoration: BoxDecoration(
          color: color.withOpacity(0.8),
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  void _showBookingDetails(dynamic booking) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final color = _parseColor(booking['color']);
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      booking['guest_name'] ?? 'Onbekende gast',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDetailRow(Icons.calendar_today, 'Check-in', booking['check_in']),
              _buildDetailRow(Icons.calendar_today, 'Check-out', booking['check_out']),
              _buildDetailRow(
                Icons.info_outline,
                'Status',
                _getStatusLabel(booking['status']),
              ),
              _buildDetailRow(
                Icons.euro,
                'Betaling',
                _getPaymentLabel(booking['payment_status']),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(color: Colors.grey[600]),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
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
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String _getDayName(int weekday) {
    const days = ['', 'Ma', 'Di', 'Wo', 'Do', 'Vr', 'Za', 'Zo'];
    return days[weekday];
  }

  String _getMonthName(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mrt', 'Apr', 'Mei', 'Jun',
      'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dec'
    ];
    return months[month];
  }

  String _getMonthNameFull(int month) {
    const months = [
      '', 'Januari', 'Februari', 'Maart', 'April', 'Mei', 'Juni',
      'Juli', 'Augustus', 'September', 'Oktober', 'November', 'December'
    ];
    return months[month];
  }

  List<Map<String, dynamic>> _buildMonthSpans(List<DateTime> dates) {
    final spans = <Map<String, dynamic>>[];
    if (dates.isEmpty) return spans;

    int currentMonth = dates.first.month;
    int currentYear = dates.first.year;
    int dayCount = 0;

    for (final date in dates) {
      if (date.month == currentMonth && date.year == currentYear) {
        dayCount++;
      } else {
        spans.add({'month': currentMonth, 'year': currentYear, 'days': dayCount});
        currentMonth = date.month;
        currentYear = date.year;
        dayCount = 1;
      }
    }
    // Add the last span
    spans.add({'month': currentMonth, 'year': currentYear, 'days': dayCount});

    return spans;
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
      case 'completed':
        return 'Afgerond';
      default:
        return status ?? 'Onbekend';
    }
  }

  String _getPaymentLabel(String? status) {
    switch (status) {
      case 'paid':
        return 'Volledig betaald';
      case 'partial':
        return 'Aanbetaald';
      case 'unpaid':
        return 'Openstaand';
      default:
        return status ?? 'Onbekend';
    }
  }
}
