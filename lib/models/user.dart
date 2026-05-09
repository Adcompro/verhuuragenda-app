class User {
  final int id;
  final String name;
  final String email;
  final String? role;
  final List<String> permissions;
  final Host? host;
  final String? brandingAppName;
  final DateTime? termsAcceptedAt;
  final String? termsVersion;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.role,
    this.permissions = const [],
    this.host,
    this.brandingAppName,
    this.termsAcceptedAt,
    this.termsVersion,
  });

  bool get hasAcceptedTerms => termsAcceptedAt != null;

  /// Whether this user is allowed to see the menu item identified by [key].
  /// Admin always wins. Otherwise the role table below decides.
  bool canAccessMenu(String key) {
    final r = role ?? 'host';
    if (r == 'admin') return true;
    // Mapping: which roles see which menu key.
    const allowedByRole = <String, Set<String>>{
      'dashboard':     {'host', 'manager', 'viewer'},
      'calendar':      {'host', 'manager', 'viewer'},
      'bookings':      {'host', 'manager', 'viewer'},
      'accommodations':{'host', 'manager', 'viewer'},
      'guests':        {'manager', 'viewer'}, // host doesn't manage other guests
      'chat':          {'host', 'manager', 'viewer'},
      'cleaning':      {'host', 'manager'},
      'maintenance':   {'host', 'manager'},
      'pool':          {'host', 'manager'},
      'garden':        {'host', 'manager'},
      'campaigns':     <String>{}, // admin only
      'statistics':    {'manager'},
      'settings':      {'host', 'manager', 'viewer'},
    };
    return allowedByRole[key]?.contains(r) ?? true;
  }

  bool hasPermission(String permission) =>
      permissions.contains(permission) || role == 'admin';

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

    String? brandingAppName;
    final branding = json['branding'];
    if (branding is Map && branding['app_name'] is String) {
      brandingAppName = branding['app_name'] as String;
    }

    DateTime? termsAcceptedAt;
    if (json['terms_accepted_at'] != null) {
      try {
        termsAcceptedAt = DateTime.parse(json['terms_accepted_at']);
      } catch (_) {/* ignore */}
    }

    final rawPerms = json['permissions'];
    final perms = rawPerms is List
        ? rawPerms.map((e) => e.toString()).toList()
        : <String>[];

    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'],
      permissions: perms,
      host: host,
      brandingAppName: brandingAppName,
      termsAcceptedAt: termsAcceptedAt,
      termsVersion: json['terms_version'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'host': host?.toJson(),
      'branding': brandingAppName != null ? {'app_name': brandingAppName} : null,
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
