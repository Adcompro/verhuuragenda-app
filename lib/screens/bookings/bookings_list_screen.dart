import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../core/api/api_client.dart';
import '../../config/api_config.dart';
import '../../models/booking.dart';

class BookingsListScreen extends StatefulWidget {
  const BookingsListScreen({super.key});

  @override
  State<BookingsListScreen> createState() => _BookingsListScreenState();
}

class _BookingsListScreenState extends State<BookingsListScreen> {
  List<Booking> _bookings = [];
  bool _isLoading = true;
  String? _error;
  String _statusFilter = 'all';
  String _periodFilter = 'upcoming'; // 'upcoming', 'all', 'past', 'custom'
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final queryParams = <String, dynamic>{
        'per_page': '100', // Load more bookings
      };

      if (_statusFilter != 'all') {
        queryParams['status'] = _statusFilter;
      }

      // Add date filters based on period
      final now = DateTime.now();
      switch (_periodFilter) {
        case 'upcoming':
          queryParams['from'] = _formatDateForApi(now.subtract(const Duration(days: 7)));
          break;
        case 'past':
          queryParams['to'] = _formatDateForApi(now);
          break;
        case 'custom':
          if (_startDate != null) {
            queryParams['from'] = _formatDateForApi(_startDate!);
          }
          if (_endDate != null) {
            queryParams['to'] = _formatDateForApi(_endDate!);
          }
          break;
        case 'all':
        default:
          // No date filter
          break;
      }

      final response = await ApiClient.instance.get(
        ApiConfig.bookings,
        queryParameters: queryParams,
      );

      // Handle both paginated and non-paginated responses
      List<dynamic> data;
      if (response.data is Map && response.data['data'] != null) {
        data = response.data['data'] as List;
      } else if (response.data is List) {
        data = response.data as List;
      } else {
        data = [];
      }

