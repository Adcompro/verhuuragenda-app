import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../config/theme.dart';
import '../../core/api/api_client.dart';
import '../../config/api_config.dart';
import '../../models/booking.dart';
import '../../utils/responsive.dart';

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
          queryParams['from_date'] = _formatDateForApi(now);
          break;
        case 'past':
          queryParams['to_date'] = _formatDateForApi(now);
          break;
        case 'custom':
          if (_startDate != null) {
            queryParams['from_date'] = _formatDateForApi(_startDate!);
          }
          if (_endDate != null) {
            queryParams['to_date'] = _formatDateForApi(_endDate!);
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
        // Sort by check-in date descending (newest first)
        _bookings.sort((a, b) => b.checkIn.compareTo(a.checkIn));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatDateForApi(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.bookings),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _showPeriodFilter,
            tooltip: l10n.selectPeriod,
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
              _buildFilterMenuItem('all', l10n.all, l10n),
              _buildFilterMenuItem('confirmed', l10n.confirmed, l10n),
              _buildFilterMenuItem('option', l10n.option, l10n),
              _buildFilterMenuItem('inquiry', l10n.inquiry, l10n),
              _buildFilterMenuItem('cancelled', l10n.cancelled, l10n),
            ],
          ),
        ],
        bottom: _buildFilterChips(l10n),
      ),
      body: _buildBody(l10n),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/bookings/new'),
        icon: const Icon(Icons.add),
        label: Text(l10n.newBooking),
      ),
    );
  }

  PopupMenuItem<String> _buildFilterMenuItem(String value, String label, AppLocalizations l10n) {
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

  PreferredSize _buildFilterChips(AppLocalizations l10n) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(50),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _buildPeriodChip('upcoming', l10n.upcoming),
            const SizedBox(width: 8),
            _buildPeriodChip('all', l10n.allTab),
            const SizedBox(width: 8),
            _buildPeriodChip('past', l10n.past),
            const SizedBox(width: 8),
            _buildPeriodChip('custom', l10n.custom),
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
    final l10n = AppLocalizations.of(context)!;
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
            Text(
              l10n.selectPeriod,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.upcoming),
              title: Text(l10n.upcomingBookings),
              subtitle: Text(l10n.fromToday),
              selected: _periodFilter == 'upcoming',
              onTap: () {
                Navigator.pop(context);
                setState(() => _periodFilter = 'upcoming');
                _loadBookings();
              },
            ),
            ListTile(
              leading: const Icon(Icons.all_inclusive),
              title: Text(l10n.allBookings),
              subtitle: Text(l10n.withoutDateFilter),
              selected: _periodFilter == 'all',
              onTap: () {
                Navigator.pop(context);
                setState(() => _periodFilter = 'all');
                _loadBookings();
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: Text(l10n.pastBookings),
              subtitle: Text(l10n.untilToday),
              selected: _periodFilter == 'past',
              onTap: () {
                Navigator.pop(context);
                setState(() => _periodFilter = 'past');
                _loadBookings();
              },
            ),
            ListTile(
              leading: const Icon(Icons.date_range),
              title: Text(l10n.customPeriod),
              subtitle: Text(_startDate != null && _endDate != null
                  ? '${_formatDate(_startDate!)} - ${_formatDate(_endDate!)}'
                  : l10n.chooseADateRange),
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
              start: now.subtract(const Duration(days: 30)),
              end: now.add(const Duration(days: 30)),
            ),
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

  Widget _buildBody(AppLocalizations l10n) {
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
              Text(l10n.couldNotLoadBookings(_error!), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadBookings,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.tryAgain),
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
              l10n.noBookingsFound,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              _getPeriodDescription(l10n),
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    final isWide = Responsive.useWideLayout(context);
    final padding = Responsive.getScreenPadding(context);

    return RefreshIndicator(
      onRefresh: _loadBookings,
      child: CustomScrollView(
        slivers: [
          // Count header
          SliverPadding(
            padding: EdgeInsets.fromLTRB(padding.left, padding.top, padding.right, 12),
            sliver: SliverToBoxAdapter(
              child: Text(
                l10n.bookingsCount(_bookings.length),
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ),
          ),
          // Grid on tablet, list on phone
          if (isWide)
            SliverPadding(
              padding: EdgeInsets.fromLTRB(padding.left, 0, padding.right, padding.bottom),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: Responsive.isDesktop(context) ? 3 : 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.8,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final booking = _bookings[index];
                    return _BookingCard(
                      booking: booking,
                      onTap: () => context.push('/bookings/${booking.id}'),
                    );
                  },
                  childCount: _bookings.length,
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(padding.left, 0, padding.right, padding.bottom),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final booking = _bookings[index];
                    return _BookingCard(
                      booking: booking,
                      onTap: () => context.push('/bookings/${booking.id}'),
                    );
                  },
                  childCount: _bookings.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getPeriodDescription(AppLocalizations l10n) {
    switch (_periodFilter) {
      case 'upcoming':
        return l10n.forUpcomingPeriod;
      case 'past':
        return l10n.inPastPeriod;
      case 'custom':
        if (_startDate != null && _endDate != null) {
          return l10n.fromDateToDate(_formatDate(_startDate!), _formatDate(_endDate!));
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
    final l10n = AppLocalizations.of(context)!;
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
                      booking.guest?.fullName ?? l10n.unknown,
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
                      booking.accommodation?.name ?? l10n.unknown,
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
                      child: Text(
                        l10n.now,
                        style: const TextStyle(
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
    final l10n = AppLocalizations.of(context)!;
    Color color;
    String label;

    switch (status) {
      case 'confirmed':
        color = AppTheme.statusConfirmed;
        label = l10n.confirmed;
        break;
      case 'option':
        color = AppTheme.statusOption;
        label = l10n.option;
        break;
      case 'inquiry':
        color = AppTheme.statusInquiry;
        label = l10n.inquiry;
        break;
      case 'cancelled':
        color = AppTheme.statusCancelled;
        label = l10n.cancelled;
        break;
      case 'completed':
        color = Colors.purple;
        label = l10n.completed;
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
    final l10n = AppLocalizations.of(context)!;
    Color color;
    String label;

    switch (status) {
      case 'paid':
        color = AppTheme.paymentPaid;
        label = l10n.paid;
        break;
      case 'partial':
        color = AppTheme.paymentPartial;
        label = l10n.partiallyPaid;
        break;
      default:
        color = AppTheme.paymentUnpaid;
        label = l10n.outstanding;
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
