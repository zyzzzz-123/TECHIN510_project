import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/task_service.dart';

class TaskProvider extends ChangeNotifier {
  final int userId;
  List<Task> _todos = [];
  List<Task> _completed = [];
  bool _loading = false;

  TaskProvider({required this.userId});

  List<Task> get todos => _todos;
  List<Task> get completed => _completed;
  bool get loading => _loading;

  Future<void> fetchTasks() async {
    _loading = true;
    notifyListeners();
    _todos = await TaskService.fetchTasks(userId, status: 'todo');
    _completed = await TaskService.fetchTasks(userId, status: 'done');
    _loading = false;
    notifyListeners();
  }

  Future<void> addTask(String text, {String type = 'todo', DateTime? dueDate}) async {
    await TaskService.createTask(userId, text, type: type, dueDate: dueDate);
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

  Future<void> updateTask(int taskId, {String? text, DateTime? dueDate, String? type}) async {
    await TaskService.updateTask(taskId, text: text, dueDate: dueDate, type: type);
    await fetchTasks();
  }
} 