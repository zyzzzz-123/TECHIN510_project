import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/task_agent_service.dart';
import 'package:intl/intl.dart';

class TaskConfirmationCard extends StatelessWidget {
  final TaskIntent intent;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final Task? task; // 对于更新操作，可以传入原始任务进行比较

  const TaskConfirmationCard({
    Key? key,
    required this.intent,
    required this.onConfirm,
    required this.onCancel,
    this.task,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _getActionTitle(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(intent.confirmationMessage),
            const SizedBox(height: 16),
            _buildTaskDetails(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onCancel,
                  child: const Text('取消'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: onConfirm,
                  child: const Text('确认'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getActionTitle() {
    switch (intent.action) {
      case TaskAction.create:
        return '创建任务';
      case TaskAction.update:
        return '更新任务';
      case TaskAction.delete:
        return '删除任务';
      case TaskAction.query:
        return '查询任务';
      default:
        return '任务操作';
    }
  }

  Widget _buildTaskDetails() {
    switch (intent.action) {
      case TaskAction.create:
        return _buildCreateTaskDetails();
      case TaskAction.update:
        return _buildUpdateTaskDetails();
      case TaskAction.delete:
        return _buildDeleteTaskDetails();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCreateTaskDetails() {
    final taskData = intent.data;
    final text = taskData['text'] ?? '新任务';
    final type = taskData['type'] ?? 'todo';
    String dueDateStr = '无截止日期';
    
    if (taskData['due_date'] != null) {
      try {
        final dueDate = DateTime.parse(taskData['due_date']);
        dueDateStr = DateFormat('yyyy-MM-dd').format(dueDate);
      } catch (e) {
        dueDateStr = '日期格式错误';
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        Text('任务内容: $text', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('类型: ${type == 'todo' ? '待办事项' : '长期目标'}'),
        const SizedBox(height: 4),
        Text('截止日期: $dueDateStr'),
        const Divider(),
      ],
    );
  }

  Widget _buildUpdateTaskDetails() {
    final taskData = intent.data;
    final Map<String, dynamic> updates = {};
    
    if (taskData['text'] != null) {
      updates['任务内容'] = taskData['text'];
    }
    
    if (taskData['due_date'] != null) {
      try {
        final dueDate = DateTime.parse(taskData['due_date']);
        updates['截止日期'] = DateFormat('yyyy-MM-dd').format(dueDate);
      } catch (e) {
        updates['截止日期'] = '日期格式错误';
      }
    }
    
    if (taskData['status'] != null) {
      updates['状态'] = taskData['status'] == 'todo' ? '待办' : '已完成';
    }
    
    if (taskData['type'] != null) {
      updates['类型'] = taskData['type'] == 'todo' ? '待办事项' : '长期目标';
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        Text('任务ID: ${taskData['id']}', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        ...updates.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Text('${entry.key}: ${entry.value}'),
          );
        }).toList(),
        const Divider(),
      ],
    );
  }

  Widget _buildDeleteTaskDetails() {
    final taskData = intent.data;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        Text('任务ID: ${taskData['id']}', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('此操作不可撤销!', style: TextStyle(color: Colors.red)),
        const Divider(),
      ],
    );
  }
} 