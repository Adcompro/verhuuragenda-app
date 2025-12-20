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
      basePriceLow: json['base_price_low']?.toDouble(),
      basePriceMid: json['base_price_mid']?.toDouble(),
      basePriceHigh: json['base_price_high']?.toDouble(),
      cleaningFee: json['cleaning_fee']?.toDouble(),
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
      thumbnailUrl: json['thumbnail_url'],
      photos: json['photos'] != null
          ? List<String>.from(json['photos'])
          : [],
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
