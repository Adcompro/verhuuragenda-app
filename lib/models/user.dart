class User {
  final int id;
  final String name;
  final String email;
  final String? role;
  final Host? host;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.role,
    this.host,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    Host? host;
    try {
      if (json['host'] != null && json['host'] is Map<String, dynamic>) {
        host = Host.fromJson(json['host']);
      }
    } catch (e) {
      // Ignore host parsing errors
      host = null;
    }

    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'],
      host: host,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'host': host?.toJson(),
    };
  }
}

class Host {
  final int id;
  final String? companyName;
  final String? phone;
  final String? address;
  final String? city;
  final String? postalCode;
  final String? country;
  final String? website;
  final String? photoUrl;
  final String subscriptionStatus;
  final String? subscriptionPlan;
  final DateTime? subscriptionEndsAt;

  Host({
    required this.id,
    this.companyName,
    this.phone,
    this.address,
    this.city,
    this.postalCode,
    this.country,
    this.website,
    this.photoUrl,
    required this.subscriptionStatus,
    this.subscriptionPlan,
    this.subscriptionEndsAt,
  });

  factory Host.fromJson(Map<String, dynamic> json) {
    DateTime? subscriptionEndsAt;
    try {
      if (json['subscription_ends_at'] != null) {
        subscriptionEndsAt = DateTime.parse(json['subscription_ends_at']);
      }
    } catch (e) {
      subscriptionEndsAt = null;
    }

    return Host(
      id: json['id'] ?? 0,
      companyName: json['company_name'],
      phone: json['phone'],
      address: json['address'],
      city: json['city'],
      postalCode: json['postal_code'],
      country: json['country'],
      website: json['website'],
      photoUrl: json['photo_url'],
      subscriptionStatus: json['subscription_status'] ?? 'free',
      subscriptionPlan: json['subscription_plan'],
      subscriptionEndsAt: subscriptionEndsAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_name': companyName,
      'phone': phone,
      'address': address,
      'city': city,
      'postal_code': postalCode,
      'country': country,
      'website': website,
      'photo_url': photoUrl,
      'subscription_status': subscriptionStatus,
      'subscription_plan': subscriptionPlan,
      'subscription_ends_at': subscriptionEndsAt?.toIso8601String(),
    };
  }

  bool get isPremium => subscriptionStatus == 'active';
  bool get isTrial => subscriptionStatus == 'trial';
  bool get isExpired => subscriptionStatus == 'expired';
}
