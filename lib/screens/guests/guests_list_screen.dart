import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../core/api/api_client.dart';
import '../../config/api_config.dart';
import '../../models/guest.dart';

class GuestsListScreen extends StatefulWidget {
  const GuestsListScreen({super.key});

  @override
  State<GuestsListScreen> createState() => _GuestsListScreenState();
}

class _GuestsListScreenState extends State<GuestsListScreen> {
  List<Guest> _guests = [];
  List<Guest> _filteredGuests = [];
  bool _isLoading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadGuests();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadGuests() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiClient.instance.get(ApiConfig.guests);

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
        _guests = data.map((json) => Guest.fromJson(json)).toList();
        _filteredGuests = _guests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Kon gasten niet laden: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _filterGuests(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredGuests = _guests;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredGuests = _guests.where((guest) {
          return guest.fullName.toLowerCase().contains(lowerQuery) ||
              (guest.email?.toLowerCase().contains(lowerQuery) ?? false) ||
              (guest.phone?.contains(query) ?? false);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gasten'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: _filterGuests,
              decoration: InputDecoration(
                hintText: 'Zoek op naam, email of telefoon...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterGuests('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
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
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadGuests,
                icon: const Icon(Icons.refresh),
                label: const Text('Opnieuw proberen'),
              ),
            ],
          ),
        ),
      );
    }

    if (_guests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Geen gasten gevonden',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_filteredGuests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Geen resultaten voor "${_searchController.text}"',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadGuests,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredGuests.length,
        itemBuilder: (context, index) {
          final guest = _filteredGuests[index];
          return _GuestCard(guest: guest);
        },
      ),
    );
  }
}

class _GuestCard extends StatelessWidget {
  final Guest guest;

  const _GuestCard({required this.guest});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showGuestDetails(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              _buildAvatar(),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            guest.fullName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        if (guest.isReturning)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.repeat, size: 12, color: AppTheme.primaryColor),
                                const SizedBox(width: 4),
                                Text(
                                  '${guest.totalBookings}x',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    if (guest.email != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.email, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              guest.email!,
                              style: TextStyle(color: Colors.grey[600], fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (guest.phone != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            guest.phone!,
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                    if (guest.countryCode != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.flag, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            _getCountryName(guest.countryCode!),
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Contact buttons
              Column(
                children: [
                  if (guest.phone != null)
                    IconButton(
                      icon: Icon(Icons.phone, color: Colors.green[600]),
                      onPressed: () => _callGuest(guest.phone!),
                      tooltip: 'Bellen',
                    ),
                  if (guest.email != null)
                    IconButton(
                      icon: Icon(Icons.email, color: Colors.blue[600]),
                      onPressed: () => _emailGuest(guest.email!),
                      tooltip: 'Emailen',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 28,
      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
      child: Text(
        guest.initials.isEmpty ? '?' : guest.initials,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  void _showGuestDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
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
              // Header
              Row(
                children: [
                  _buildAvatar(),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          guest.fullName,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (guest.isReturning)
                          Text(
                            'Terugkerende gast (${guest.totalBookings} boekingen)',
                            style: TextStyle(color: AppTheme.primaryColor),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Contact info
              if (guest.email != null)
                _buildDetailRow(Icons.email, 'Email', guest.email!),
              if (guest.phone != null)
                _buildDetailRow(Icons.phone, 'Telefoon', guest.phone!),
              if (guest.countryCode != null)
                _buildDetailRow(Icons.flag, 'Land', _getCountryName(guest.countryCode!)),
              if (guest.source != null)
                _buildDetailRow(Icons.source, 'Bron', _getSourceLabel(guest.source!)),
              const SizedBox(height: 24),
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (guest.phone != null)
                    _buildActionButton(
                      context,
                      Icons.phone,
                      'Bellen',
                      Colors.green,
                      () => _callGuest(guest.phone!),
                    ),
                  if (guest.email != null)
                    _buildActionButton(
                      context,
                      Icons.email,
                      'Email',
                      Colors.blue,
                      () => _emailGuest(guest.email!),
                    ),
                  if (guest.phone != null)
                    _buildActionButton(
                      context,
                      Icons.message,
                      'WhatsApp',
                      const Color(0xFF25D366),
                      () => _whatsappGuest(guest.phone!),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              Text(
                value,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onPressed,
  ) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(16),
            backgroundColor: color,
          ),
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
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
    // Remove non-numeric characters except +
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('https://wa.me/$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _getCountryName(String code) {
    const countries = {
      'NL': 'Nederland',
      'BE': 'België',
      'DE': 'Duitsland',
      'FR': 'Frankrijk',
      'GB': 'Verenigd Koninkrijk',
      'US': 'Verenigde Staten',
      'ES': 'Spanje',
      'IT': 'Italië',
      'AT': 'Oostenrijk',
      'CH': 'Zwitserland',
    };
    return countries[code.toUpperCase()] ?? code;
  }

  String _getSourceLabel(String source) {
    const sources = {
      'direct': 'Direct',
      'airbnb': 'Airbnb',
      'booking': 'Booking.com',
      'vrbo': 'VRBO',
      'website': 'Website',
    };
    return sources[source] ?? source;
  }
}
