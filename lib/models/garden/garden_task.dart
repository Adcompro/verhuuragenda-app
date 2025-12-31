class GardenTask {
  final int? id;
  final int accommodationId;
  final String? accommodationName;
  final String title;
  final String? description;
  final String category;
  final String? categoryLabel;
  final String priority;
  final String? priorityLabel;
  final String status;
  final String? statusLabel;
  final DateTime? dueDate;
  final String? dueDateFormatted;
  final bool isOverdue;
  final int? estimatedMinutes;
  final int? actualMinutes;
  final String? notes;
  final List<String>? photos;
  final List<String>? photoUrls;
  final bool isRecurring;
  final String? recurringInterval;
  final String? recurringIntervalLabel;
  final int? recurringDay;
  final DateTime? completedAt;
  final String? completedAtFormatted;
  final int? completedBy;
  final String? completedByName;
  final DateTime? createdAt;

  GardenTask({
    this.id,
    required this.accommodationId,
    this.accommodationName,
    required this.title,
    this.description,
    required this.category,
    this.categoryLabel,
    required this.priority,
    this.priorityLabel,
    required this.status,
    this.statusLabel,
    this.dueDate,
    this.dueDateFormatted,
    this.isOverdue = false,
    this.estimatedMinutes,
    this.actualMinutes,
    this.notes,
    this.photos,
    this.photoUrls,
    this.isRecurring = false,
    this.recurringInterval,
    this.recurringIntervalLabel,
    this.recurringDay,
    this.completedAt,
    this.completedAtFormatted,
    this.completedBy,
    this.completedByName,
    this.createdAt,
  });

  factory GardenTask.fromJson(Map<String, dynamic> json) {
    return GardenTask(
      id: _parseInt(json['id']),
      accommodationId: _parseInt(json['accommodation_id']) ?? 0,
      accommodationName: json['accommodation_name'],
      title: json['title'] ?? '',
      description: json['description'],
      category: json['category'] ?? 'other',
      categoryLabel: json['category_label'],
      priority: json['priority'] ?? 'medium',
      priorityLabel: json['priority_label'],
      status: json['status'] ?? 'todo',
      statusLabel: json['status_label'],
      dueDate: json['due_date'] != null ? DateTime.tryParse(json['due_date'].toString()) : null,
      dueDateFormatted: json['due_date_formatted'],
      isOverdue: json['is_overdue'] ?? false,
      estimatedMinutes: _parseInt(json['estimated_minutes']),
      actualMinutes: _parseInt(json['actual_minutes']),
      notes: json['notes'],
      photos: json['photos'] != null ? List<String>.from(json['photos']) : null,
      photoUrls: json['photo_urls'] != null ? List<String>.from(json['photo_urls']) : null,
      isRecurring: json['is_recurring'] ?? false,
      recurringInterval: json['recurring_interval'],
      recurringIntervalLabel: json['recurring_interval_label'],
      recurringDay: _parseInt(json['recurring_day']),
      completedAt: json['completed_at'] != null ? DateTime.tryParse(json['completed_at'].toString()) : null,
      completedAtFormatted: json['completed_at_formatted'],
      completedBy: _parseInt(json['completed_by']),
      completedByName: json['completed_by_name'],
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
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
      if (id != null) 'id': id,
      'accommodation_id': accommodationId,
      'title': title,
      'description': description,
      'category': category,
      'priority': priority,
      'status': status,
      'due_date': dueDate?.toIso8601String().split('T')[0],
      'estimated_minutes': estimatedMinutes,
      'actual_minutes': actualMinutes,
      'notes': notes,
      'is_recurring': isRecurring,
      'recurring_interval': recurringInterval,
      'recurring_day': recurringDay,
    };
  }

  bool get isTodo => status == 'todo' || status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get hasPhotos => photos != null && photos!.isNotEmpty;

  GardenTask copyWith({
    int? id,
    int? accommodationId,
    String? accommodationName,
    String? title,
    String? description,
    String? category,
    String? categoryLabel,
    String? priority,
    String? priorityLabel,
    String? status,
    String? statusLabel,
    DateTime? dueDate,
    String? dueDateFormatted,
    bool? isOverdue,
    int? estimatedMinutes,
    int? actualMinutes,
    String? notes,
    List<String>? photos,
    List<String>? photoUrls,
    bool? isRecurring,
    String? recurringInterval,
    String? recurringIntervalLabel,
    int? recurringDay,
    DateTime? completedAt,
    String? completedAtFormatted,
    int? completedBy,
    String? completedByName,
    DateTime? createdAt,
  }) {
    return GardenTask(
      id: id ?? this.id,
      accommodationId: accommodationId ?? this.accommodationId,
      accommodationName: accommodationName ?? this.accommodationName,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      categoryLabel: categoryLabel ?? this.categoryLabel,
      priority: priority ?? this.priority,
      priorityLabel: priorityLabel ?? this.priorityLabel,
      status: status ?? this.status,
      statusLabel: statusLabel ?? this.statusLabel,
      dueDate: dueDate ?? this.dueDate,
      dueDateFormatted: dueDateFormatted ?? this.dueDateFormatted,
      isOverdue: isOverdue ?? this.isOverdue,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      actualMinutes: actualMinutes ?? this.actualMinutes,
      notes: notes ?? this.notes,
      photos: photos ?? this.photos,
      photoUrls: photoUrls ?? this.photoUrls,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringInterval: recurringInterval ?? this.recurringInterval,
      recurringIntervalLabel: recurringIntervalLabel ?? this.recurringIntervalLabel,
      recurringDay: recurringDay ?? this.recurringDay,
      completedAt: completedAt ?? this.completedAt,
      completedAtFormatted: completedAtFormatted ?? this.completedAtFormatted,
      completedBy: completedBy ?? this.completedBy,
      completedByName: completedByName ?? this.completedByName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// Category icons and labels
class GardenCategory {
  static const Map<String, String> labels = {
    'mowing': 'Grasmaaien',
    'pruning': 'Snoeien',
    'weeding': 'Onkruid wieden',
    'fertilizing': 'Bemesten',
    'watering': 'Water geven',
    'leaf_removal': 'Bladeren ruimen',
    'hedge_trimming': 'Haag knippen',
    'planting': 'Planten',
    'seeding': 'Zaaien',
    'composting': 'Composteren',
    'tool_maintenance': 'Gereedschap onderhoud',
    'other': 'Overig',
  };

  static const List<String> all = [
    'mowing',
    'pruning',
    'weeding',
    'fertilizing',
    'watering',
    'leaf_removal',
    'hedge_trimming',
    'planting',
    'seeding',
    'composting',
    'tool_maintenance',
    'other',
  ];
}

// Priority labels
class GardenPriority {
  static const Map<String, String> labels = {
    'low': 'Laag',
    'medium': 'Midden',
    'high': 'Hoog',
    'urgent': 'Urgent',
  };

  static const List<String> all = ['low', 'medium', 'high', 'urgent'];
}

// Status labels
class GardenStatus {
  static const Map<String, String> labels = {
    'todo': 'Te doen',
    'in_progress': 'Bezig',
    'completed': 'Voltooid',
    'cancelled': 'Geannuleerd',
  };

  static const List<String> all = ['todo', 'in_progress', 'completed', 'cancelled'];
}

// Recurring interval labels
class RecurringInterval {
  static const Map<String, String> labels = {
    'daily': 'Dagelijks',
    'weekly': 'Wekelijks',
    'biweekly': 'Tweewekelijks',
    'monthly': 'Maandelijks',
    'quarterly': 'Per kwartaal',
    'yearly': 'Jaarlijks',
  };

  static const List<String> all = ['daily', 'weekly', 'biweekly', 'monthly', 'quarterly', 'yearly'];
}
