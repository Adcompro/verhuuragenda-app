import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _error = '${l10n.couldNotLoadAccommodations}: ${e.toString()}';
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.accommodations),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToEdit(null),
        icon: const Icon(Icons.add),
        label: Text(l10n.newItem),
      ),
    );
  }

  Widget _buildBody() {
    final l10n = AppLocalizations.of(context)!;

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
                label: Text(l10n.retry),
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
              l10n.noAccommodationsFound,
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
    final l10n = AppLocalizations.of(context)!;
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
                    _buildStatusBadge(l10n),
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
                        l10n.nGuestsCount(accommodation.maxGuests!),
                      ),
                    if (accommodation.bedrooms != null)
                      _buildInfoChip(
                        Icons.bed,
                        l10n.nBedroomsShort(accommodation.bedrooms!),
                      ),
                    if (accommodation.bathrooms != null)
                      _buildInfoChip(
                        Icons.bathtub,
                        l10n.nBathroomsShort(accommodation.bathrooms!),
                      ),
                  ],
                ),
                // iCal sync indicators
                if (_hasAnySyncUrl(accommodation)) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Icon(Icons.sync, size: 14, color: Colors.grey[500]),
                      if (accommodation.icalAirbnbUrl != null && accommodation.icalAirbnbUrl!.isNotEmpty)
                        _buildSyncBadge('Airbnb', const Color(0xFFFF5A5F)),
                      if (accommodation.icalBookingUrl != null && accommodation.icalBookingUrl!.isNotEmpty)
                        _buildSyncBadge('Booking', const Color(0xFF003580)),
                      if (accommodation.icalVrboUrl != null && accommodation.icalVrboUrl!.isNotEmpty)
                        _buildSyncBadge('VRBO', const Color(0xFF3B5998)),
                      if (accommodation.icalGoogleUrl != null && accommodation.icalGoogleUrl!.isNotEmpty)
                        _buildSyncBadge('Google', const Color(0xFF4285F4)),
                      if (accommodation.icalHoliduUrl != null && accommodation.icalHoliduUrl!.isNotEmpty)
                        _buildSyncBadge('Holidu', const Color(0xFF00B4AB)),
                      if (accommodation.icalBelvillaUrl != null && accommodation.icalBelvillaUrl!.isNotEmpty)
                        _buildSyncBadge('Belvilla', const Color(0xFFE85D04)),
                      if (accommodation.icalOtherUrl != null && accommodation.icalOtherUrl!.isNotEmpty)
                        _buildSyncBadge(l10n.other, Colors.grey),
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
                        _buildPriceColumn(l10n.lowSeason, accommodation.basePriceLow!, l10n),
                      if (accommodation.basePriceMid != null)
                        _buildPriceColumn(l10n.midSeasonShort, accommodation.basePriceMid!, l10n),
                      if (accommodation.basePriceHigh != null)
                        _buildPriceColumn(l10n.highSeason, accommodation.basePriceHigh!, l10n),
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

  Widget _buildStatusBadge(AppLocalizations l10n) {
    final isActive = accommodation.isActive;
    final isPublished = accommodation.isPublished;

    if (!isActive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          l10n.inactive,
          style: const TextStyle(
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
        isPublished ? l10n.published : l10n.draft,
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

  Widget _buildPriceColumn(String label, double price, AppLocalizations l10n) {
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
          '${price.toStringAsFixed(0)}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '/${l10n.perWeek.replaceAll('per ', '')}',
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

  bool _hasAnySyncUrl(Accommodation acc) {
    return (acc.icalAirbnbUrl != null && acc.icalAirbnbUrl!.isNotEmpty) ||
        (acc.icalBookingUrl != null && acc.icalBookingUrl!.isNotEmpty) ||
        (acc.icalVrboUrl != null && acc.icalVrboUrl!.isNotEmpty) ||
        (acc.icalGoogleUrl != null && acc.icalGoogleUrl!.isNotEmpty) ||
        (acc.icalHoliduUrl != null && acc.icalHoliduUrl!.isNotEmpty) ||
        (acc.icalBelvillaUrl != null && acc.icalBelvillaUrl!.isNotEmpty) ||
        (acc.icalOtherUrl != null && acc.icalOtherUrl!.isNotEmpty);
  }

  Widget _buildSyncBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }
}
