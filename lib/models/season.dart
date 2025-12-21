class Season {
  final int id;
  final String name;
  final String type;
  final String typeLabel;
  final int year;
  final String startDate;
  final String endDate;

  Season({
    required this.id,
    required this.name,
    required this.type,
    required this.typeLabel,
    required this.year,
    required this.startDate,
    required this.endDate,
  });

  factory Season.fromJson(Map<String, dynamic> json) {
    return Season(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      type: json['type'] ?? 'mid',
      typeLabel: json['type_label'] ?? 'Middenseizoen',
      year: json['year'] ?? DateTime.now().year,
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'year': year,
      'start_date': startDate,
      'end_date': endDate,
    };
  }

  String get typeIcon {
    switch (type) {
      case 'low':
        return 'snowflake';
      case 'high':
        return 'sun';
      default:
        return 'cloud';
    }
  }
}
