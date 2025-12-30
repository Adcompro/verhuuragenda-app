import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../config/theme.dart';
import '../../core/api/api_client.dart';
import '../../config/api_config.dart';
import '../../utils/responsive.dart';

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

  // Dynamically determine days to show based on screen size
  int _getDaysToShow(BuildContext context) {
    if (Responsive.isDesktop(context)) return 28;
    if (Responsive.isTablet(context)) return 21;
    return 14;
  }

  @override
  void initState() {
    super.initState();
    _loadCalendarData();
  }

  Future<void> _loadCalendarData({int? daysToLoad}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Use provided days or default to 28 for max coverage
      final days = daysToLoad ?? 28;
      final endDate = _startDate.add(Duration(days: days + 7));
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorView(l10n)
                : _buildContent(),
      ),
    );
  }

  Widget _buildErrorView(AppLocalizations l10n) {
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
            Text(
              l10n.couldNotLoad,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
              label: Text(l10n.retryShort),
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
    final daysToShow = _getDaysToShow(context);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        _buildHeader(l10n),
        _buildQuickStats(l10n),
        _buildDateNav(daysToShow, l10n),
        Expanded(
          child: _accommodations.isEmpty
              ? _buildEmptyState(l10n)
              : _buildAccommodationCards(daysToShow),
        ),
      ],
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.occupancyTitle,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1D26),
                  ),
                ),
                Text(
                  l10n.accommodationsCountText(_accommodations.length),
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

  Widget _buildQuickStats(AppLocalizations l10n) {
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
            l10n.occupied,
            AppTheme.primaryColor,
          ),
          const SizedBox(width: 12),
          _statChip(
            Icons.login_rounded,
            '$checkInsToday',
            l10n.checkIn,
            AppTheme.successColor,
          ),
          const SizedBox(width: 12),
          _statChip(
            Icons.logout_rounded,
            '$checkOutsToday',
            l10n.checkOut,
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

  Widget _buildDateNav(int daysToShow, AppLocalizations l10n) {
    final isWide = Responsive.useWideLayout(context);
    final horizontalMargin = isWide ? 24.0 : 20.0;

    return Container(
      margin: EdgeInsets.fromLTRB(horizontalMargin, 8, horizontalMargin, 12),
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
                      _getDateRangeText(daysToShow),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: isWide ? 16 : 15,
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
                        isWide ? l10n.daysViewText(daysToShow) : l10n.tapForToday,
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

  String _getDateRangeText(int daysToShow) {
    final endDate = _startDate.add(Duration(days: daysToShow - 1));
    final months = ['', 'jan', 'feb', 'mrt', 'apr', 'mei', 'jun', 'jul', 'aug', 'sep', 'okt', 'nov', 'dec'];

    if (_startDate.month == endDate.month) {
      return '${_startDate.day} - ${endDate.day} ${months[endDate.month]}';
    } else {
      return '${_startDate.day} ${months[_startDate.month]} - ${endDate.day} ${months[endDate.month]}';
    }
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.villa_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            l10n.noAccommodationsShort,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccommodationCards(int daysToShow) {
    final isWide = Responsive.useWideLayout(context);
    final horizontalPadding = isWide ? 24.0 : 20.0;

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 20),
      itemCount: _accommodations.length,
      itemBuilder: (context, index) {
        return _buildAccommodationCard(_accommodations[index], daysToShow);
      },
    );
  }

  Widget _buildAccommodationCard(dynamic accommodation, int daysToShow) {
    final l10n = AppLocalizations.of(context)!;
    final accId = accommodation['id'];
    final accColor = _parseColor(accommodation['color']);
    final accBookings = _bookings.where((b) => b['accommodation_id'] == accId).toList();
    final accBlocked = _blockedDates.where((b) => b['accommodation_id'] == accId).toList();
    final isWide = Responsive.useWideLayout(context);
    final timelineHeight = isWide ? 60.0 : 50.0;

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
            padding: EdgeInsets.all(isWide ? 20 : 16),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: accColor, width: 4),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: isWide ? 48 : 40,
                  height: isWide ? 48 : 40,
                  decoration: BoxDecoration(
                    color: accColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.home_rounded, color: accColor, size: isWide ? 26 : 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    accommodation['name'] ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: isWide ? 18 : 16,
                    ),
                  ),
                ),
                _getStatusBadge(accBookings, accBlocked, l10n),
              ],
            ),
          ),

          // Timeline with tappable booking bars
          Padding(
            padding: EdgeInsets.fromLTRB(isWide ? 20 : 16, 0, isWide ? 20 : 16, isWide ? 20 : 16),
            child: SizedBox(
              height: timelineHeight,
              child: _buildTimeline(
                accBookings,
                accBlocked,
                daysToShow,
                accommodationId: accId,
                accommodationName: accommodation['name'] ?? '',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getStatusBadge(List<dynamic> bookings, List<dynamic> blocked, AppLocalizations l10n) {
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
                  l10n.occupied,
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
            l10n.availableStatus,
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

  Widget _buildTimeline(List<dynamic> bookings, List<dynamic> blocked, int daysToShow, {required int accommodationId, required String accommodationName}) {
    final dates = List.generate(
      daysToShow,
      (i) => _startDate.add(Duration(days: i)),
    );
    final isWide = Responsive.useWideLayout(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = constraints.maxWidth / daysToShow;
        final startDay = DateTime(dates.first.year, dates.first.month, dates.first.day);

        // Pre-calculate booking positions for hit testing
        final bookingRects = <Map<String, dynamic>>[];
        for (final booking in bookings) {
          final eventStart = DateTime.parse(booking['check_in']);
          final eventEnd = DateTime.parse(booking['check_out']);
          final startOffset = eventStart.difference(startDay).inDays;
          final duration = eventEnd.difference(eventStart).inDays;

          if (startOffset + duration >= 0 && startOffset < daysToShow) {
            final visibleStart = startOffset < 0 ? 0 : startOffset;
            final visibleEnd = (startOffset + duration) > daysToShow ? daysToShow : (startOffset + duration);
            if (visibleEnd > visibleStart) {
              bookingRects.add({
                'booking': booking,
                'left': visibleStart * cellWidth,
                'right': visibleEnd * cellWidth,
              });
            }
          }
        }

        return Column(
          children: [
            // Day numbers row
            Row(
              children: dates.map((date) {
                final isToday = _isToday(date);
                return SizedBox(
                  width: cellWidth,
                  child: Text(
                    '${date.day}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isWide ? 11 : 10,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                      color: isToday ? AppTheme.primaryColor : Colors.grey[500],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 4),
            // Timeline bars with single GestureDetector
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) {
                  final tapX = details.localPosition.dx;

                  // Check if tap is on a booking (check in reverse order - top bookings first)
                  for (final rect in bookingRects.reversed) {
                    if (tapX >= rect['left'] && tapX < rect['right']) {
                      _showBookingDetails(rect['booking']);
                      return;
                    }
                  }

                  // Not on a booking - create new booking for the tapped day
                  final dayIndex = (tapX / cellWidth).floor().clamp(0, daysToShow - 1);
                  final date = dates[dayIndex];
                  _showNewBookingDialog(date, accommodationId, accommodationName);
                },
                child: Stack(
                  children: [
                    // Day backgrounds (visual only, no gesture detection)
                    Row(
                      children: dates.map((date) {
                        final isToday = _isToday(date);
                        final isWeekend = date.weekday >= 6;
                        return Expanded(
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
                        );
                      }).toList(),
                    ),
                    // Blocked dates (visual only)
                    ...blocked.map((b) => _buildBar(b, startDay, cellWidth, daysToShow, isBlocked: true)),
                    // Bookings (visual only)
                    ...bookings.map((b) => _buildBar(b, startDay, cellWidth, daysToShow, isBlocked: false)),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showNewBookingDialog(DateTime checkInDate, int accommodationId, String accommodationName) {
    final l10n = AppLocalizations.of(context)!;
    DateTime checkOutDate = checkInDate.add(const Duration(days: 7));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final sheetL10n = AppLocalizations.of(context)!;
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  Text(
                    sheetL10n.newBooking,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    accommodationName,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),

                  const SizedBox(height: 24),

                  // Check-in date
                  Text(sheetL10n.checkIn, style: const TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: checkInDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 730)),
                      );
                      if (picked != null) {
                        setState(() {
                          checkInDate = picked;
                          if (checkOutDate.isBefore(checkInDate) || checkOutDate.isAtSameMomentAs(checkInDate)) {
                            checkOutDate = checkInDate.add(const Duration(days: 1));
                          }
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                          const SizedBox(width: 12),
                          Text(
                            _formatDisplayDate(_formatDate(checkInDate)),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Check-out date
                  Text(sheetL10n.checkOut, style: const TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: checkOutDate,
                        firstDate: checkInDate.add(const Duration(days: 1)),
                        lastDate: DateTime.now().add(const Duration(days: 730)),
                      );
                      if (picked != null) {
                        setState(() => checkOutDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: AppTheme.accentColor),
                          const SizedBox(width: 12),
                          Text(
                            _formatDisplayDate(_formatDate(checkOutDate)),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                  Text(
                    sheetL10n.nightsCount(checkOutDate.difference(checkInDate).inDays),
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),

                  const SizedBox(height: 24),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(sheetL10n.cancel),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            // Navigate to booking form with pre-filled dates
                            context.push(
                              '/bookings/new?accommodation_id=$accommodationId&check_in=${_formatDate(checkInDate)}&check_out=${_formatDate(checkOutDate)}',
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(sheetL10n.continueText),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBar(dynamic event, DateTime startDay, double cellWidth, int daysToShow, {required bool isBlocked}) {
    final l10n = AppLocalizations.of(context)!;
    final DateTime eventStart;
    final DateTime eventEnd;
    final Color color;
    final String label;
    final isWide = Responsive.useWideLayout(context);

    if (isBlocked) {
      eventStart = DateTime.parse(event['start_date']);
      eventEnd = DateTime.parse(event['end_date']);
      final source = event['source'] ?? '';
      color = _getSourceColor(source);
      label = _getSourceLabel(source, l10n);
    } else {
      eventStart = DateTime.parse(event['check_in']);
      eventEnd = DateTime.parse(event['check_out']);
      color = _parseColor(event['color']);
      label = event['guest_name'] ?? '';
    }

    final startOffset = eventStart.difference(startDay).inDays;
    final duration = eventEnd.difference(eventStart).inDays + (isBlocked ? 1 : 0);

    if (startOffset + duration < 0 || startOffset >= daysToShow) {
      return const SizedBox.shrink();
    }

    final visibleStart = startOffset < 0 ? 0 : startOffset;
    final visibleEnd = (startOffset + duration) > daysToShow ? daysToShow : (startOffset + duration);
    final visibleDuration = visibleEnd - visibleStart;

    if (visibleDuration <= 0) return const SizedBox.shrink();

    final barWidth = visibleDuration * cellWidth - 2;

    // Visual only - tap handling is done in _buildTimeline
    return Positioned(
      left: visibleStart * cellWidth + 1,
      top: 2,
      bottom: 2,
      width: barWidth,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  void _showBookingDetails(dynamic booking) {
    final l10n = AppLocalizations.of(context)!;
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
        final sheetL10n = AppLocalizations.of(context)!;
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
                                      booking['guest_name'] ?? sheetL10n.unknown,
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
                              _buildStatusBadge(booking['status'], sheetL10n),
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
                                      Text(sheetL10n.checkIn, style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
                                    sheetL10n.nightsCount(nights),
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
                                      Text(sheetL10n.checkOut, style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
                          Text(
                            sheetL10n.guestsSection,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              _guestChip(Icons.person, sheetL10n.adultsCount(adults)),
                              if (children > 0) _guestChip(Icons.child_care, sheetL10n.childrenCount(children)),
                              if (babies > 0) _guestChip(Icons.baby_changing_station, sheetL10n.babiesCount(babies)),
                              if (hasPet) _guestChip(Icons.pets, petDescription ?? sheetL10n.pet),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Payment section
                          Text(
                            sheetL10n.payment,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                                _paymentRow(sheetL10n.totalAmount, totalAmount, isBold: true),
                                const Divider(height: 20),
                                _paymentRow(sheetL10n.paid, paidAmount, color: AppTheme.successColor),
                                _paymentRow(sheetL10n.stillToPay, remainingAmount,
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
                                label: Text(sheetL10n.addPayment),
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
                            Text(
                              sheetL10n.notes,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                                  context.push('/bookings/$bookingId');
                                }
                              },
                              icon: const Icon(Icons.open_in_full),
                              label: Text(sheetL10n.viewFullBooking),
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

  Widget _buildStatusBadge(String? status, AppLocalizations l10n) {
    Color color;
    String label;
    switch (status) {
      case 'confirmed':
        color = AppTheme.successColor;
        label = l10n.confirmed;
        break;
      case 'option':
        color = Colors.orange;
        label = l10n.option;
        break;
      case 'inquiry':
        color = Colors.blue;
        label = l10n.inquiry;
        break;
      case 'completed':
        color = AppTheme.successColor;
        label = l10n.completed;
        break;
      case 'cancelled':
        color = Colors.red;
        label = l10n.cancelled;
        break;
      default:
        color = Colors.grey;
        label = status ?? l10n.unknown;
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
    final l10n = AppLocalizations.of(context)!;
    final amountController = TextEditingController();
    final remainingAmount = (booking['remaining_amount'] ?? 0).toDouble();
    String paymentMethod = 'bank_transfer';
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        final dialogL10n = AppLocalizations.of(context)!;
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text(dialogL10n.addPayment),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${dialogL10n.stillToPay}: € ${remainingAmount.toStringAsFixed(2)}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: dialogL10n.amount,
                    prefixText: '€ ',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: paymentMethod,
                  decoration: InputDecoration(
                    labelText: dialogL10n.paymentMethod,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(value: 'bank_transfer', child: Text(dialogL10n.bankTransfer)),
                    DropdownMenuItem(value: 'cash', child: Text(dialogL10n.cash)),
                    DropdownMenuItem(value: 'ideal', child: Text(dialogL10n.ideal)),
                    DropdownMenuItem(value: 'creditcard', child: Text(dialogL10n.creditCard)),
                    DropdownMenuItem(value: 'other', child: Text(dialogL10n.other)),
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
                child: Text(dialogL10n.cancel),
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
                            SnackBar(
                              content: Text(dialogL10n.enterValidAmount),
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
                              SnackBar(
                                content: Text(dialogL10n.paymentAdded),
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
                              SnackBar(
                                content: Text(dialogL10n.couldNotAddPayment),
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
                    : Text(dialogL10n.add),
              ),
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

  String _formatShortDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}';
    } catch (e) {
      return dateStr;
    }
  }

  String _getStatusLabel(String? status, AppLocalizations l10n) {
    switch (status) {
      case 'confirmed': return l10n.confirmed;
      case 'option': return l10n.option;
      case 'inquiry': return l10n.inquiry;
      case 'completed': return l10n.completed;
      case 'cancelled': return l10n.cancelled;
      default: return status ?? l10n.unknown;
    }
  }

  String _getPaymentLabel(String? status, AppLocalizations l10n) {
    switch (status) {
      case 'paid': return l10n.paid;
      case 'partial': return l10n.partiallyPaid;
      case 'unpaid': return l10n.unpaid;
      default: return status ?? '-';
    }
  }

  Color _getSourceColor(String source) {
    switch (source) {
      case 'airbnb': return const Color(0xFFFF5A5F);   // Airbnb rood/roze
      case 'booking': return const Color(0xFF003580); // Booking.com donkerblauw
      case 'vrbo': return const Color(0xFF0E55E5);    // Vrbo blauw
      case 'holidu': return const Color(0xFF6B21A8);  // Holidu paars
      case 'google': return const Color(0xFF4285F4);  // Google blauw
      case 'belvilla': return const Color(0xFFE87722); // Belvilla oranje
      default: return Colors.grey;
    }
  }

  String _getSourceLabel(String source, AppLocalizations l10n) {
    switch (source) {
      case 'airbnb': return 'Airbnb';
      case 'booking': return 'Booking';
      case 'vrbo': return 'Vrbo';
      case 'holidu': return 'Holidu';
      case 'google': return 'Google';
      case 'belvilla': return 'Belvilla';
      default: return l10n.blocked;
    }
  }
}
