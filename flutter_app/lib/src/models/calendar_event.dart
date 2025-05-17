import 'package:flutter/material.dart';

class CalendarEvent {
  final int id;
  final int? userId;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final Color color;
  final bool isAllDay;
  final String source; // 'user', 'google', 'apple'
  final String? externalId; // ID from external calendar if imported
  final String status; // 'todo' or 'done'

  CalendarEvent({
    required this.id,
    required this.userId,
    required this.title,
    this.description = '',
    required this.startTime,
    required this.endTime,
    this.color = Colors.blue,
    this.isAllDay = false,
    this.source = 'user',
    this.externalId,
    required this.status,
  });

  factory CalendarEvent.fromTask(dynamic task) {
    if (task.type == 'longterm' || task.type == 'long_term') {
      throw Exception('longterm type should not be converted to CalendarEvent');
    }
    if (task.type == 'event') {
      final DateTime start = task.startDate ?? DateTime.now();
      final DateTime end = task.endDate ?? start.add(const Duration(hours: 1));
      return CalendarEvent(
        id: task.id,
        userId: task.userId,
        title: task.text,
        startTime: start,
        endTime: end,
        color: _getColorByType('event', task.status),
        source: 'task',
        status: task.status,
      );
    }
    final DateTime due = task.dueDate ?? DateTime.now();
    return CalendarEvent(
      id: task.id,
      userId: task.userId,
      title: '[DDL] ' + task.text,
      startTime: due,
      endTime: due,
      color: _getColorByType('ddl', task.status),
      source: 'task',
      status: task.status,
    );
  }

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      description: json['description'] ?? '',
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      color: Color(json['color'] ?? 0xFF2196F3),
      isAllDay: json['is_all_day'] ?? false,
      source: json['source'] ?? 'user',
      externalId: json['external_id'],
      status: json['status'] ?? 'todo',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'color': color.value,
      'is_all_day': isAllDay,
      'source': source,
      'external_id': externalId,
      'status': status,
    };
  }

  static Color _getColorByType(String type, String status) {
    if (status == 'done') return Colors.grey;
    switch (type) {
      case 'ddl':
        return Colors.red;
      case 'event':
        return Colors.blue;
      case 'longterm':
      case 'long_term':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }
} 