import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../core/api/api_client.dart';
import '../../config/api_config.dart';
import '../../models/accommodation.dart';
import 'accommodation_edit_screen.dart';

class AccommodationsListScreen extends StatefulWidget {
  const AccommodationsListScreen({super.key});

  @override
  State<AccommodationsListScreen> createState() => _AccommodationsListScreenState();
}

class _AccommodationsListScreenState extends State<AccommodationsListScreen> {
  List<Accommodation> _accommodations = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAccommodations();
  }

  Future<void> _loadAccommodations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiClient.instance.get(ApiConfig.accommodations);

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
        _accommodations = data.map((json) => Accommodation.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Kon accommodaties niet laden: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateToEdit(int? accommodationId) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AccommodationEditScreen(accommodationId: accommodationId),
      ),
    );
    if (result == true) {
      _loadAccommodations();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accommodaties'),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToEdit(null),
        icon: const Icon(Icons.add),
        label: const Text('Nieuw'),
      ),
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
                onPressed: _loadAccommodations,
                icon: const Icon(Icons.refresh),
                label: const Text('Opnieuw proberen'),
              ),
            ],
          ),
        ),
      );
    }

    if (_accommodations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home_work_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Geen accommodaties gevonden',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAccommodations,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _accommodations.length,
        itemBuilder: (context, index) {
          final accommodation = _accommodations[index];
          return _AccommodationCard(
            accommodation: accommodation,
            onTap: () => _navigateToEdit(accommodation.id),
          );
        },
      ),
    );
  }
}

class _AccommodationCard extends StatelessWidget {
  final Accommodation accommodation;
  final VoidCallback? onTap;

  const _AccommodationCard({required this.accommodation, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image header
          _buildImageHeader(),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row with color indicator
                Row(
                  children: [
                    if (accommodation.color != null)
                      Container(
                        width: 12,
                        height: 12,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: _parseColor(accommodation.color!),
                          shape: BoxShape.circle,
                        ),
                      ),
                    Expanded(
                      child: Text(
                        accommodation.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    _buildStatusBadge(),
                  ],
                ),
                const SizedBox(height: 8),
                // Property type and location
                Row(
                  children: [
                    Icon(Icons.home, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      accommodation.propertyTypeLabel,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    if (accommodation.city != null) ...[
                      const SizedBox(width: 16),
                      Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        accommodation.city!,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                // Capacity info
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    if (accommodation.maxGuests != null)
                      _buildInfoChip(
                        Icons.people,
                        '${accommodation.maxGuests} gasten',
                      ),
                    if (accommodation.bedrooms != null)
                      _buildInfoChip(
                        Icons.bed,
                        '${accommodation.bedrooms} slpk',
                      ),
                    if (accommodation.bathrooms != null)
                      _buildInfoChip(
                        Icons.bathtub,
                        '${accommodation.bathrooms} badk',
                      ),
                  ],
                ),
                // iCal sync indicators
                if (accommodation.icalAirbnbUrl != null ||
                    accommodation.icalBookingUrl != null ||
                    accommodation.icalOtherUrl != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.sync, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        'Sync: ',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      if (accommodation.icalAirbnbUrl != null && accommodation.icalAirbnbUrl!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF5A5F).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Airbnb',
                            style: TextStyle(fontSize: 10, color: Color(0xFFFF5A5F), fontWeight: FontWeight.w500),
                          ),
                        ),
                      if (accommodation.icalBookingUrl != null && accommodation.icalBookingUrl!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF003580).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Booking',
                            style: TextStyle(fontSize: 10, color: Color(0xFF003580), fontWeight: FontWeight.w500),
                          ),
                        ),
                      if (accommodation.icalOtherUrl != null && accommodation.icalOtherUrl!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Overig',
                            style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w500),
                          ),
                        ),
                    ],
                  ),
                ],
                // Pricing info
                if (accommodation.basePriceLow != null ||
                    accommodation.basePriceMid != null ||
                    accommodation.basePriceHigh != null) ...[
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      if (accommodation.basePriceLow != null)
                        _buildPriceColumn('Laagseizoen', accommodation.basePriceLow!),
                      if (accommodation.basePriceMid != null)
                        _buildPriceColumn('Midden', accommodation.basePriceMid!),
                      if (accommodation.basePriceHigh != null)
                        _buildPriceColumn('Hoogseizoen', accommodation.basePriceHigh!),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildImageHeader() {
    if (accommodation.thumbnailUrl != null && accommodation.thumbnailUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: accommodation.thumbnailUrl!,
        height: 160,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          height: 160,
          color: Colors.grey[200],
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => _buildPlaceholderImage(),
      );
    }
    return _buildPlaceholderImage();
  }

  Widget _buildPlaceholderImage() {
    return Container(
      height: 160,
      color: accommodation.color != null
          ? _parseColor(accommodation.color!).withOpacity(0.1)
          : Colors.grey[100],
      child: Center(
        child: Icon(
          Icons.home_work,
          size: 48,
          color: accommodation.color != null
              ? _parseColor(accommodation.color!)
              : Colors.grey[400],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    final isActive = accommodation.isActive;
    final isPublished = accommodation.isPublished;

    if (!isActive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Inactief',
          style: TextStyle(
            fontSize: 11,
            color: Colors.red,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isPublished ? Colors.green : Colors.orange).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isPublished ? 'Gepubliceerd' : 'Concept',
        style: TextStyle(
          fontSize: 11,
          color: isPublished ? Colors.green : Colors.orange,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[500]),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceColumn(String label, double price) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '€${price.toStringAsFixed(0)}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '/week',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
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
