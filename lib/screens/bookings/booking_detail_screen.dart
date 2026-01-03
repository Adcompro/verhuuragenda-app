import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../config/theme.dart';
import '../../core/api/api_client.dart';
import '../../config/api_config.dart';
import '../../models/booking.dart';

class BookingDetailScreen extends StatefulWidget {
  final int bookingId;

  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  Booking? _booking;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiClient.instance.get(
        '${ApiConfig.bookings}/${widget.bookingId}',
      );

      setState(() {
        _booking = Booking.fromJson(response.data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(_booking?.bookingNumber ?? l10n.bookingWithId(widget.bookingId)),
        actions: [
          if (_booking != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => context.push('/bookings/${widget.bookingId}/edit'),
              tooltip: l10n.edit,
            ),
          if (_booking != null)
            PopupMenuButton<String>(
              onSelected: _handleMenuAction,
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'status',
                  child: Row(
                    children: [
                      const Icon(Icons.swap_horiz, size: 20),
                      const SizedBox(width: 12),
                      Text(l10n.changeStatus),
                    ],
                  ),
                ),
                if (_booking!.portalUrl != null)
                  PopupMenuItem(
                    value: 'portal',
                    child: Row(
                      children: [
                        const Icon(Icons.share, size: 20),
                        const SizedBox(width: 12),
                        Text(l10n.shareGuestPortal),
                      ],
                    ),
                  ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete, size: 20, color: Colors.red),
                      const SizedBox(width: 12),
                      Text(l10n.delete, style: const TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _buildBody(l10n),
    );
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
              Text(l10n.couldNotLoadBooking(_error!), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadBooking,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.tryAgain),
              ),
            ],
          ),
        ),
      );
    }

    if (_booking == null) {
      return Center(child: Text(l10n.bookingNotFound));
    }

    return RefreshIndicator(
      onRefresh: _loadBooking,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusHeader(),
            _buildGuestSection(l10n),
            _buildAccommodationSection(l10n),
            _buildDatesSection(l10n),
            _buildFinancialSection(l10n),
            if (_booking!.payments.isNotEmpty) _buildPaymentsSection(l10n),
            if (_booking!.internalNotes != null && _booking!.internalNotes!.isNotEmpty)
              _buildNotesSection(l10n),
            if (_booking!.portalUrl != null) _buildPortalSection(l10n),
            const SizedBox(height: 100), // Space for FAB
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: _getStatusColor(_booking!.status).withOpacity(0.1),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _getStatusColor(_booking!.status),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _booking!.statusLabel,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Spacer(),
          Text(
            _booking!.sourceLabel,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestSection(AppLocalizations l10n) {
    final guest = _booking!.guest;
    if (guest == null) return const SizedBox.shrink();

    return _buildSection(
      title: l10n.guest,
      icon: Icons.person,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                child: Text(
                  guest.initials.isEmpty ? '?' : guest.initials,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      guest.fullName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (guest.email != null)
                      Text(
                        guest.email!,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (guest.phone != null) ...[
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.phone,
                    label: l10n.call,
                    color: Colors.green,
                    onPressed: () => _callGuest(guest.phone!),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.message,
                    label: 'WhatsApp',
                    color: const Color(0xFF25D366),
                    onPressed: () => _whatsappGuest(guest.phone!),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (guest.email != null)
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.email,
                    label: l10n.email,
                    color: Colors.blue,
                    onPressed: () => _emailGuest(guest.email!),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccommodationSection(AppLocalizations l10n) {
    final accommodation = _booking!.accommodation;
    if (accommodation == null) return const SizedBox.shrink();

    return _buildSection(
      title: l10n.accommodation,
      icon: Icons.home,
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: accommodation.color != null
                  ? _parseColor(accommodation.color!)
                  : AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  accommodation.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (accommodation.city != null)
                  Text(
                    accommodation.city!,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatesSection(AppLocalizations l10n) {
    return _buildSection(
      title: l10n.stay,
      icon: Icons.calendar_today,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDateCard(
                  label: l10n.checkIn,
                  date: _booking!.checkIn,
                  icon: Icons.login,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDateCard(
                  label: l10n.checkOut,
                  date: _booking!.checkOut,
                  icon: Icons.logout,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem(
                  icon: Icons.nights_stay,
                  value: '${_booking!.nights}',
                  label: l10n.nights,
                ),
                _buildInfoItem(
                  icon: Icons.people,
                  value: '${_booking!.adults}',
                  label: l10n.adults,
                ),
                if (_booking!.children != null && _booking!.children! > 0)
                  _buildInfoItem(
                    icon: Icons.child_care,
                    value: '${_booking!.children}',
                    label: l10n.children,
                  ),
                if (_booking!.babies != null && _booking!.babies! > 0)
                  _buildInfoItem(
                    icon: Icons.baby_changing_station,
                    value: '${_booking!.babies}',
                    label: l10n.babies,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSection(AppLocalizations l10n) {
    return _buildSection(
      title: l10n.financial,
      icon: Icons.euro,
      child: Column(
        children: [
          _buildFinancialRow(l10n.totalAmount, _booking!.totalAmount, isBold: true),
          if (_booking!.cleaningFee != null && _booking!.cleaningFee! > 0)
            _buildFinancialRow(l10n.cleaningCosts, _booking!.cleaningFee!, isSubtle: true),
          if (_booking!.depositAmount != null && _booking!.depositAmount! > 0)
            _buildFinancialRow(l10n.deposit, _booking!.depositAmount!, isSubtle: true),
          const Divider(height: 24),
          _buildFinancialRow(
            l10n.paid,
            _booking!.paidAmount,
            color: AppTheme.paymentPaid,
          ),
          _buildFinancialRow(
            l10n.outstanding,
            _booking!.remainingAmount,
            color: _booking!.remainingAmount > 0 ? AppTheme.paymentUnpaid : AppTheme.paymentPaid,
            isBold: true,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _addPayment,
              icon: const Icon(Icons.add),
              label: Text(l10n.addPayment),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsSection(AppLocalizations l10n) {
    return _buildSection(
      title: l10n.payments,
      icon: Icons.payment,
      child: Column(
        children: _booking!.payments.map((payment) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '€${payment.amount.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        payment.methodLabel,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                if (payment.paidAt != null)
                  Text(
                    _formatDate(payment.paidAt!),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNotesSection(AppLocalizations l10n) {
    return _buildSection(
      title: l10n.internalNotes,
      icon: Icons.note,
      child: Text(
        _booking!.internalNotes!,
        style: TextStyle(color: Colors.grey[700]),
      ),
    );
  }

  Widget _buildPortalSection(AppLocalizations l10n) {
    return _buildSection(
      title: l10n.guestPortal,
      icon: Icons.link,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_booking!.portalPin != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.pin, color: AppTheme.primaryColor),
                  const SizedBox(width: 12),
                  Text(
                    'PIN: ${_booking!.portalPin}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                      letterSpacing: 4,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _booking!.portalPin!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.pinCopied)),
                      );
                    },
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _booking!.portalUrl!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.linkCopied)),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  label: Text(l10n.copyLink),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _sharePortal(),
                  icon: const Icon(Icons.share),
                  label: Text(l10n.share),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: color),
      label: Text(label, style: TextStyle(color: color)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withOpacity(0.5)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  Widget _buildDateCard({
    required String label,
    required DateTime date,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primaryColor),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(
            _formatDateFull(date),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildFinancialRow(
    String label,
    double amount, {
    Color? color,
    bool isBold = false,
    bool isSubtle = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isSubtle ? Colors.grey[500] : Colors.grey[700],
              fontSize: isSubtle ? 13 : 14,
            ),
          ),
          Text(
            '€${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? (isBold ? Colors.black : Colors.grey[700]),
              fontSize: isBold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'status':
        _showStatusDialog();
        break;
      case 'portal':
        _sharePortal();
        break;
      case 'delete':
        _confirmDelete();
        break;
    }
  }

  void _showStatusDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.changeStatus),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusOption('confirmed', l10n.confirmed),
            _buildStatusOption('option', l10n.option),
            _buildStatusOption('inquiry', l10n.inquiry),
            _buildStatusOption('cancelled', l10n.cancelled),
            _buildStatusOption('completed', l10n.completed),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOption(String status, String label) {
    final isSelected = _booking!.status == status;
    return ListTile(
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: _getStatusColor(status),
      ),
      title: Text(label),
      onTap: () async {
        Navigator.pop(context);
        await _updateStatus(status);
      },
    );
  }

  Future<void> _updateStatus(String status) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await ApiClient.instance.patch(
        '${ApiConfig.bookings}/${widget.bookingId}/status',
        data: {'status': status},
      );
      _loadBooking();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.statusUpdated)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorUpdating(e.toString()))),
        );
      }
    }
  }

  void _addPayment() {
    // Show payment dialog
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _AddPaymentSheet(
        bookingId: widget.bookingId,
        remainingAmount: _booking!.remainingAmount,
        onPaymentAdded: _loadBooking,
      ),
    );
  }

  void _sharePortal() {
    if (_booking?.portalUrl == null) return;
    final l10n = AppLocalizations.of(context)!;

    final message = l10n.portalShareMessage(
      _booking!.guest?.fullName ?? l10n.guest,
      _booking!.portalUrl!,
      _booking!.portalPin ?? l10n.notAvailable,
    );

    Share.share(message, subject: l10n.yourBookingDetails);
  }

  void _confirmDelete() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteBookingQuestion),
        content: Text(l10n.deleteBookingConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteBooking();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteBooking() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await ApiClient.instance.delete('${ApiConfig.bookings}/${widget.bookingId}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.bookingDeleted)),
        );
        context.go('/bookings');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorDeleting(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _callGuest(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _emailGuest(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _whatsappGuest(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('https://wa.me/$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return AppTheme.statusConfirmed;
      case 'option':
        return AppTheme.statusOption;
      case 'inquiry':
        return AppTheme.statusInquiry;
      case 'cancelled':
        return AppTheme.statusCancelled;
      case 'completed':
        return Colors.purple;
      default:
        return Colors.grey;
    }
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

  String _formatDate(DateTime date) {
    return '${date.day}-${date.month}-${date.year}';
  }

  String _formatDateFull(DateTime date) {
    const days = ['Ma', 'Di', 'Wo', 'Do', 'Vr', 'Za', 'Zo'];
    const months = ['jan', 'feb', 'mrt', 'apr', 'mei', 'jun', 'jul', 'aug', 'sep', 'okt', 'nov', 'dec'];
    return '${days[date.weekday - 1]} ${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _AddPaymentSheet extends StatefulWidget {
  final int bookingId;
  final double remainingAmount;
  final VoidCallback onPaymentAdded;

  const _AddPaymentSheet({
    required this.bookingId,
    required this.remainingAmount,
    required this.onPaymentAdded,
  });

  @override
  State<_AddPaymentSheet> createState() => _AddPaymentSheetState();
}

class _AddPaymentSheetState extends State<_AddPaymentSheet> {
  final _amountController = TextEditingController();
  String _method = 'bank';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.remainingAmount.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const SizedBox(height: 24),
          Text(
            l10n.addPayment,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n.amount,
              prefixText: '€ ',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _method,
            decoration: InputDecoration(
              labelText: l10n.paymentMethod,
              border: const OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(value: 'bank', child: Text(l10n.bank)),
              DropdownMenuItem(value: 'cash', child: Text(l10n.cash)),
              const DropdownMenuItem(value: 'ideal', child: Text('iDEAL')),
              DropdownMenuItem(value: 'creditcard', child: Text(l10n.creditcard)),
            ],
            onChanged: (value) {
              setState(() => _method = value!);
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitPayment,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.registerPayment),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitPayment() async {
    final l10n = AppLocalizations.of(context)!;
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.enterValidAmount)),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ApiClient.instance.post(
        '${ApiConfig.bookings}/${widget.bookingId}/payments',
        data: {
          'amount': amount,
          'method': _method,
          'paid_at': DateTime.now().toIso8601String(),
        },
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onPaymentAdded();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.paymentAdded)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorWithMessage(e.toString()))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
