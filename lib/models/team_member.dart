class TeamMember {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? roleLabel;
  final bool isActive;
  final bool isOwner;
  final String? status;
  final String? statusLabel;
  final String? createdAt;

  TeamMember({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.roleLabel,
    required this.isActive,
    this.isOwner = false,
    this.status,
    this.statusLabel,
    this.createdAt,
  });

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'viewer',
      roleLabel: json['role_label'],
      isActive: json['is_active'] ?? true,
      isOwner: json['is_owner'] ?? false,
      status: json['status'],
      statusLabel: json['status_label'],
      createdAt: json['created_at'],
    );
  }
}

class TeamRole {
  final String value;
  final String label;
  final String description;
  final String color;

  TeamRole({
    required this.value,
    required this.label,
    required this.description,
    required this.color,
  });

  factory TeamRole.fromJson(Map<String, dynamic> json) {
    return TeamRole(
      value: json['value'] ?? '',
      label: json['label'] ?? '',
      description: json['description'] ?? '',
      color: json['color'] ?? 'gray',
    );
  }
}
