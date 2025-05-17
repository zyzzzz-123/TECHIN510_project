import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/task_service.dart';

class TaskProvider extends ChangeNotifier {
  int? _userId;
  List<Task> _todos = [];
  List<Task> _completed = [];
  bool _loading = false;

  TaskProvider({int? userId}) : _userId = userId;
  
  // Getter and Setter for userId
  int? get userId => _userId;
  set userId(int? value) {
    _userId = value;
    if (value != null) {
      fetchTasks(); // Fetch tasks when user ID is set
    } else {
      // Clear tasks when user logs out
      _todos = [];
      _completed = [];
    }
    notifyListeners();
  }

  List<Task> get todos => _todos;
  List<Task> get completed => _completed;
  bool get loading => _loading;

  Future<void> fetchTasks() async {
    if (_userId == null) {
      return; // If no user ID, don't fetch tasks
    }
    
    _loading = true;
    notifyListeners();
    _todos = await TaskService.fetchTasks(_userId!, status: 'todo');
    _completed = await TaskService.fetchTasks(_userId!, status: 'done');
    _loading = false;
    notifyListeners();
  }

  Future<void> addTask(String text, {String type = 'todo', DateTime? dueDate, DateTime? startDate, DateTime? endDate}) async {
    if (_userId == null) {
      throw Exception('User not logged in');
    }
    
    await TaskService.createTask(_userId!, text, type: type, dueDate: dueDate, startDate: startDate, endDate: endDate);
    await fetchTasks();
  }

  Future<void> markTaskDone(int taskId) async {
    await TaskService.markTaskDone(taskId);
    await fetchTasks();
  }

  Future<void> markTaskUndone(int taskId) async {
    await TaskService.markTaskUndone(taskId);
    await fetchTasks();
  }

  Future<void> updateTaskDueDate(int taskId, DateTime dueDate) async {
    await TaskService.updateTaskDueDate(taskId, dueDate);
    await fetchTasks();
  }

  Future<void> updateTask(int taskId, {String? text, DateTime? dueDate, DateTime? startDate, DateTime? endDate, String? type}) async {
    await TaskService.updateTask(taskId, text: text, dueDate: dueDate, startDate: startDate, endDate: endDate, type: type);
    await fetchTasks();
  }

  Future<void> deleteTask(int taskId) async {
    await TaskService.deleteTask(taskId);
    await fetchTasks();
  }
} 