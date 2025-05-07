class Task {
  final int id;
  final int userId;
  final String text;
  final String status;
  final String type;
  final DateTime? dueDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Task({
    required this.id,
    required this.userId,
    required this.text,
    required this.status,
    required this.type,
    this.dueDate,
    this.createdAt,
    this.updatedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'],
        userId: json['user_id'],
        text: json['text'],
        status: json['status'],
        type: json['type'] ?? 'todo',
        dueDate: json['due_date'] != null ? DateTime.tryParse(json['due_date']) : null,
        createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
        updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'text': text,
        'status': status,
        'type': type,
        'due_date': dueDate?.toIso8601String(),
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };
} 