class Guest {
  final int id;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? countryCode;
  final String? source;
  final bool isReturning;
  final int totalBookings;

  Guest({
    required this.id,
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.countryCode,
    this.source,
    this.isReturning = false,
    this.totalBookings = 0,
  });

  factory Guest.fromJson(Map<String, dynamic> json) {
    return Guest(
      id: json['id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      email: json['email'],
      phone: json['phone'],
      countryCode: json['country_code'],
      source: json['source'],
      isReturning: json['is_returning'] ?? false,
      totalBookings: json['total_bookings'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'country_code': countryCode,
      'source': source,
      'is_returning': isReturning,
      'total_bookings': totalBookings,
    };
  }

  String get fullName {
    if (firstName == null && lastName == null) return 'Onbekend';
    return '${firstName ?? ''} ${lastName ?? ''}'.trim();
  }

  String get initials {
    final first = firstName?.isNotEmpty == true ? firstName![0] : '';
    final last = lastName?.isNotEmpty == true ? lastName![0] : '';
    return '$first$last'.toUpperCase();
  }
}
