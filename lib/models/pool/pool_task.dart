class PoolTask {
  final int id;
  final int accommodationId;
  final String? accommodationName;
  final String taskType;
  final String? taskTypeLabel;
  final DateTime performedAt;
  final String? notes;

  PoolTask({
    required this.id,
    required this.accommodationId,
    this.accommodationName,
    required this.taskType,
    this.taskTypeLabel,
    required this.performedAt,
    this.notes,
  });

  factory PoolTask.fromJson(Map<String, dynamic> json) {
    return PoolTask(
      id: _parseInt(json['id']) ?? 0,
      accommodationId: _parseInt(json['accommodation_id']) ?? 0,
      accommodationName: json['accommodation_name'],
      taskType: json['task_type'] ?? '',
      taskTypeLabel: json['task_type_label'],
      performedAt: json['performed_at'] != null
          ? DateTime.tryParse(json['performed_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      notes: json['notes'],
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'accommodation_id': accommodationId,
      'task_type': taskType,
      'performed_at': performedAt.toIso8601String(),
      'notes': notes,
    };
  }

  String get displayLabel => taskTypeLabel ?? _getDefaultLabel();

  String _getDefaultLabel() {
    switch (taskType) {
      case 'filter_clean':
        return 'Filter schoonmaken';
      case 'skimmer_empty':
        return 'Skimmer legen';
      case 'robot_run':
        return 'Robot gedraaid';
      case 'water_level':
        return 'Waterstand gecontroleerd';
      case 'pump_check':
        return 'Pomp gecontroleerd';
      case 'brush_walls':
        return 'Wanden geborsteld';
      case 'winterize':
        return 'Winterklaar gemaakt';
      case 'other':
        return 'Overig';
      default:
        return taskType;
    }
  }
}

class PoolTaskType {
  final String value;
  final String label;

  PoolTaskType({required this.value, required this.label});

  factory PoolTaskType.fromJson(Map<String, dynamic> json) {
    return PoolTaskType(
      value: json['value'] ?? '',
      label: json['label'] ?? '',
    );
  }

  static List<PoolTaskType> defaultTypes = [
    PoolTaskType(value: 'filter_clean', label: 'Filter schoonmaken'),
    PoolTaskType(value: 'skimmer_empty', label: 'Skimmer legen'),
    PoolTaskType(value: 'robot_run', label: 'Robot gedraaid'),
    PoolTaskType(value: 'water_level', label: 'Waterstand gecontroleerd'),
    PoolTaskType(value: 'pump_check', label: 'Pomp gecontroleerd'),
    PoolTaskType(value: 'brush_walls', label: 'Wanden geborsteld'),
    PoolTaskType(value: 'winterize', label: 'Winterklaar gemaakt'),
    PoolTaskType(value: 'other', label: 'Overig'),
  ];
}
