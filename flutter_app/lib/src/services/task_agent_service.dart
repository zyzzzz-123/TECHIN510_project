import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../services/task_service.dart';
import '../models/task.dart';

enum TaskAction {
  query,
  create,
  update,
  delete,
  none
}

class TaskIntent {
  final TaskAction action;
  final Map<String, dynamic> data;
  
  TaskIntent({required this.action, this.data = const {}});
  
  factory TaskIntent.fromJson(Map<String, dynamic> json) {
    TaskAction action = TaskAction.none;
    
    if (json['action'] == 'query_task') {
      action = TaskAction.query;
    } else if (json['action'] == 'add_task') {
      action = TaskAction.create;
    } else if (json['action'] == 'update_task') {
      action = TaskAction.update;
    } else if (json['action'] == 'delete_task') {
      action = TaskAction.delete;
    }
    
    return TaskIntent(
      action: action,
      data: json['task'] != null ? Map<String, dynamic>.from(json['task']) : {},
    );
  }
  
  bool get hasTask => data.isNotEmpty;
  
  String get confirmationMessage => 
    data['confirmation_prompt'] as String? ?? 'Confirm this action?';
}

class TaskAgentService {
  // 解析AI响应，尝试提取任务意图
  static TaskIntent? parseAIResponse(String response) {
    try {
      // 尝试将响应解析为JSON
      final json = jsonDecode(response);
      
      // 检查是否包含action字段
      if (json is Map<String, dynamic> && json.containsKey('action')) {
        return TaskIntent.fromJson(json);
      }
    } catch (e) {
      print('Not a valid JSON response or not a task action: $e');
    }
    
    return null; // 不是可解析的任务意图
  }
  
  // 根据用户查询获取任务
  static Future<List<Task>> queryTasks(int userId, String query) async {
    // 使用AI来理解查询意图
    final aiResponse = await ChatService.sendMessage(
      'Parse the following query and respond with JSON containing query parameters. ' +
      'Query: "$query". ' +
      'Return JSON with fields: status (todo/done/all), type (todo/goal/all), ' +
      'date_filter (today/this_week/this_month/all), sort_by (due_date/created_at).',
      modelProvider: 'openai'
    );
    
    try {
      final Map<String, dynamic> queryParams = jsonDecode(aiResponse);
      String? status = queryParams['status'] != 'all' ? queryParams['status'] : null;
      
      // 获取任务列表
      final tasks = await TaskService.fetchTasks(userId, status: status);
      
      // 应用其他过滤条件
      var filteredTasks = tasks.where((task) {
        // 类型过滤
        if (queryParams['type'] != 'all' && task.type != queryParams['type']) {
          return false;
        }
        
        // 日期过滤
        if (queryParams['date_filter'] != 'all') {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          
          if (queryParams['date_filter'] == 'today') {
            if (task.dueDate == null || 
                task.dueDate!.year != today.year || 
                task.dueDate!.month != today.month || 
                task.dueDate!.day != today.day) {
              return false;
            }
          } else if (queryParams['date_filter'] == 'this_week') {
            final weekStart = today.subtract(Duration(days: today.weekday - 1));
            final weekEnd = weekStart.add(Duration(days: 6));
            if (task.dueDate == null || 
                task.dueDate!.isBefore(weekStart) || 
                task.dueDate!.isAfter(weekEnd)) {
              return false;
            }
          } else if (queryParams['date_filter'] == 'this_month') {
            if (task.dueDate == null || 
                task.dueDate!.year != today.year || 
                task.dueDate!.month != today.month) {
              return false;
            }
          }
        }
        
        return true;
      }).toList();
      
      // 排序
      if (queryParams['sort_by'] == 'due_date') {
        filteredTasks.sort((a, b) {
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
      } else {
        filteredTasks.sort((a, b) {
          if (a.createdAt == null) return 1;
          if (b.createdAt == null) return -1;
          return b.createdAt!.compareTo(a.createdAt!);
        });
      }
      
      return filteredTasks;
    } catch (e) {
      print('Error parsing AI response for query: $e');
      // 如果AI解析失败，返回所有待办任务
      return await TaskService.fetchTasks(userId, status: 'todo');
    }
  }
  
  // 处理对任务的操作
  static Future<TaskIntent?> processUserRequest(int userId, String userMessage) async {
    // 发送用户消息到AI服务
    final aiResponse = await ChatService.sendMessage(
      'You are a task management assistant. ' +
      'If the user wants to add, update, or delete a task, respond with a JSON object in this format: ' +
      '{"action": "add_task|update_task|delete_task|query_task", "task": { task properties }, "confirmation_prompt": "..."} ' +
      'For add_task: include text (required), due_date (ISO format, optional), type (todo/goal, optional) ' +
      'For update_task: include id (required), and any of text, due_date, status, type ' +
      'For delete_task: include id (required) ' +
      'For query_task: include filter conditions ' +
      'The confirmation_prompt should clearly describe the action. ' +
      'If not a task operation, respond normally. ' +
      'User message: $userMessage',
      modelProvider: 'openai'
    );
    
    // 解析AI响应
    final intent = parseAIResponse(aiResponse);
    if (intent == null) {
      // 不是任务操作，返回null
      return null;
    }
    
    // 设置用户ID
    if (intent.hasTask && intent.action != TaskAction.query) {
      intent.data['user_id'] = userId;
    }
    
    return intent;
  }
  
  // 执行任务创建
  static Future<Task> createTask(int userId, Map<String, dynamic> taskData) async {
    String text = taskData['text'] ?? 'New Task';
    String type = taskData['type'] ?? 'todo';
    
    DateTime? dueDate;
    if (taskData['due_date'] != null) {
      try {
        dueDate = DateTime.parse(taskData['due_date']);
      } catch (e) {
        print('Invalid due date format: ${taskData['due_date']}');
      }
    }
    
    return await TaskService.createTask(
      userId, 
      text,
      type: type,
      dueDate: dueDate
    );
  }
  
  // 执行任务更新
  static Future<void> updateTask(Map<String, dynamic> taskData) async {
    int taskId = taskData['id'];
    
    Map<String, dynamic> updateData = {};
    
    if (taskData['text'] != null) {
      updateData['text'] = taskData['text'];
    }
    
    if (taskData['due_date'] != null) {
      try {
        updateData['dueDate'] = DateTime.parse(taskData['due_date']);
      } catch (e) {
        print('Invalid due date format: ${taskData['due_date']}');
      }
    }
    
    if (taskData['status'] != null) {
      updateData['status'] = taskData['status'];
    }
    
    if (taskData['type'] != null) {
      updateData['type'] = taskData['type'];
    }
    
    await TaskService.updateTask(
      taskId,
      text: updateData['text'],
      dueDate: updateData['dueDate'],
      type: updateData['type']
    );
    
    // 如果需要更新状态
    if (updateData['status'] == 'done') {
      await TaskService.markTaskDone(taskId);
    } else if (updateData['status'] == 'todo') {
      await TaskService.markTaskUndone(taskId);
    }
  }
  
  // 执行任务删除
  static Future<void> deleteTask(int taskId) async {
    await TaskService.deleteTask(taskId);
  }
} 