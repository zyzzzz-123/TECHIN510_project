import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/calendar_event.dart';
import '../../providers/calendar_provider.dart';
import '../../providers/task_provider.dart';
import '../../widgets/calendar/calendar_day_view.dart';
import '../../widgets/calendar/calendar_week_view.dart';
import '../../widgets/calendar/calendar_month_view.dart';
import '../../widgets/calendar/calendar_import_dialog.dart';
import '../home/home_screen.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    return ChangeNotifierProvider(
      create: (_) => CalendarProvider(userId: taskProvider.userId, taskProvider: taskProvider),
      child: _CalendarContent(),
    );
  }
}

class _CalendarContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<CalendarProvider>(
      builder: (context, provider, _) {
        if (provider.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        return Column(
          children: [
            // View selector and import button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Row(
                children: [
                  Expanded(
                    child: SegmentedButton<CalendarViewType>(
                      segments: const [
                        ButtonSegment(
                          value: CalendarViewType.day,
                          label: Text('Day'),
                          icon: Icon(Icons.view_day),
                        ),
                        ButtonSegment(
                          value: CalendarViewType.week,
                          label: Text('Week'),
                          icon: Icon(Icons.view_week),
                        ),
                        ButtonSegment(
                          value: CalendarViewType.month,
                          label: Text('Month'),
                          icon: Icon(Icons.calendar_view_month),
                        ),
                      ],
                      selected: {provider.viewType},
                      onSelectionChanged: (Set<CalendarViewType> selected) {
                        provider.setViewType(selected.first);
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            // Calendar view
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                child: _buildCalendarView(context, provider),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCalendarView(BuildContext context, CalendarProvider provider) {
    switch (provider.viewType) {
      case CalendarViewType.day:
        return CalendarDayView(
          selectedDate: provider.selectedDate,
          events: provider.getEventsForDay(provider.selectedDate),
          onEventTap: (event) => _showEventDetails(context, event),
          onDateChange: (date) => provider.selectDate(date),
        );
      case CalendarViewType.week:
        return CalendarWeekView(
          selectedDate: provider.selectedDate,
          eventsByDay: provider.eventsByDay,
          onDaySelected: (date) => provider.selectDate(date),
          onEventTap: (event) => _showEventDetails(context, event),
        );
      case CalendarViewType.month:
        return CalendarMonthView(
          selectedDate: provider.selectedDate,
          eventsByDay: provider.eventsByDay,
          onDaySelected: (date) => provider.selectDate(date),
        );
    }
  }

  void _showImportDialog(BuildContext context, CalendarProvider provider) async {
    if (!provider.hasCalendarPermission) {
      await provider.checkCalendarPermissions();
      
      if (!provider.hasCalendarPermission) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Calendar permission denied')),
          );
        }
        return;
      }
    }
    
    if (provider.deviceCalendars.isEmpty) {
      await provider.fetchDeviceCalendars();
    }
    
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => CalendarImportDialog(
          deviceCalendars: provider.deviceCalendars,
          onCalendarSelected: (calendarId) {
            provider.importFromDeviceCalendar(calendarId);
          },
        ),
      );
    }
  }

  void _showEventDetails(BuildContext context, CalendarEvent event) {
    final calendarProvider = Provider.of<CalendarProvider>(context, listen: false);
    final taskProvider = calendarProvider.taskProvider;
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (event.description.isNotEmpty) ...[
                Text(event.description),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${_formatDateTime(event.startTime)} - ${_formatDateTime(event.endTime)}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('状态: ', style: Theme.of(context).textTheme.bodyMedium),
                  Text(event.status == 'done' ? '已完成' : '未完成',
                    style: TextStyle(
                      color: event.status == 'done' ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (event.source == 'task') ...[
                Builder(
                  builder: (innerContext) {
                    final isDone = event.status == 'done';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton.icon(
                          icon: Icon(isDone ? Icons.undo : Icons.check),
                          label: Text(isDone ? '标记为未完成' : '标记为已完成'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDone ? Colors.orange : Colors.green,
                          ),
                          onPressed: () async {
                            if (isDone) {
                              await taskProvider.markTaskUndone(event.id);
                            } else {
                              await taskProvider.markTaskDone(event.id);
                            }
                            if (innerContext.mounted) Navigator.pop(innerContext);
                          },
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.edit),
                          label: const Text('编辑'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                          ),
                          onPressed: () async {
                            Navigator.pop(innerContext); // 先关闭详情弹窗
                            await showDialog(
                              context: innerContext,
                              builder: (context) {
                                final nameController = TextEditingController(text: event.title.replaceFirst('[DDL] ', ''));
                                String type = event.title.startsWith('[DDL]') ? 'ddl' : 'event';
                                DateTime? dueDate = type == 'ddl' ? event.startTime : null;
                                DateTime? startDate = type == 'event' ? event.startTime : null;
                                DateTime? endDate = type == 'event' ? event.endTime : null;
                                return EditTaskDialog(
                                  nameController: nameController,
                                  pickedDate: dueDate,
                                  type: type,
                                  onSave: (newName, newDate, newType, {DateTime? startDate, DateTime? endDate}) async {
                                    if (newType == 'ddl') {
                                      await taskProvider.updateTask(event.id, text: newName, dueDate: newDate, type: newType);
                                    } else if (newType == 'event') {
                                      await taskProvider.updateTask(event.id, text: newName, startDate: startDate, endDate: endDate, type: newType);
                                    } else {
                                      await taskProvider.updateTask(event.id, text: newName, type: newType);
                                    }
                                  },
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.delete),
                          label: const Text('删除'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: innerContext,
                              builder: (context) => AlertDialog(
                                title: const Text('确认删除'),
                                content: const Text('确定要删除该任务吗？'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
                                  ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('删除')),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await taskProvider.deleteTask(event.id);
                              if (innerContext.mounted) Navigator.pop(innerContext);
                            }
                          },
                        ),
                      ],
                    );
                  },
                ),
              ],
              if (event.source != 'device') ...[
                ElevatedButton(
                  onPressed: () {
                    calendarProvider.addToDeviceCalendar(event);
                    Navigator.pop(context);
                  },
                  child: const Text('Add to Device Calendar'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
