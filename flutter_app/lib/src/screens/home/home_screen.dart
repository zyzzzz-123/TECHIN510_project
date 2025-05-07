import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/task_provider.dart';
import '../../models/task.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../login/login_screen.dart';
import '../chat/chat_screen.dart';
import '../user/user_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onLogout;
  const HomeScreen({super.key, this.onLogout});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int? _userId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('user_id');
    if (id == null) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } else {
      setState(() {
        _userId = id;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_userId == null) {
      return const SizedBox.shrink();
    }
    return ChangeNotifierProvider(
      create: (_) => TaskProvider(userId: _userId!)..fetchTasks(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Goal Achiever'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: widget.onLogout,
            ),
          ],
        ),
        body: _selectedIndex == 0
            ? const _TodoPage()
            : _selectedIndex == 1
                ? Center(child: Text('Calendar'))
                : _selectedIndex == 2
                    ? const ChatScreen()
                    : const UserScreen(),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Calendar'),
            BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'User'),
          ],
        ),
      ),
    );
  }
}

class _TodoPage extends StatelessWidget {
  const _TodoPage();
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Consumer<TaskProvider>(
          builder: (context, provider, _) {
            if (provider.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            // 分类
            final todos = provider.todos.where((t) => t.type == 'todo').toList();
            final longTerms = provider.todos.where((t) => t.type == 'long_term').toList();
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text("Today's Tasks", style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                ...todos.map((task) {
                  final dueDateStr = task.dueDate != null ? task.dueDate!.toLocal().toString().split(' ')[0] : null;
                  return ListTile(
                    leading: Checkbox(
                      value: false,
                      onChanged: (_) => provider.markTaskDone(task.id),
                    ),
                    title: Text(task.text),
                    subtitle: dueDateStr != null ? Text('Due: $dueDateStr', style: const TextStyle(fontSize: 12)) : null,
                    onTap: () async {
                      final nameController = TextEditingController(text: task.text);
                      DateTime? pickedDate = task.dueDate;
                      String type = task.type;
                      await showDialog(
                        context: context,
                        builder: (context) {
                          return _EditTaskDialog(
                            nameController: nameController,
                            pickedDate: pickedDate,
                            type: type,
                            onSave: (newName, newDate, newType) async {
                              await provider.updateTask(task.id, text: newName, dueDate: newDate, type: newType);
                            },
                          );
                        },
                      );
                    },
                  );
                }),
                const Divider(height: 32),
                Text("Long-term Projects", style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                ...longTerms.map((task) {
                  final dueDateStr = task.dueDate != null ? task.dueDate!.toLocal().toString().split(' ')[0] : null;
                  return ListTile(
                    leading: Checkbox(
                      value: false,
                      onChanged: (_) => provider.markTaskDone(task.id),
                    ),
                    title: Text(task.text),
                    subtitle: dueDateStr != null ? Text('Due: $dueDateStr', style: const TextStyle(fontSize: 12)) : null,
                    onTap: () async {
                      final nameController = TextEditingController(text: task.text);
                      DateTime? pickedDate = task.dueDate;
                      String type = task.type;
                      await showDialog(
                        context: context,
                        builder: (context) {
                          return _EditTaskDialog(
                            nameController: nameController,
                            pickedDate: pickedDate,
                            type: type,
                            onSave: (newName, newDate, newType) async {
                              await provider.updateTask(task.id, text: newName, dueDate: newDate, type: newType);
                            },
                          );
                        },
                      );
                    },
                  );
                }),
                const Divider(height: 32),
                Text("Completed Tasks", style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                ...provider.completed.map((task) {
                  final dueDateStr = task.dueDate != null ? task.dueDate!.toLocal().toString().split(' ')[0] : null;
                  return ListTile(
                    leading: Checkbox(
                      value: true,
                      onChanged: (_) => provider.markTaskUndone(task.id),
                      activeColor: Colors.green,
                    ),
                    title: Text(
                      task.text,
                      style: const TextStyle(color: Colors.grey, decoration: TextDecoration.lineThrough),
                    ),
                    subtitle: dueDateStr != null ? Text('Due: $dueDateStr', style: const TextStyle(fontSize: 12)) : null,
                    onTap: () async {
                      final nameController = TextEditingController(text: task.text);
                      DateTime? pickedDate = task.dueDate;
                      String type = task.type;
                      await showDialog(
                        context: context,
                        builder: (context) {
                          return _EditTaskDialog(
                            nameController: nameController,
                            pickedDate: pickedDate,
                            type: type,
                            onSave: (newName, newDate, newType) async {
                              await provider.updateTask(task.id, text: newName, dueDate: newDate, type: newType);
                            },
                          );
                        },
                      );
                    },
                  );
                }),
              ],
            );
          },
        ),
        Positioned(
          bottom: 24,
          right: 24,
          child: FloatingActionButton(
            onPressed: () async {
              final nameController = TextEditingController();
              DateTime? pickedDate;
              String type = 'todo';
              final provider = Provider.of<TaskProvider>(context, listen: false);
              await showDialog(
                context: context,
                builder: (context) {
                  return _EditTaskDialog(
                    nameController: nameController,
                    pickedDate: pickedDate,
                    type: type,
                    onSave: (newName, newDate, newType) async {
                      await provider.addTask(newName, type: newType, dueDate: newDate);
                    },
                  );
                },
              );
            },
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

class _EditTaskDialog extends StatefulWidget {
  final TextEditingController nameController;
  final DateTime? pickedDate;
  final String type;
  final Future<void> Function(String, DateTime?, String) onSave;
  const _EditTaskDialog({required this.nameController, this.pickedDate, required this.type, required this.onSave});
  @override
  State<_EditTaskDialog> createState() => _EditTaskDialogState();
}

class _EditTaskDialogState extends State<_EditTaskDialog> {
  late DateTime? _pickedDate;
  late String _type;
  @override
  void initState() {
    super.initState();
    _pickedDate = widget.pickedDate;
    _type = widget.type;
  }
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Task'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: widget.nameController,
            decoration: const InputDecoration(labelText: 'Task Name'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Due Date: '),
              Text(_pickedDate?.toLocal().toString().split(' ')[0] ?? 'None'),
              IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _pickedDate ?? DateTime.now(),
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                  );
                  if (date != null) {
                    setState(() {
                      _pickedDate = date;
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Type: '),
              DropdownButton<String>(
                value: _type,
                items: const [
                  DropdownMenuItem(value: 'todo', child: Text('Todo')),
                  DropdownMenuItem(value: 'long_term', child: Text('Long-term')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _type = v);
                },
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            await widget.onSave(widget.nameController.text, _pickedDate, _type);
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
