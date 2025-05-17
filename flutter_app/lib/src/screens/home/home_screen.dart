import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/task_provider.dart';
import '../../models/task.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../login/login_screen.dart';
import '../chat/chat_screen.dart';
import '../chat/chat_screen_v2.dart';
import '../user/user_screen.dart';
import '../calendar/calendar_screen.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onLogout;
  final bool useChatV2;
  
  const HomeScreen({
    super.key, 
    this.onLogout,
    this.useChatV2 = true,
  });

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Goal Achiever'),
      ),
      body: _selectedIndex == 0
          ? const _TodoPage()
          : _selectedIndex == 1
              ? const CalendarScreen()
              : _selectedIndex == 2
                  ? widget.useChatV2 ? const ChatScreenV2() : const ChatScreen()
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
            final todos = provider.todos.where((t) => t.type == 'todo' || t.type == 'event').toList();
            final longTerms = provider.todos.where((t) => t.type == 'longterm' || t.type == 'long_term').toList();
            // Upcoming Schedule: all future (not today) events and DDLs
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final upcoming = provider.todos.where((t) {
              if (t.type == 'event' && t.startDate != null) {
                final eventDay = DateTime(t.startDate!.year, t.startDate!.month, t.startDate!.day);
                return eventDay.isAfter(today);
              } else if ((t.type == 'ddl' || t.type == 'todo') && t.dueDate != null) {
                final dueDay = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
                return dueDay.isAfter(today);
              }
              return false;
            }).toList();
            upcoming.sort((a, b) {
              final aTime = a.type == 'event' ? a.startDate! : a.dueDate!;
              final bTime = b.type == 'event' ? b.startDate! : b.dueDate!;
              return aTime.compareTo(bTime);
            });
            // Overdue Tasks: 所有今天之前的未完成任务/事件
            final overdue = provider.todos.where((t) {
              if (t.type == 'event' && t.startDate != null) {
                final eventDay = DateTime(t.startDate!.year, t.startDate!.month, t.startDate!.day);
                return eventDay.isBefore(today);
              } else if ((t.type == 'ddl' || t.type == 'todo') && t.dueDate != null) {
                final dueDay = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
                return dueDay.isBefore(today);
              }
              return false;
            }).toList();
            overdue.sort((a, b) {
              final aTime = a.type == 'event' ? a.startDate! : a.dueDate!;
              final bTime = b.type == 'event' ? b.startDate! : b.dueDate!;
              return aTime.compareTo(bTime);
            });
            // 合并所有任务，筛选今天的任务
            final allTasks = [...provider.todos, ...provider.completed];
            final todays = allTasks.where((t) {
              if (t.type == 'event' && t.startDate != null) {
                final eventDay = DateTime(t.startDate!.year, t.startDate!.month, t.startDate!.day);
                return eventDay == today;
              } else if ((t.type == 'ddl' || t.type == 'todo') && t.dueDate != null) {
                final dueDay = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
                return dueDay == today;
              }
              return false;
            }).toList();
            todays.sort((a, b) {
              final aTime = a.type == 'event' ? a.startDate! : a.dueDate!;
              final bTime = b.type == 'event' ? b.startDate! : b.dueDate!;
              return aTime.compareTo(bTime);
            });
            // 计算当前时间
            final nowTime = DateTime.now();
            // Today's Tasks分组
            final List<Task> todaysUnfinished = [];
            final List<Task> todaysOverdue = [];
            final List<Task> todaysCompleted = [];
            for (final t in todays) {
              final isDone = t.status == 'done';
              DateTime? due;
              if (t.type == 'event') {
                due = t.endDate;
              } else {
                due = t.dueDate;
              }
              if (isDone) {
                todaysCompleted.add(t);
              } else if (due != null && due.isBefore(nowTime)) {
                todaysOverdue.add(t);
              } else {
                todaysUnfinished.add(t);
              }
            }
            todaysUnfinished.sort((a, b) {
              final aTime = a.type == 'event' ? a.startDate! : a.dueDate!;
              final bTime = b.type == 'event' ? b.startDate! : b.dueDate!;
              return aTime.compareTo(bTime);
            });
            todaysOverdue.sort((a, b) {
              final aTime = a.type == 'event' ? a.startDate! : a.dueDate!;
              final bTime = b.type == 'event' ? b.startDate! : b.dueDate!;
              return aTime.compareTo(bTime);
            });
            todaysCompleted.sort((a, b) {
              final aTime = a.type == 'event' ? a.startDate! : a.dueDate!;
              final bTime = b.type == 'event' ? b.startDate! : b.dueDate!;
              return aTime.compareTo(bTime);
            });
            // 过滤全局Completed Tasks，只显示非今天的已完成任务
            final completedNotToday = provider.completed.where((t) {
              DateTime? day;
              if (t.type == 'event' && t.startDate != null) {
                day = DateTime(t.startDate!.year, t.startDate!.month, t.startDate!.day);
              } else if ((t.type == 'ddl' || t.type == 'todo') && t.dueDate != null) {
                day = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
              }
              return day == null || day != today;
            }).toList();
            // 展开/折叠状态
            final Map<String, bool> sectionExpanded = {
              'today': true,
              'upcoming': true,
              'longterm': true,
              'overdue': false,
              'completed': false,
            };
            // 用StatefulBuilder包裹以便局部setState
            return StatefulBuilder(
              builder: (context, setSectionState) {
                Widget buildSection({required String key, required String title, required Color color, required List<Widget> children, Color? backgroundColor}) {
                  return ExpansionTile(
                    initiallyExpanded: sectionExpanded[key]!,
                    title: Container(
                      decoration: backgroundColor != null ? BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(6),
                      ) : null,
                      padding: backgroundColor != null ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2) : null,
                      child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color)),
                    ),
                    onExpansionChanged: (expanded) => setSectionState(() => sectionExpanded[key] = expanded),
                    children: children.isNotEmpty ? children : [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text('No tasks', style: TextStyle(color: Colors.grey[500])),
                      )
                    ],
                  );
                }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
                    // 1. Today's Tasks
                    buildSection(
                      key: 'today',
                      title: "Today's Tasks",
                      color: const Color(0xFFB85C00),
                      backgroundColor: const Color(0xFFFFF3E0),
                      children: [
                        if (todaysUnfinished.isNotEmpty) ...[
                          ...todaysUnfinished.map((task) => buildTaskCard(context, task, const Color(0xFFB85C00), Icons.today)),
                        ],
                        if (todaysOverdue.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: Text('Overdue Today', style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold)),
                          ),
                          ...todaysOverdue.map((task) => buildTaskCard(context, task, Colors.red, Icons.flag)),
                        ],
                        if (todaysCompleted.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: Text('Completed Today', style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold)),
                          ),
                          ...todaysCompleted.map((task) => buildTaskCard(context, task, Colors.grey, Icons.check_circle, completed: true)),
                        ],
                      ],
                    ),
                    const Divider(height: 32),
                    // 2. Upcoming Schedule
                    buildSection(
                      key: 'upcoming',
                      title: 'Upcoming Schedule',
                      color: Colors.blue,
                      children: upcoming.take(5).map((task) => buildTaskCard(context, task, Colors.blue, Icons.schedule)).toList(),
                    ),
                    const Divider(height: 32),
                    // 3. Long-term Projects
                    buildSection(
                      key: 'longterm',
                      title: 'Long-term Projects',
                      color: Colors.purple,
                      children: longTerms.map((task) => buildTaskCard(context, task, Colors.purple, Icons.assignment)).toList(),
                    ),
                    const Divider(height: 32),
                    // 4. Overdue Tasks
                    buildSection(
                      key: 'overdue',
                      title: 'Overdue Tasks',
                      color: Colors.red,
                      children: overdue.map((task) => buildTaskCard(context, task, Colors.red, Icons.flag)).toList(),
                    ),
        const Divider(height: 32),
                    // 5. Completed Tasks
                    buildSection(
                      key: 'completed',
                      title: 'Completed Tasks',
                      color: Colors.grey,
                      children: completedNotToday.map((task) => buildTaskCard(context, task, Colors.grey, Icons.check_circle, completed: true)).toList(),
                    ),
                  ],
                );
              },
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
                  return EditTaskDialog(
                    nameController: nameController,
                    pickedDate: pickedDate,
                    type: type,
                    onSave: (newName, newDate, newType, {DateTime? startDate, DateTime? endDate}) async {
                      final provider = Provider.of<TaskProvider>(context, listen: false);
                      if (newType == 'ddl') {
                        await provider.addTask(newName, type: newType, dueDate: newDate);
                      } else if (newType == 'event') {
                        await provider.addTask(newName, type: newType, startDate: startDate, endDate: endDate);
                      } else {
                        await provider.addTask(newName, type: newType);
                      }
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

  // 渲染任务卡片的通用方法
  Widget buildTaskCard(BuildContext context, Task task, Color color, IconData icon, {bool completed = false}) {
    return Card(
      color: color.withOpacity(0.08),
      child: Slidable(
        key: ValueKey(task.id),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.44,
          children: [
            SlidableAction(
              onPressed: (ctx) async {
                final provider = Provider.of<TaskProvider>(ctx, listen: false);
                if (completed) {
                  await provider.markTaskUndone(task.id);
                } else {
                  await provider.markTaskDone(task.id);
                }
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text(completed ? 'Marked as unfinished' : 'Marked as completed')),
                  );
                }
              },
              backgroundColor: completed ? Colors.orange : Colors.green,
              foregroundColor: Colors.white,
              icon: completed ? Icons.undo : Icons.check,
              label: completed ? 'Incomplete' : 'Complete',
            ),
            SlidableAction(
              onPressed: (ctx) async {
                final provider = Provider.of<TaskProvider>(ctx, listen: false);
                final confirm = await showDialog(
                  context: ctx,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Task'),
                    content: const Text('Are you sure you want to delete this task?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await provider.deleteTask(task.id);
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Task deleted')),
                    );
                  }
                }
              },
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Delete',
            ),
          ],
        ),
        child: ListTile(
          leading: Icon(icon, color: color),
          title: Text(
            task.text,
            style: completed
                ? const TextStyle(color: Colors.grey, decoration: TextDecoration.lineThrough)
                : TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
          subtitle: () {
            if (task.type == 'event' && task.startDate != null && task.endDate != null) {
              return Text('From: ${DateFormat('MM-dd HH:mm').format(task.startDate!)}  To: ${DateFormat('MM-dd HH:mm').format(task.endDate!)}', style: const TextStyle(fontSize: 12));
            } else if ((task.type == 'ddl' || task.type == 'todo') && task.dueDate != null) {
              return Text('Due: ${DateFormat('MM-dd HH:mm').format(task.dueDate!)}', style: const TextStyle(fontSize: 12));
            }
            return null;
          }(),
          onTap: () async {
            final provider = Provider.of<TaskProvider>(context, listen: false);
            final nameController = TextEditingController(text: task.text);
            DateTime? pickedDate = task.dueDate;
            String type = task.type;
            await showDialog(
              context: context,
              builder: (context) {
                return EditTaskDialog(
                  nameController: nameController,
                  pickedDate: pickedDate,
                  type: type,
                  onSave: (newName, newDate, newType, {DateTime? startDate, DateTime? endDate}) async {
                    if (task.id != null) {
                      // 编辑，始终用updateTask
                      await provider.updateTask(
                        task.id,
                        text: newName,
                        dueDate: newDate,
                        startDate: startDate,
                        endDate: endDate,
                        type: newType,
                      );
                    } else {
                      // 新建
                      if (newType == 'ddl') {
                        await provider.addTask(newName, type: newType, dueDate: newDate);
                      } else if (newType == 'event') {
                        await provider.addTask(newName, type: newType, startDate: startDate, endDate: endDate);
                      } else {
                        await provider.addTask(newName, type: newType);
                      }
                    }
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class EditTaskDialog extends StatefulWidget {
  final TextEditingController nameController;
  final DateTime? pickedDate;
  final String type;
  final Future<void> Function(String, DateTime?, String, {DateTime? startDate, DateTime? endDate}) onSave;
  const EditTaskDialog({required this.nameController, this.pickedDate, required this.type, required this.onSave});
  @override
  State<EditTaskDialog> createState() => EditTaskDialogState();
}

class EditTaskDialogState extends State<EditTaskDialog> {
  late DateTime? _pickedDate;
  late DateTime? _startDate;
  late DateTime? _endDate;
  late String _type;
  late TimeOfDay? _pickedTime;

  @override
  void initState() {
    super.initState();
    _pickedDate = widget.pickedDate;
    // 类型兼容映射
    if (widget.type == 'todo') {
      _type = 'ddl';
    } else if (widget.type == 'long_term') {
      _type = 'longterm';
    } else {
      _type = widget.type;
    }
    _startDate = null;
    _endDate = null;
    // 新增：初始化DDL时间
    if (_type == 'ddl' && _pickedDate != null) {
      _pickedTime = TimeOfDay(hour: _pickedDate!.hour, minute: _pickedDate!.minute);
    } else {
      _pickedTime = null;
    }
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
              const Text('Type: '),
              DropdownButton<String>(
                value: _type,
                items: const [
                  DropdownMenuItem(value: 'ddl', child: Text('DDL')),
                  DropdownMenuItem(value: 'event', child: Text('Event')),
                  DropdownMenuItem(value: 'longterm', child: Text('Long-term')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _type = v);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_type == 'ddl')
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                const Text('Due Date: '),
                Text(_pickedDate != null ? DateFormat('yyyy-MM-dd').format(_pickedDate!) : 'None'),
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
                Text(_pickedTime != null ? _pickedTime!.format(context) : '23:59'),
                IconButton(
                  icon: const Icon(Icons.access_time),
                  onPressed: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _pickedTime ?? const TimeOfDay(hour: 23, minute: 59),
                    );
                    if (time != null) {
                      setState(() {
                        _pickedTime = time;
                      });
                    }
                  },
                ),
              ],
            ),
          if (_type == 'event') ...[
            Row(
              children: [
                const Text('Start: '),
                Text(_startDate != null ? DateFormat('yyyy-MM-dd HH:mm').format(_startDate!) : 'None'),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _startDate ?? DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _startDate != null
                            ? TimeOfDay(hour: _startDate!.hour, minute: _startDate!.minute)
                            : TimeOfDay.now(),
                      );
                      if (time != null) {
                        setState(() {
                          _startDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                        });
                      } else {
                        setState(() {
                          _startDate = DateTime(date.year, date.month, date.day);
                        });
                      }
                    }
                  },
                ),
              ],
            ),
            Row(
              children: [
                const Text('End: '),
                Text(_endDate != null ? DateFormat('yyyy-MM-dd HH:mm').format(_endDate!) : 'None'),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _endDate ?? (_startDate ?? DateTime.now()),
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _endDate != null
                            ? TimeOfDay(hour: _endDate!.hour, minute: _endDate!.minute)
                            : TimeOfDay.now(),
                      );
                      if (time != null) {
                        setState(() {
                          _endDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                        });
                      } else {
                        setState(() {
                          _endDate = DateTime(date.year, date.month, date.day);
                        });
                      }
                    }
                  },
                ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_type == 'event' && (_startDate == null || _endDate == null)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please select both start and end time for the event.')),
              );
              return;
            }
            // 修复DDL dueDate合并时间
            DateTime? finalDueDate = _pickedDate;
            if (_type == 'ddl' && _pickedDate != null) {
              final time = _pickedTime ?? const TimeOfDay(hour: 23, minute: 59);
              finalDueDate = DateTime(_pickedDate!.year, _pickedDate!.month, _pickedDate!.day, time.hour, time.minute);
            }
            await widget.onSave(
              widget.nameController.text,
              finalDueDate,
              _type,
              startDate: _startDate,
              endDate: _endDate,
            );
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
