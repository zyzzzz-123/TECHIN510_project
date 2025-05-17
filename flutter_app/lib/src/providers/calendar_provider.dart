import 'package:flutter/material.dart';
import 'package:device_calendar/device_calendar.dart' as device_cal;
import '../models/calendar_event.dart';
import '../models/task.dart';
import '../services/calendar_service.dart';
import 'task_provider.dart';

enum CalendarViewType { day, week, month }

class CalendarProvider extends ChangeNotifier {
  final int? userId;
  final TaskProvider taskProvider;
  bool _loading = false;
  List<CalendarEvent> _events = [];
  DateTime _selectedDate = DateTime.now();
  CalendarViewType _viewType = CalendarViewType.day;
  Map<DateTime, List<CalendarEvent>> _eventsByDay = {};
  List<device_cal.Calendar> _deviceCalendars = [];
  bool _hasCalendarPermission = false;

  CalendarProvider({required this.userId, required this.taskProvider}) {
    _init();
    taskProvider.addListener(_onTasksChanged);
  }

  @override
  void dispose() {
    taskProvider.removeListener(_onTasksChanged);
    super.dispose();
  }

  // Getters
  bool get loading => _loading;
  List<CalendarEvent> get events => _events;
  DateTime get selectedDate => _selectedDate;
  CalendarViewType get viewType => _viewType;
  Map<DateTime, List<CalendarEvent>> get eventsByDay => _eventsByDay;
  List<device_cal.Calendar> get deviceCalendars => _deviceCalendars;
  bool get hasCalendarPermission => _hasCalendarPermission;

  // Initialize the provider
  Future<void> _init() async {
    _generateEventsFromTasks();
    await checkCalendarPermissions();
  }

  void _onTasksChanged() {
    _generateEventsFromTasks();
  }

  void _generateEventsFromTasks() {
    final allTasks = [...taskProvider.todos, ...taskProvider.completed];
    _events = allTasks
        .where((task) => task.type != 'longterm' && task.type != 'long_term')
        .map((task) => CalendarEvent.fromTask(task))
        .toList();
    _groupEventsByDay();
    notifyListeners();
  }

  // Check calendar permissions
  Future<void> checkCalendarPermissions() async {
    _hasCalendarPermission = await CalendarService.requestCalendarPermissions();
    if (_hasCalendarPermission) {
      await fetchDeviceCalendars();
    }
    notifyListeners();
  }

  // Fetch events from the API
  Future<void> fetchEvents() async {
    _loading = true;
    notifyListeners();
    _generateEventsFromTasks();
    _loading = false;
    notifyListeners();
  }

  // Group events by day for easier rendering
  void _groupEventsByDay() {
    _eventsByDay = {};
    for (var event in _events) {
      DateTime day = DateTime(event.startTime.year, event.startTime.month, event.startTime.day);
      final endDay = DateTime(event.endTime.year, event.endTime.month, event.endTime.day);
      while (!day.isAfter(endDay)) {
        _eventsByDay.putIfAbsent(day, () => []);
        _eventsByDay[day]!.add(event);
        day = day.add(const Duration(days: 1));
      }
    }
  }

  // Change the selected date
  void selectDate(DateTime date) {
    _selectedDate = date;
    fetchEvents();
  }

  // Change the view type (day, week, month)
  void setViewType(CalendarViewType type) {
    _viewType = type;
    fetchEvents();
  }

  // Fetch device calendars
  Future<void> fetchDeviceCalendars() async {
    if (!_hasCalendarPermission) {
      return;
    }

    try {
      _deviceCalendars = await CalendarService.getDeviceCalendars();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching device calendars: $e');
    }
  }

  // Import events from device calendar
  Future<void> importFromDeviceCalendar(String calendarId) async {
    if (!_hasCalendarPermission) {
      return;
    }

    _loading = true;
    notifyListeners();

    try {
      // Calculate date range (let's get events for 3 months)
      final startDate = DateTime.now().subtract(const Duration(days: 30));
      final endDate = DateTime.now().add(const Duration(days: 60));

      final importedEvents = await CalendarService.importFromDeviceCalendar(
        userId ?? 0,
        calendarId,
        startDate,
        endDate,
      );

      // Add imported events to current events
      _events.addAll(importedEvents);
      _groupEventsByDay();
    } catch (e) {
      debugPrint('Error importing from device calendar: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Add event to device calendar
  Future<bool> addToDeviceCalendar(CalendarEvent event) async {
    try {
      return await CalendarService.addToDeviceCalendar(event);
    } catch (e) {
      debugPrint('Error adding to device calendar: $e');
      return false;
    }
  }

  // Get events for a specific day
  List<CalendarEvent> getEventsForDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return _eventsByDay[date] ?? [];
  }
} 