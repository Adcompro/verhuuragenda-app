// Helper function to parse values that could be String, int, double, or null
double? _parseDoubleNullable(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    return double.tryParse(value);
  }
  return null;
}

class Accommodation {
  final int id;
  final String name;
  final String? slug;
  final String? propertyType;
  final int? maxGuests;
  final int? bedrooms;
  final int? bathrooms;
  final String? color;
  final double? basePriceLow;
  final double? basePriceMid;
  final double? basePriceHigh;
  final double? cleaningFee;
  final bool isActive;
  final bool isPublished;
  final String? address;
  final String? city;
  final String? region;
  final String? countryCode;
  final String? wifiNetwork;
  final String? wifiPassword;
  final String? alarmCode;
  final String? checkinTimeFrom;
  final String? checkinTimeUntil;
  final String? checkoutTime;
  final String? houseRules;
  final String? arrivalInstructions;
  final String? localTips;
  final String? thumbnailUrl;
  final List<String> photos;
  final String? icalAirbnbUrl;
  final String? icalBookingUrl;
  final String? icalVrboUrl;
  final String? icalGoogleUrl;
  final String? icalHoliduUrl;
  final String? icalBelvillaUrl;
  final String? icalOtherUrl;
  final String? icalExportUrl;
  final String? description;

  Accommodation({
    required this.id,
    required this.name,
    this.slug,
    this.propertyType,
    this.maxGuests,
    this.bedrooms,
    this.bathrooms,
    this.color,
    this.basePriceLow,
    this.basePriceMid,
    this.basePriceHigh,
    this.cleaningFee,
    this.isActive = true,
    this.isPublished = false,
    this.address,
    this.city,
    this.region,
    this.countryCode,
    this.wifiNetwork,
    this.wifiPassword,
    this.alarmCode,
    this.checkinTimeFrom,
    this.checkinTimeUntil,
    this.checkoutTime,
    this.houseRules,
    this.arrivalInstructions,
    this.localTips,
    this.thumbnailUrl,
    this.photos = const [],
    this.icalAirbnbUrl,
    this.icalBookingUrl,
    this.icalVrboUrl,
    this.icalGoogleUrl,
    this.icalHoliduUrl,
    this.icalBelvillaUrl,
    this.icalOtherUrl,
    this.icalExportUrl,
    this.description,
  });

  factory Accommodation.fromJson(Map<String, dynamic> json) {
    return Accommodation(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'],
      propertyType: json['property_type'],
      maxGuests: json['max_guests'],
      bedrooms: json['bedrooms'],
      bathrooms: json['bathrooms'],
      color: json['color'],
      basePriceLow: _parseDoubleNullable(json['base_price_low']),
      basePriceMid: _parseDoubleNullable(json['base_price_mid']),
      basePriceHigh: _parseDoubleNullable(json['base_price_high']),
      cleaningFee: _parseDoubleNullable(json['cleaning_fee']),
      isActive: json['is_active'] ?? true,
      isPublished: json['is_published'] ?? false,
      address: json['address'],
      city: json['city'],
      region: json['region'],
      countryCode: json['country_code'],
      wifiNetwork: json['wifi_network'],
      wifiPassword: json['wifi_password'],
      alarmCode: json['alarm_code'],
      checkinTimeFrom: json['checkin_time_from'],
      checkinTimeUntil: json['checkin_time_until'],
      checkoutTime: json['checkout_time'],
      houseRules: json['house_rules'],
      arrivalInstructions: json['arrival_instructions'],
      localTips: json['local_tips'],
      thumbnailUrl: json['thumbnail_url'] ?? json['primary_photo'],
      photos: json['photos'] != null
          ? List<String>.from(json['photos'])
          : [],
      icalAirbnbUrl: json['ical_airbnb_url'],
      icalBookingUrl: json['ical_booking_url'],
      icalVrboUrl: json['ical_vrbo_url'],
      icalGoogleUrl: json['ical_google_url'],
      icalHoliduUrl: json['ical_holidu_url'],
      icalBelvillaUrl: json['ical_belvilla_url'],
      icalOtherUrl: json['ical_other_url'],
      icalExportUrl: json['ical_export_url'],
      description: json['description'],
    );
  }

  String get propertyTypeLabel {
    switch (propertyType) {
      case 'apartment':
        return 'Appartement';
      case 'house':
        return 'Woning';
      case 'villa':
        return 'Villa';
      case 'cabin':
        return 'Huisje';
      case 'studio':
        return 'Studio';
      default:
        return propertyType ?? 'Accommodatie';
    }
  }

  String get shortDescription {
    final parts = <String>[];
    if (maxGuests != null) parts.add('$maxGuests personen');
    if (bedrooms != null) parts.add('$bedrooms slaapkamers');
    return parts.join(' • ');
  }
}
