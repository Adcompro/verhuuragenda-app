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
      final queryParams = <String, dynamic>{};
      if (_statusFilter != 'all') {
        queryParams['status'] = _statusFilter;
      }

      final response = await ApiClient.instance.get(
        ApiConfig.bookings,
        queryParameters: queryParams,
      );

      final data = response.data['data'] as List;
      setState(() {
        _bookings = data.map((json) => Booking.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Kon boekingen niet laden';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Boekingen'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _statusFilter = value;
              });
              _loadBookings();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('Alle')),
              const PopupMenuItem(value: 'confirmed', child: Text('Bevestigd')),
              const PopupMenuItem(value: 'option', child: Text('Optie')),
              const PopupMenuItem(value: 'inquiry', child: Text('Aanvraag')),
            ],
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to create booking
        },
        child: const Icon(Icons.add),
      ),
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
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadBookings,
              child: const Text('Opnieuw proberen'),
            ),
          ],
        ),
      );
    }

    if (_bookings.isEmpty) {
      return const Center(
        child: Text('Geen boekingen gevonden'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _bookings.length,
        itemBuilder: (context, index) {
          final booking = _bookings[index];
          return _BookingCard(
            booking: booking,
            onTap: () => context.go('/bookings/${booking.id}'),
          );
        },
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback onTap;

  const _BookingCard({required this.booking, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
                  Icon(Icons.home, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    booking.accommodation?.name ?? 'Onbekend',
                    style: TextStyle(color: Colors.grey[600]),
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
                  Text(
                    '(${booking.nights} nachten)',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
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
