import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../config/api_config.dart';
import '../../core/api/api_client.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  bool _isSaving = false;

  // Notification preferences
  bool _newBooking = true;
  bool _bookingCancelled = true;
  bool _paymentReceived = true;
  bool _checkInReminder = true;
  bool _checkOutReminder = true;
  bool _cleaningReminder = true;
  bool _maintenanceUpdates = true;
  bool _marketingEmails = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);

    try {
      final response = await ApiClient.instance.get('${ApiConfig.notifications}/preferences');

      if (response.data is Map) {
        final prefs = response.data as Map<String, dynamic>;
        setState(() {
          _newBooking = prefs['new_booking'] ?? true;
          _bookingCancelled = prefs['booking_cancelled'] ?? true;
          _paymentReceived = prefs['payment_received'] ?? true;
          _checkInReminder = prefs['check_in_reminder'] ?? true;
          _checkOutReminder = prefs['check_out_reminder'] ?? true;
          _cleaningReminder = prefs['cleaning_reminder'] ?? true;
          _maintenanceUpdates = prefs['maintenance_updates'] ?? true;
          _marketingEmails = prefs['marketing_emails'] ?? false;
        });
      }
    } catch (e) {
      // Use default values on error
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePreferences() async {
    setState(() => _isSaving = true);

    try {
      await ApiClient.instance.put(
        '${ApiConfig.notifications}/preferences',
        data: {
          'new_booking': _newBooking,
          'booking_cancelled': _bookingCancelled,
          'payment_received': _paymentReceived,
          'check_in_reminder': _checkInReminder,
          'check_out_reminder': _checkOutReminder,
          'cleaning_reminder': _cleaningReminder,
          'maintenance_updates': _maintenanceUpdates,
          'marketing_emails': _marketingEmails,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Voorkeuren opgeslagen'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kon voorkeuren niet opslaan'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaties'),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _savePreferences,
              child: const Text('Opslaan'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _buildSectionHeader('Boekingen'),
                _buildSwitchTile(
                  icon: Icons.add_circle_outline,
                  title: 'Nieuwe boeking',
                  subtitle: 'Ontvang een melding bij nieuwe boekingen',
                  value: _newBooking,
                  onChanged: (v) => setState(() => _newBooking = v),
                ),
                _buildSwitchTile(
                  icon: Icons.cancel_outlined,
                  title: 'Annulering',
                  subtitle: 'Melding wanneer een boeking wordt geannuleerd',
                  value: _bookingCancelled,
                  onChanged: (v) => setState(() => _bookingCancelled = v),
                ),
                _buildSwitchTile(
                  icon: Icons.euro,
                  title: 'Betaling ontvangen',
                  subtitle: 'Melding bij ontvangst van betalingen',
                  value: _paymentReceived,
                  onChanged: (v) => setState(() => _paymentReceived = v),
                ),
                const Divider(),

                _buildSectionHeader('Herinneringen'),
                _buildSwitchTile(
                  icon: Icons.login,
                  title: 'Check-in herinnering',
                  subtitle: 'Herinnering 1 dag voor check-in van gasten',
                  value: _checkInReminder,
                  onChanged: (v) => setState(() => _checkInReminder = v),
                ),
                _buildSwitchTile(
                  icon: Icons.logout,
                  title: 'Check-out herinnering',
                  subtitle: 'Herinnering op de dag van check-out',
                  value: _checkOutReminder,
                  onChanged: (v) => setState(() => _checkOutReminder = v),
                ),
                _buildSwitchTile(
                  icon: Icons.cleaning_services,
                  title: 'Schoonmaak herinnering',
                  subtitle: 'Herinnering voor schoonmaaktaken',
                  value: _cleaningReminder,
                  onChanged: (v) => setState(() => _cleaningReminder = v),
                ),
                const Divider(),

                _buildSectionHeader('Overig'),
                _buildSwitchTile(
                  icon: Icons.build,
                  title: 'Onderhoud updates',
                  subtitle: 'Meldingen over onderhoudstaken',
                  value: _maintenanceUpdates,
                  onChanged: (v) => setState(() => _maintenanceUpdates = v),
                ),
                _buildSwitchTile(
                  icon: Icons.mail_outline,
                  title: 'Nieuwsbrief & tips',
                  subtitle: 'Ontvang tips en updates over VerhuurAgenda',
                  value: _marketingEmails,
                  onChanged: (v) => setState(() => _marketingEmails = v),
                ),
                const SizedBox(height: 24),

                // Info section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[100]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Push notificaties worden verstuurd naar dit apparaat. Zorg dat notificaties zijn ingeschakeld in je telefooninstellingen.',
                            style: TextStyle(
                              color: Colors.blue[800],
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: Colors.grey[600]),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: AppTheme.primaryColor,
    );
  }
}
