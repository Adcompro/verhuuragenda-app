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

          // Timeline - tappable booking bars
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              height: 50,
              child: _buildTimeline(accBookings, accBlocked),
            ),
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
          clipBehavior: Clip.none,
          children: [
            // Day indicators (IgnorePointer allows touches to pass through to booking bars)
            IgnorePointer(
              child: Row(
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
      width: visibleDuration * cellWidth - 2,
      height: 28,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: isBlocked ? null : () {
          debugPrint('Booking tapped: ${event['guest_name']}');
          _showBookingDetails(event);
        },
        child: Container(
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
    final adults = booking['adults'] ?? 0;
    final children = booking['children'] ?? 0;
    final babies = booking['babies'] ?? 0;
    final hasPet = booking['has_pet'] == true;
    final petDescription = booking['pet_description'];
    final totalAmount = (booking['total_amount'] ?? 0).toDouble();
    final paidAmount = (booking['paid_amount'] ?? 0).toDouble();
    final remainingAmount = (booking['remaining_amount'] ?? 0).toDouble();
    final notes = booking['internal_notes'];
    final nights = booking['nights'] ?? 0;
    final accommodationName = booking['accommodation_name'] ?? '';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.person, color: Colors.white, size: 28),
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
                                      accommodationName,
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                              _buildStatusBadge(booking['status']),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Dates section
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
                                      Icon(Icons.login_rounded, color: AppTheme.successColor),
                                      const SizedBox(height: 8),
                                      const Text('Check-in', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatDisplayDate(booking['check_in']),
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '$nights nachten',
                                    style: TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    children: [
                                      Icon(Icons.logout_rounded, color: AppTheme.accentColor),
                                      const SizedBox(height: 8),
                                      const Text('Check-out', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatDisplayDate(booking['check_out']),
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Guests section
                          const Text(
                            'Gasten',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              _guestChip(Icons.person, '$adults volwassenen'),
                              if (children > 0) _guestChip(Icons.child_care, '$children kinderen'),
                              if (babies > 0) _guestChip(Icons.baby_changing_station, '$babies baby\'s'),
                              if (hasPet) _guestChip(Icons.pets, petDescription ?? 'Huisdier'),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Payment section
                          const Text(
                            'Betaling',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Column(
                              children: [
                                _paymentRow('Totaalbedrag', totalAmount, isBold: true),
                                const Divider(height: 20),
                                _paymentRow('Betaald', paidAmount, color: AppTheme.successColor),
                                _paymentRow('Nog te betalen', remainingAmount,
                                  color: remainingAmount > 0 ? Colors.red : AppTheme.successColor,
                                  isBold: true,
                                ),
                              ],
                            ),
                          ),

                          // Add payment button
                          if (remainingAmount > 0) ...[
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _showAddPaymentDialog(booking);
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Betaling toevoegen'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  backgroundColor: AppTheme.successColor,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],

                          // Notes section
                          if (notes != null && notes.toString().isNotEmpty) ...[
                            const SizedBox(height: 24),
                            const Text(
                              'Notities',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.amber[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.amber[200]!),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.note, color: Colors.amber[700], size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      notes.toString(),
                                      style: TextStyle(color: Colors.amber[900]),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 24),

                          // View full details button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                // Navigate to booking detail
                                final bookingId = booking['id'];
                                if (bookingId != null) {
                                  Navigator.pushNamed(context, '/bookings/$bookingId');
                                }
                              },
                              icon: const Icon(Icons.open_in_full),
                              label: const Text('Bekijk volledige boeking'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusBadge(String? status) {
    Color color;
    String label;
    switch (status) {
      case 'confirmed':
        color = AppTheme.successColor;
        label = 'Bevestigd';
        break;
      case 'option':
        color = Colors.orange;
        label = 'Optie';
        break;
      case 'inquiry':
        color = Colors.blue;
        label = 'Aanvraag';
        break;
      default:
        color = Colors.grey;
        label = status ?? 'Onbekend';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _guestChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentRow(String label, double amount, {Color? color, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(
            '€ ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
              fontSize: isBold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddPaymentDialog(dynamic booking) {
    final amountController = TextEditingController();
    final remainingAmount = (booking['remaining_amount'] ?? 0).toDouble();
    String paymentMethod = 'bank_transfer';
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Betaling toevoegen'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nog te betalen: € ${remainingAmount.toStringAsFixed(2)}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Bedrag',
                  prefixText: '€ ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: paymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Betaalmethode',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'bank_transfer', child: Text('Bankoverschrijving')),
                  DropdownMenuItem(value: 'cash', child: Text('Contant')),
                  DropdownMenuItem(value: 'ideal', child: Text('iDEAL')),
                  DropdownMenuItem(value: 'creditcard', child: Text('Creditcard')),
                  DropdownMenuItem(value: 'other', child: Text('Anders')),
                ],
                onChanged: (value) {
                  setState(() => paymentMethod = value ?? 'bank_transfer');
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Annuleren'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      final amount = double.tryParse(
                        amountController.text.replaceAll(',', '.'),
                      );
                      if (amount == null || amount <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Voer een geldig bedrag in'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      setState(() => isLoading = true);

                      try {
                        await ApiClient.instance.post(
                          '${ApiConfig.bookings}/${booking['id']}/payments',
                          data: {
                            'amount': amount,
                            'method': paymentMethod,
                            'paid_at': DateTime.now().toIso8601String(),
                          },
                        );

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Betaling toegevoegd'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          // Reload calendar data
                          _loadCalendarData();
                        }
                      } catch (e) {
                        setState(() => isLoading = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Kon betaling niet toevoegen'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Toevoegen'),
            ),
          ],
        ),
      ),
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
