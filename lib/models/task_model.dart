class Task {
  final int id;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime? completedAt;
  final bool isCompleted;
  final int salesRepId;
  final String priority;
  final String status;
  final AssignedBy? assignedBy;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    this.completedAt,
    required this.isCompleted,
    required this.salesRepId,
    required this.priority,
    required this.status,
    this.assignedBy,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      isCompleted: json['isCompleted'],
      salesRepId: json['salesRepId'],
      priority: json['priority'],
      status: json['status'],
      assignedBy: json['assignedBy'] != null
          ? AssignedBy.fromJson(json['assignedBy'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'isCompleted': isCompleted,
      'salesRepId': salesRepId,
      'priority': priority,
      'status': status,
      'assignedBy': assignedBy?.toJson(),
    };
  }

  String get formattedCreatedDate {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  String get formattedCompletedDate {
    if (completedAt == null) return 'Not completed';
    return '${completedAt!.day}/${completedAt!.month}/${completedAt!.year}';
  }

  String get priorityColor {
    switch (priority.toLowerCase()) {
      case 'high':
        return 'red';
      case 'medium':
        return 'orange';
      case 'low':
        return 'green';
      default:
        return 'grey';
    }
  }
}

class AssignedBy {
  final int id;
  final String username;

  AssignedBy({
    required this.id,
    required this.username,
  });

  factory AssignedBy.fromJson(Map<String, dynamic> json) {
    return AssignedBy(
      id: json['id'],
      username: json['username'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
    };
  }
}