      setState(() {
        _bookings = data.map((json) => Booking.fromJson(json)).toList();
        // Sort by check-in date
        _bookings.sort((a, b) => a.checkIn.compareTo(b.checkIn));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Kon boekingen niet laden: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  String _formatDateForApi(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Boekingen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _showPeriodFilter,
            tooltip: 'Periode filter',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _statusFilter = value;
              });
              _loadBookings();
            },
            itemBuilder: (context) => [
              _buildFilterMenuItem('all', 'Alle statussen'),
              _buildFilterMenuItem('confirmed', 'Bevestigd'),
              _buildFilterMenuItem('option', 'Optie'),
              _buildFilterMenuItem('inquiry', 'Aanvraag'),
              _buildFilterMenuItem('cancelled', 'Geannuleerd'),
            ],
          ),
        ],
        bottom: _buildFilterChips(),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/bookings/new'),
        icon: const Icon(Icons.add),
        label: const Text('Nieuwe boeking'),
      ),
    );
  }

  PopupMenuItem<String> _buildFilterMenuItem(String value, String label) {
    final isSelected = _statusFilter == value;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          if (isSelected)
            Icon(Icons.check, size: 18, color: AppTheme.primaryColor)
          else
            const SizedBox(width: 18),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  PreferredSize _buildFilterChips() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(50),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _buildPeriodChip('upcoming', 'Aankomend'),
            const SizedBox(width: 8),
            _buildPeriodChip('all', 'Alles'),
            const SizedBox(width: 8),
            _buildPeriodChip('past', 'Afgelopen'),
            const SizedBox(width: 8),
            _buildPeriodChip('custom', 'Aangepast'),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodChip(String value, String label) {
    final isSelected = _periodFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (value == 'custom') {
          _showDateRangePicker();
        } else {
          setState(() {
            _periodFilter = value;
            _startDate = null;
            _endDate = null;
          });
          _loadBookings();
        }
      },
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryColor,
    );
  }

  void _showPeriodFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Periode selecteren',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.upcoming),
              title: const Text('Aankomende boekingen'),
              subtitle: const Text('Vanaf vandaag'),
              selected: _periodFilter == 'upcoming',
              onTap: () {
                Navigator.pop(context);
                setState(() => _periodFilter = 'upcoming');
                _loadBookings();
              },
            ),
            ListTile(
              leading: const Icon(Icons.all_inclusive),
              title: const Text('Alle boekingen'),
              subtitle: const Text('Zonder datumfilter'),
              selected: _periodFilter == 'all',
              onTap: () {
                Navigator.pop(context);
                setState(() => _periodFilter = 'all');
                _loadBookings();
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Afgelopen boekingen'),
              subtitle: const Text('Tot vandaag'),
              selected: _periodFilter == 'past',
              onTap: () {
                Navigator.pop(context);
                setState(() => _periodFilter = 'past');
                _loadBookings();
              },
            ),
            ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text('Aangepaste periode'),
              subtitle: Text(_startDate != null && _endDate != null
                  ? '${_formatDate(_startDate!)} - ${_formatDate(_endDate!)}'
                  : 'Kies een datumbereik'),
              selected: _periodFilter == 'custom',
              onTap: () {
                Navigator.pop(context);
                _showDateRangePicker();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDateRangePicker() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : DateTimeRange(
              start: now.subtract(const Duration(days: 365)),
              end: now.add(const Duration(days: 365)),
            ),
      locale: const Locale('nl', 'NL'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppTheme.primaryColor),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _periodFilter = 'custom';
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadBookings();
    }
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadBookings,
                icon: const Icon(Icons.refresh),
                label: const Text('Opnieuw proberen'),
              ),
            ],
          ),
        ),
      );
    }

    if (_bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Geen boekingen gevonden',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              _getPeriodDescription(),
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _bookings.length + 1, // +1 for the count header
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '${_bookings.length} boeking${_bookings.length == 1 ? '' : 'en'}',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            );
          }
          final booking = _bookings[index - 1];
          return _BookingCard(
            booking: booking,
            onTap: () => context.push('/bookings/${booking.id}'),
          );
        },
      ),
    );
  }

  String _getPeriodDescription() {
    switch (_periodFilter) {
      case 'upcoming':
        return 'voor aankomende periode';
      case 'past':
        return 'in afgelopen periode';
      case 'custom':
        if (_startDate != null && _endDate != null) {
          return 'van ${_formatDate(_startDate!)} tot ${_formatDate(_endDate!)}';
        }
        return '';
      default:
        return '';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}-${date.month}-${date.year}';
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback onTap;

  const _BookingCard({required this.booking, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isUpcoming = booking.checkIn.isAfter(DateTime.now());
    final isOngoing = booking.checkIn.isBefore(DateTime.now()) &&
                      booking.checkOut.isAfter(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      booking.guest?.fullName ?? 'Onbekend',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  _StatusBadge(status: booking.status),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (booking.accommodation?.color != null)
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: _parseColor(booking.accommodation!.color!),
                        shape: BoxShape.circle,
                      ),
                    ),
                  Icon(Icons.home, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      booking.accommodation?.name ?? 'Onbekend',
                      style: TextStyle(color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${_formatDate(booking.checkIn)} - ${_formatDate(booking.checkOut)}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${booking.nights}n',
                      style: TextStyle(color: Colors.grey[600], fontSize: 11),
                    ),
                  ),
                  if (isOngoing) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Nu',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '€${booking.totalAmount.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  _PaymentBadge(status: booking.paymentStatus),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}-${date.month}-${date.year}';
  }

  Color _parseColor(String colorString) {
    try {
      if (colorString.startsWith('#')) {
        return Color(int.parse(colorString.substring(1), radix: 16) + 0xFF000000);
      }
      return AppTheme.primaryColor;
    } catch (e) {
      return AppTheme.primaryColor;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case 'confirmed':
        color = AppTheme.statusConfirmed;
        label = 'Bevestigd';
        break;
      case 'option':
        color = AppTheme.statusOption;
        label = 'Optie';
        break;
      case 'inquiry':
        color = AppTheme.statusInquiry;
        label = 'Aanvraag';
        break;
      case 'cancelled':
        color = AppTheme.statusCancelled;
        label = 'Geannuleerd';
        break;
      case 'completed':
        color = Colors.purple;
        label = 'Afgerond';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _PaymentBadge extends StatelessWidget {
  final String status;

  const _PaymentBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case 'paid':
        color = AppTheme.paymentPaid;
        label = 'Betaald';
        break;
      case 'partial':
        color = AppTheme.paymentPartial;
        label = 'Aanbetaald';
        break;
      default:
        color = AppTheme.paymentUnpaid;
        label = 'Openstaand';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 8, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
