import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';
import '../services/chat_history_service.dart';
import '../services/task_agent_service.dart';
import 'dart:convert';
import '../services/auth_service.dart';

class ChatProvider extends ChangeNotifier {
  int? _userId;
  List<ChatMessage> _messages = [];
  List<GroupedChatMessages> _groupedHistory = [];
  bool _loading = false;
  bool _historyLoading = false;
  String? _error;
  String _selectedModel = 'openai';
  TaskIntent? _pendingTaskIntent;
  String? _authToken;
  
  // Getters
  List<ChatMessage> get messages => _messages;
  List<GroupedChatMessages> get groupedHistory => _groupedHistory;
  bool get loading => _loading;
  bool get historyLoading => _historyLoading;
  String? get error => _error;
  String get selectedModel => _selectedModel;
  TaskIntent? get pendingTaskIntent => _pendingTaskIntent;
  
  // 更新用户信息
  void updateUser(int? userId, String? token) {
    _userId = userId;
    _authToken = token;
    if (userId != null && token != null) {
      fetchChatHistory();
    } else {
      _groupedHistory = [];
      _messages = [];
    }
    notifyListeners();
  }
  
  // 更新选择的模型
  void setSelectedModel(String model) {
    _selectedModel = model;
    notifyListeners();
  }
  
  // 加载聊天历史
  Future<void> fetchChatHistory() async {
    if (_userId == null || _authToken == null) return;
    
    _historyLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _groupedHistory = await ChatHistoryService.getChatHistory(
        authToken: _authToken,
      );
      
      // 加载最近的一组消息作为当前会话
      if (_groupedHistory.isNotEmpty) {
        _messages = _groupedHistory.first.messages;
      }
    } catch (e) {
      _error = 'Failed to load chat history: $e';
    } finally {
      _historyLoading = false;
      notifyListeners();
    }
  }
  
  // 发送消息
  Future<void> sendMessage(String message) async {
    if (_userId == null) {
      _error = '请先登录';
      notifyListeners();
      return;
    }
    
    if (message.trim().isEmpty) return;
    
    // 添加用户消息
    final userMessage = ChatMessage(
      role: 'user',
      content: message,
      createdAt: DateTime.now(),
    );
    
    _messages.add(userMessage);
    _loading = true;
    _error = null;
    notifyListeners();
    
    try {
      // 首先尝试分析任务意图
      final taskIntent = await TaskAgentService.processUserRequest(_userId!, message);
      
      if (taskIntent != null) {
        // 找到任务意图
        _pendingTaskIntent = taskIntent;
        
        // 如果是查询操作，直接执行
        if (taskIntent.action == TaskAction.query) {
          await _executeQueryTask(_userId!, message);
        }
      } else {
        // 没有找到任务意图，使用正常的聊天
        final messages = _messages.map((msg) => {
          'role': msg.role,
          'content': msg.content,
        }).toList();
        
        final aiReply = await ChatService.sendMessages(
          messages,
          modelProvider: _selectedModel,
        );
        
        // 尝试解析为JSON，检查是否是旧格式的任务操作
        Map<String, dynamic>? actionJson;
        try {
          actionJson = jsonDecode(aiReply);
          if (actionJson is! Map || actionJson['action'] == null) {
            actionJson = null;
          }
        } catch (_) {
          actionJson = null;
        }
        
        final assistantMessage = ChatMessage(
          role: 'assistant',
          content: aiReply,
          createdAt: DateTime.now(),
          modelProvider: _selectedModel,
        );
        
        _messages.add(assistantMessage);
        
        // 如果是旧格式的任务操作
        if (actionJson != null && actionJson['confirmation_prompt'] != null) {
          // 这里可以扩展处理旧格式任务操作的逻辑
        }
      }
    } catch (e) {
      _error = 'Error: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
  
  // 执行任务查询
  Future<void> _executeQueryTask(int userId, String query) async {
    try {
      final tasks = await TaskAgentService.queryTasks(userId, query);
      
      final assistantMessage = ChatMessage(
        role: 'assistant',
        content: '查询到 ${tasks.length} 个任务',
        createdAt: DateTime.now(),
      );
      
      _messages.add(assistantMessage);
      // 这里可以添加逻辑显示查询结果
      
    } catch (e) {
      _error = 'Failed to query tasks: $e';
    }
  }
  
  // 确认任务操作
  Future<void> confirmTaskAction() async {
    if (_pendingTaskIntent == null || _userId == null) return;
    
    _loading = true;
    notifyListeners();
    
    try {
      String resultMessage = '';
      
      switch (_pendingTaskIntent!.action) {
        case TaskAction.create:
          final task = await TaskAgentService.createTask(_userId!, _pendingTaskIntent!.data);
          resultMessage = '已创建任务: ${task.text}';
          break;
          
        case TaskAction.update:
          await TaskAgentService.updateTask(_pendingTaskIntent!.data);
          resultMessage = '已更新任务ID: ${_pendingTaskIntent!.data['id']}';
          break;
          
        case TaskAction.delete:
          await TaskAgentService.deleteTask(_pendingTaskIntent!.data['id']);
          resultMessage = '已删除任务ID: ${_pendingTaskIntent!.data['id']}';
          break;
          
        default:
          resultMessage = '未知操作';
      }
      
      // 添加确认和结果消息
      _messages.add(ChatMessage(
        role: 'user',
        content: '确认',
        createdAt: DateTime.now(),
      ));
      
      _messages.add(ChatMessage(
        role: 'assistant',
        content: resultMessage,
        createdAt: DateTime.now(),
      ));
      
      _pendingTaskIntent = null;
    } catch (e) {
      _error = '操作失败: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
  
  // 取消任务操作
  void cancelTaskAction() {
    _messages.add(ChatMessage(
      role: 'user',
      content: '取消',
      createdAt: DateTime.now(),
    ));
    
    _messages.add(ChatMessage(
      role: 'assistant',
      content: '已取消操作',
      createdAt: DateTime.now(),
    ));
    
    _pendingTaskIntent = null;
    notifyListeners();
  }
  
  // 清空当前会话
  void clearCurrentSession() {
    _messages = [];
    notifyListeners();
  }
  
  // 切换到特定日期的历史会话
  void loadHistorySession(String date) {
    final historyGroup = _groupedHistory.firstWhere(
      (group) => group.date == date,
      orElse: () => GroupedChatMessages(date: date, messages: []),
    );
    
    _messages = List.from(historyGroup.messages);
    notifyListeners();
  }
  
  // 清空所有历史记录
  Future<void> clearAllHistory() async {
    if (_authToken == null) return;
    
    try {
      await ChatHistoryService.clearHistory(_authToken!);
      _groupedHistory = [];
      _messages = [];
    } catch (e) {
      _error = 'Failed to clear history: $e';
    }
    
    notifyListeners();
  }
} 