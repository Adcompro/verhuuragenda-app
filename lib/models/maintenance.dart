class MaintenanceTask {
  final int id;
  final int? accommodationId;
  final String? accommodationName;
  final String title;
  final String? description;
  final String priority; // low, medium, high, urgent
  final String status; // open, in_progress, waiting, completed, cancelled
  final String category; // repair, maintenance, cleaning, inventory, inspection, other
  final DateTime? dueDate;
  final DateTime? completedAt;
  final String? completedBy;
  final String? notes;
  final List<String> photos;
  final DateTime createdAt;
  final DateTime updatedAt;

  MaintenanceTask({
    required this.id,
    this.accommodationId,
    this.accommodationName,
    required this.title,
    this.description,
    required this.priority,
    required this.status,
    this.category = 'maintenance',
    this.dueDate,
    this.completedAt,
    this.completedBy,
    this.notes,
    this.photos = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory MaintenanceTask.fromJson(Map<String, dynamic> json) {
    List<String> photosList = [];
    if (json['photos'] != null) {
      if (json['photos'] is List) {
        photosList = (json['photos'] as List).map((p) => p.toString()).toList();
      }
    }

    return MaintenanceTask(
      id: json['id'] ?? 0,
      accommodationId: json['accommodation_id'],
      accommodationName: json['accommodation_name'] ?? json['accommodation']?['name'],
      title: json['title'] ?? '',
      description: json['description'],
      priority: json['priority'] ?? 'medium',
      status: json['status'] ?? 'open',
      category: json['category'] ?? 'maintenance',
      dueDate: json['due_date'] != null ? DateTime.tryParse(json['due_date']) : null,
      completedAt: json['completed_at'] != null ? DateTime.tryParse(json['completed_at']) : null,
      completedBy: json['completed_by'],
      notes: json['notes'],
      photos: photosList,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accommodation_id': accommodationId,
      'title': title,
      'description': description,
      'priority': priority,
      'status': status,
      'category': category,
      'due_date': dueDate?.toIso8601String().split('T')[0],
      'notes': notes,
    };
  }

  String get priorityLabel {
    switch (priority) {
      case 'urgent':
        return 'Spoed';
      case 'high':
        return 'Hoog';
      case 'medium':
        return 'Gemiddeld';
      case 'low':
        return 'Laag';
      default:
        return priority;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'open':
        return 'Open';
      case 'in_progress':
        return 'Bezig';
      case 'waiting':
        return 'Wachtend';
      case 'completed':
        return 'Afgerond';
      case 'cancelled':
        return 'Geannuleerd';
      default:
        return status;
    }
  }

  String get categoryLabel {
    switch (category) {
      case 'repair':
        return 'Reparatie';
      case 'maintenance':
        return 'Onderhoud';
      case 'cleaning':
        return 'Schoonmaak';
      case 'inventory':
        return 'Inventaris';
      case 'inspection':
        return 'Inspectie';
      case 'other':
        return 'Overig';
      default:
        return category;
    }
  }

  bool get isOverdue {
    if (dueDate == null || status == 'completed' || status == 'cancelled') {
      return false;
    }
    return dueDate!.isBefore(DateTime.now());
  }
}
