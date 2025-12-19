import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../config/theme.dart';
import '../../core/api/api_client.dart';
import '../../config/api_config.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  List<dynamic> _bookings = [];
  Map<int, String> _accommodationNames = {};
  bool _isLoading = true;
  String? _error;

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
      final response = await ApiClient.instance.get(ApiConfig.calendar);
      final accommodations = response.data['accommodations'] ?? [];
      final Map<int, String> accNames = {};
      for (var acc in accommodations) {
        accNames[acc['id']] = acc['name'] ?? '';
      }
      setState(() {
        _bookings = response.data['bookings'] ?? [];
        _accommodationNames = accNames;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Kon kalender niet laden';
        _isLoading = false;
      });
    }
  }

  List<dynamic> _getBookingsForDay(DateTime day) {
    return _bookings.where((booking) {
      try {
        final checkIn = DateTime.parse(booking['check_in']);
        final checkOut = DateTime.parse(booking['check_out']);
        final dayOnly = DateTime(day.year, day.month, day.day);
        final checkInOnly = DateTime(checkIn.year, checkIn.month, checkIn.day);
        final checkOutOnly = DateTime(checkOut.year, checkOut.month, checkOut.day);

        return (dayOnly.isAtSameMomentAs(checkInOnly) || dayOnly.isAfter(checkInOnly)) &&
               (dayOnly.isAtSameMomentAs(checkOutOnly) || dayOnly.isBefore(checkOutOnly));
      } catch (e) {
        return false;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalender'),
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
              ? Center(
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
                )
              : Column(
                  children: [
                    TableCalendar(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      calendarFormat: _calendarFormat,
                      startingDayOfWeek: StartingDayOfWeek.monday,
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: true,
                        titleCentered: true,
                      ),
                      calendarStyle: CalendarStyle(
                        todayDecoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: const BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        markerDecoration: const BoxDecoration(
                          color: AppTheme.secondaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      eventLoader: _getBookingsForDay,
                      selectedDayPredicate: (day) {
                        return isSameDay(_selectedDay, day);
                      },
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      },
                      onFormatChanged: (format) {
                        setState(() {
                          _calendarFormat = format;
                        });
                      },
                      onPageChanged: (focusedDay) {
                        _focusedDay = focusedDay;
                      },
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: _selectedDay != null
                          ? _buildDayBookings()
                          : const Center(
                              child: Text('Selecteer een dag om boekingen te zien'),
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildDayBookings() {
    final dayBookings = _getBookingsForDay(_selectedDay!);

    if (dayBookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Geen boekingen op ${_selectedDay!.day}-${_selectedDay!.month}-${_selectedDay!.year}',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: dayBookings.length,
      itemBuilder: (context, index) {
        final booking = dayBookings[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getStatusColor(booking['status']).withOpacity(0.2),
              child: Icon(
                Icons.home,
                color: _getStatusColor(booking['status']),
              ),
            ),
            title: Text(booking['guest_name'] ?? 'Onbekende gast'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_accommodationNames[booking['accommodation_id']] ?? ''),
                Text(
                  '${booking['check_in']} - ${booking['check_out']}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            isThreeLine: true,
          ),
        );
      },
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
