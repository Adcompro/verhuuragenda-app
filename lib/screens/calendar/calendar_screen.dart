import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../config/theme.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalender'),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            locale: 'nl_NL',
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
            ),
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
    // TODO: Load bookings for selected day from API
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
}
