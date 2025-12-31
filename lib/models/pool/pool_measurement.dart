class PoolMeasurement {
  final int id;
  final int accommodationId;
  final String? accommodationName;
  final DateTime measuredAt;
  final double? phValue;
  final String? phStatus; // ok, low, high
  final double? freeChlorine;
  final String? chlorineStatus; // ok, low, high
  final double? totalChlorine;
  final int? alkalinity;
  final double? waterTemperature;
  final int? cyanuricAcid;
  final int? calciumHardness;
  final int? tds;
  final String? notes;

  PoolMeasurement({
    required this.id,
    required this.accommodationId,
    this.accommodationName,
    required this.measuredAt,
    this.phValue,
    this.phStatus,
    this.freeChlorine,
    this.chlorineStatus,
    this.totalChlorine,
    this.alkalinity,
    this.waterTemperature,
    this.cyanuricAcid,
    this.calciumHardness,
    this.tds,
    this.notes,
  });

  factory PoolMeasurement.fromJson(Map<String, dynamic> json) {
    return PoolMeasurement(
      id: json['id'] ?? 0,
      accommodationId: json['accommodation_id'] ?? 0,
      accommodationName: json['accommodation_name'],
      measuredAt: json['measured_at'] != null
          ? DateTime.parse(json['measured_at'])
          : DateTime.now(),
      phValue: _parseDouble(json['ph_value']),
      phStatus: json['ph_status'],
      freeChlorine: _parseDouble(json['free_chlorine']),
      chlorineStatus: json['chlorine_status'],
      totalChlorine: _parseDouble(json['total_chlorine']),
      alkalinity: json['alkalinity'] != null ? int.tryParse(json['alkalinity'].toString()) : null,
      waterTemperature: _parseDouble(json['water_temperature']),
      cyanuricAcid: json['cyanuric_acid'] != null ? int.tryParse(json['cyanuric_acid'].toString()) : null,
      calciumHardness: json['calcium_hardness'] != null ? int.tryParse(json['calcium_hardness'].toString()) : null,
      tds: json['tds'] != null ? int.tryParse(json['tds'].toString()) : null,
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
      'measured_at': measuredAt.toIso8601String(),
      'ph_value': phValue,
      'free_chlorine': freeChlorine,
      'total_chlorine': totalChlorine,
      'alkalinity': alkalinity,
      'water_temperature': waterTemperature,
      'cyanuric_acid': cyanuricAcid,
      'calcium_hardness': calciumHardness,
      'tds': tds,
      'notes': notes,
    };
  }

  bool get isPhOk => phStatus == 'ok';
  bool get isChlorineOk => chlorineStatus == 'ok';
}

class IdealRanges {
  final double phMin;
  final double phMax;
  final double chlorineMin;
  final double chlorineMax;
  final int alkalinityMin;
  final int alkalinityMax;
  final double tempMin;
  final double tempMax;

  IdealRanges({
    this.phMin = 7.2,
    this.phMax = 7.6,
    this.chlorineMin = 1.0,
    this.chlorineMax = 3.0,
    this.alkalinityMin = 80,
    this.alkalinityMax = 120,
    this.tempMin = 26.0,
    this.tempMax = 28.0,
  });

  factory IdealRanges.fromJson(Map<String, dynamic> json) {
    return IdealRanges(
      phMin: _parseDouble(json['ph']?['min']) ?? 7.2,
      phMax: _parseDouble(json['ph']?['max']) ?? 7.6,
      chlorineMin: _parseDouble(json['chlorine']?['min']) ?? 1.0,
      chlorineMax: _parseDouble(json['chlorine']?['max']) ?? 3.0,
      alkalinityMin: json['alkalinity']?['min'] ?? 80,
      alkalinityMax: json['alkalinity']?['max'] ?? 120,
      tempMin: _parseDouble(json['temperature']?['min']) ?? 26.0,
      tempMax: _parseDouble(json['temperature']?['max']) ?? 28.0,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
