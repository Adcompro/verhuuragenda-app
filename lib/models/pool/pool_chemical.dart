class PoolChemical {
  final int id;
  final int accommodationId;
  final String? accommodationName;
  final String chemicalType;
  final String? chemicalTypeLabel;
  final double amount;
  final String unit;
  final String? unitLabel;
  final String? formattedAmount;
  final DateTime addedAt;
  final String? notes;

  PoolChemical({
    required this.id,
    required this.accommodationId,
    this.accommodationName,
    required this.chemicalType,
    this.chemicalTypeLabel,
    required this.amount,
    required this.unit,
    this.unitLabel,
    this.formattedAmount,
    required this.addedAt,
    this.notes,
  });

  factory PoolChemical.fromJson(Map<String, dynamic> json) {
    return PoolChemical(
      id: json['id'] ?? 0,
      accommodationId: json['accommodation_id'] ?? 0,
      accommodationName: json['accommodation_name'],
      chemicalType: json['chemical_type'] ?? '',
      chemicalTypeLabel: json['chemical_type_label'],
      amount: _parseDouble(json['amount']) ?? 0.0,
      unit: json['unit'] ?? 'gram',
      unitLabel: json['unit_label'],
      formattedAmount: json['formatted_amount'],
      addedAt: json['added_at'] != null
          ? DateTime.parse(json['added_at'])
          : DateTime.now(),
      notes: json['notes'],
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'accommodation_id': accommodationId,
      'chemical_type': chemicalType,
      'amount': amount,
      'unit': unit,
      'added_at': addedAt.toIso8601String(),
      'notes': notes,
    };
  }

  String get displayLabel => chemicalTypeLabel ?? _getDefaultLabel();
  String get displayAmount => formattedAmount ?? '$amount ${unitLabel ?? unit}';

  String _getDefaultLabel() {
    switch (chemicalType) {
      case 'chlorine_tablet':
        return 'Chloortabletten';
      case 'chlorine_granule':
        return 'Chloorgranulaat';
      case 'chlorine_liquid':
        return 'Vloeibaar chloor';
      case 'ph_plus':
        return 'pH-plus';
      case 'ph_minus':
        return 'pH-min';
      case 'anti_algae':
        return 'Anti-alg';
      case 'flocculant':
        return 'Vlokmiddel';
      case 'shock':
        return 'Chloorschok';
      case 'other':
        return 'Overig';
      default:
        return chemicalType;
    }
  }
}

class ChemicalType {
  final String value;
  final String label;

  ChemicalType({required this.value, required this.label});

  factory ChemicalType.fromJson(Map<String, dynamic> json) {
    return ChemicalType(
      value: json['value'] ?? '',
      label: json['label'] ?? '',
    );
  }

  static List<ChemicalType> defaultTypes = [
    ChemicalType(value: 'chlorine_tablet', label: 'Chloortabletten'),
    ChemicalType(value: 'chlorine_granule', label: 'Chloorgranulaat'),
    ChemicalType(value: 'chlorine_liquid', label: 'Vloeibaar chloor'),
    ChemicalType(value: 'ph_plus', label: 'pH-plus'),
    ChemicalType(value: 'ph_minus', label: 'pH-min'),
    ChemicalType(value: 'anti_algae', label: 'Anti-alg'),
    ChemicalType(value: 'flocculant', label: 'Vlokmiddel'),
    ChemicalType(value: 'shock', label: 'Chloorschok'),
    ChemicalType(value: 'other', label: 'Overig'),
  ];
}

class ChemicalUnit {
  final String value;
  final String label;

  ChemicalUnit({required this.value, required this.label});

  factory ChemicalUnit.fromJson(Map<String, dynamic> json) {
    return ChemicalUnit(
      value: json['value'] ?? '',
      label: json['label'] ?? '',
    );
  }

  static List<ChemicalUnit> defaultUnits = [
    ChemicalUnit(value: 'gram', label: 'gram'),
    ChemicalUnit(value: 'ml', label: 'ml'),
    ChemicalUnit(value: 'tablet', label: 'tablet(ten)'),
    ChemicalUnit(value: 'kg', label: 'kg'),
    ChemicalUnit(value: 'liter', label: 'liter'),
  ];
}
