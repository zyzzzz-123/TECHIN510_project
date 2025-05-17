import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task.dart';
import '../config.dart';

class TaskService {
  static Future<List<Task>> fetchTasks(int userId, {String? status}) async {
    final url = Uri.parse('$baseUrl/api/tasks/user/$userId${status != null ? '?status=$status' : ''}');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Task.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load tasks');
    }
  }

  static Future<Task> createTask(int userId, String text, {String type = 'todo', DateTime? dueDate, DateTime? startDate, DateTime? endDate}) async {
    final url = Uri.parse('$baseUrl/api/tasks/');
    final body = {
      'user_id': userId,
      'text': text,
      'type': type,
    };
    if (dueDate != null) body['due_date'] = dueDate.toIso8601String();
    if (startDate != null) body['start_date'] = startDate.toIso8601String();
    if (endDate != null) body['end_date'] = endDate.toIso8601String();
    print('createTask body: ' + body.toString());
    final response = await http.post(url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode == 201) {
      return Task.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create task');
    }
  }

  static Future<void> markTaskDone(int taskId) async {
    final url = Uri.parse('$baseUrl/api/tasks/$taskId');
    final response = await http.patch(url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': 'done'}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update task');
    }
  }

  static Future<void> markTaskUndone(int taskId) async {
    final url = Uri.parse('$baseUrl/api/tasks/$taskId');
    final response = await http.patch(url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': 'todo'}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update task');
    }
  }

  static Future<void> updateTaskDueDate(int taskId, DateTime dueDate) async {
    final url = Uri.parse('$baseUrl/api/tasks/$taskId');
    final response = await http.patch(url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'due_date': dueDate.toIso8601String()}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update due date');
    }
  }

  static Future<void> updateTask(int taskId, {String? text, DateTime? dueDate, DateTime? startDate, DateTime? endDate, String? type}) async {
    final url = Uri.parse('$baseUrl/api/tasks/$taskId');
    final Map<String, dynamic> body = {};
    if (text != null) body['text'] = text;
    if (dueDate != null) body['due_date'] = dueDate.toIso8601String();
    if (startDate != null) body['start_date'] = startDate.toIso8601String();
    if (endDate != null) body['end_date'] = endDate.toIso8601String();
    if (type != null) body['type'] = type;
    if (body.isEmpty) return;
    print('updateTask body: ' + body.toString());
    final response = await http.patch(url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update task');
    }
  }

  static Future<void> deleteTask(int taskId) async {
    final url = Uri.parse('$baseUrl/api/tasks/$taskId');
    final response = await http.delete(url);
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Failed to delete task');
    }
  }
} 