import 'package:flutter/material.dart';
import '../../services/chat_service.dart';
import '../../services/task_agent_service.dart';
import '../../models/task.dart';
import '../../widgets/task_confirmation_card.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _sending = false;
  String? _error;
  TaskIntent? _pendingTaskIntent;
  Map<String, dynamic>? _pendingAction;
  String _selectedModel = 'gemini';
  List<Task>? _queriedTasks;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      if (authProvider.isAuthenticated) {
        chatProvider.updateUser(authProvider.userId, authProvider.token);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    _controller.clear();
    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      chatProvider.setSelectedModel('gemini');
      await chatProvider.sendMessage(text);
    } catch (e) {
      setState(() {
        _error = 'AI assistant error: $e';
      });
    } finally {
      setState(() => _sending = false);
    }
  }
  
  // 执行任务查询
  Future<void> _executeQueryTask(int userId, String query) async {
    try {
      final tasks = await TaskAgentService.queryTasks(userId, query);
      setState(() {
        _queriedTasks = tasks;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to query tasks: $e';
      });
    }
  }
  
  // 确认任务操作
  Future<void> _confirmTaskAction() async {
    final intent = _pendingTaskIntent;
    if (intent == null) return;
    
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final userId = taskProvider.userId;
    
    if (userId == null) {
      setState(() {
        _error = '请先登录';
        _pendingTaskIntent = null;
      });
      return;
    }
    
    setState(() {
      _sending = true;
    });
    
    try {
      String resultMessage = '';
      
      switch (intent.action) {
        case TaskAction.create:
          final task = await TaskAgentService.createTask(userId, intent.data);
          resultMessage = '已创建任务: ${task.text}';
          // 刷新任务列表
          await taskProvider.fetchTasks();
          break;
          
        case TaskAction.update:
          await TaskAgentService.updateTask(intent.data);
          resultMessage = '已更新任务ID: ${intent.data['id']}';
          // 刷新任务列表
          await taskProvider.fetchTasks();
          break;
          
        case TaskAction.delete:
          await TaskAgentService.deleteTask(intent.data['id']);
          resultMessage = '已删除任务ID: ${intent.data['id']}';
          // 刷新任务列表
          await taskProvider.fetchTasks();
          break;
          
        default:
          resultMessage = '未知操作';
      }
      
      setState(() {
        _pendingTaskIntent = null;
        _queriedTasks = null;
      });
    } catch (e) {
      setState(() {
        _error = '操作失败: $e';
      });
    } finally {
      setState(() {
        _sending = false;
      });
    }
  }
  
  // 取消任务操作
  void _cancelTaskAction() {
    setState(() {
      _pendingTaskIntent = null;
    });
  }

  // 原有的旧格式任务确认方法 - 为了向后兼容
  Future<void> _onConfirmAction() async {
    final pending = _pendingAction;
    if (pending == null) return;
    final action = pending['action'];
    final task = pending['task'];
    setState(() {
      _sending = true;
    });
    // Only support add_task for now
    if (action == 'add_task' && task != null) {
      // You may want to parse due_date, etc.
      final provider = Provider.of<TaskProvider>(context, listen: false);
      final text = task?['text'] ?? '';
      final dueDateStr = task?['due_date'];
      final dueDate = dueDateStr != null ? DateTime.tryParse(dueDateStr) : null;
      await provider.addTask(text, dueDate: dueDate);
      setState(() {
        _pendingAction = null;
      });
    } else {
      setState(() {
        _pendingAction = null;
      });
    }
    setState(() {
      _sending = false;
    });
  }

  void _onCancelAction() {
    setState(() {
      _pendingAction = null;
    });
    setState(() {
      _sending = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, _) {
        final messages = chatProvider.messages;
        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: messages.length + (_queriedTasks != null ? 1 : 0),
                itemBuilder: (context, idx) {
                  if (_queriedTasks != null && idx == messages.length) {
                    return _buildTaskListCard(_queriedTasks!);
                  }
                  final msg = messages[idx];
                  final isUser = msg.role == 'user';
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isUser ? Colors.blue[100] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(msg.content),
                    ),
                  );
                },
              ),
            ),
            if (_pendingTaskIntent != null)
              TaskConfirmationCard(
                intent: _pendingTaskIntent!,
                onConfirm: _confirmTaskAction,
                onCancel: _cancelTaskAction,
              ),
            if (_pendingAction != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _sending ? null : _onConfirmAction,
                      child: const Text('Confirm'),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton(
                      onPressed: _sending ? null : _onCancelAction,
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ),
            if (_error != null || chatProvider.error != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(_error ?? chatProvider.error!, style: const TextStyle(color: Colors.red)),
              ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(hintText: 'Type a message...'),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: _sending
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send),
                    onPressed: _sending ? null : _sendMessage,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
  
  // 构建任务列表卡片
  Widget _buildTaskListCard(List<Task> tasks) {
    if (tasks.isEmpty) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('没有找到符合条件的任务'),
        ),
      );
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                '查询结果',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),
            ...tasks.map((task) => _buildTaskItem(task)).toList(),
          ],
        ),
      ),
    );
  }
  
  // 构建单个任务项
  Widget _buildTaskItem(Task task) {
    final dueDateText = task.dueDate != null 
        ? '截止: ${task.dueDate!.year}-${task.dueDate!.month}-${task.dueDate!.day}'
        : '无截止日期';
        
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            task.status == 'done' ? Icons.check_circle : Icons.radio_button_unchecked,
            color: task.status == 'done' ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.text,
                  style: TextStyle(
                    decoration: task.status == 'done' ? TextDecoration.lineThrough : null,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  dueDateText,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Text(
            '#${task.id}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
