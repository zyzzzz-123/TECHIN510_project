import 'dart:convert';
import 'package:flutter_app/src/models/calendar_event.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/task.dart';
import 'package:device_calendar/device_calendar.dart' as device_cal;
import 'package:add_2_calendar/add_2_calendar.dart';

class CalendarService {
  static final device_cal.DeviceCalendarPlugin _deviceCalendarPlugin = device_cal.DeviceCalendarPlugin();
  
  // Fetch events from backend API
  static Future<List<CalendarEvent>> fetchEvents(int? userId, {DateTime? start, DateTime? end}) async {
    if (userId == null) {
      return [];
    }
    
    // In the future, this would be connected to a proper backend API
    // For now, we'll create some sample events and convert tasks with due dates
    List<CalendarEvent> events = [];
    
    // Get tasks with due dates and convert them to events
    final url = Uri.parse('$baseUrl/api/tasks/user/$userId');
    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      final tasks = data.map((e) => Task.fromJson(e)).toList();
      
      // Convert tasks with due dates to events
      for (var task in tasks) {
        if (task.dueDate != null) {
          events.add(CalendarEvent.fromTask(task));
        }
      }
    }
    
    return events;
  }
  
  // Request permission to access device calendars
  static Future<bool> requestCalendarPermissions() async {
    var permissionsGranted = await _deviceCalendarPlugin.hasPermissions();
    if (permissionsGranted.isSuccess && !permissionsGranted.data!) {
      permissionsGranted = await _deviceCalendarPlugin.requestPermissions();
      return permissionsGranted.isSuccess && permissionsGranted.data!;
    }
    return permissionsGranted.isSuccess && permissionsGranted.data!;
  }
  
  // Get list of device calendars
  static Future<List<device_cal.Calendar>> getDeviceCalendars() async {
    final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
    return calendarsResult.data ?? [];
  }
  
  // Import events from device calendar
  static Future<List<CalendarEvent>> importFromDeviceCalendar(
      int? userId, String calendarId, DateTime start, DateTime end) async {
    final eventsResult = await _deviceCalendarPlugin.retrieveEvents(
      calendarId,
      device_cal.RetrieveEventsParams(startDate: start, endDate: end),
    );
    
    if (eventsResult.isSuccess && eventsResult.data != null) {
      int idCounter = 1000; // Placeholder IDs for imported events
      
      return eventsResult.data!.map((event) {
        return CalendarEvent(
          id: idCounter++,
          userId: userId ?? 0,
          title: event.title ?? 'Untitled Event',
          description: event.description ?? '',
          startTime: event.start ?? DateTime.now(),
          endTime: event.end ?? DateTime.now().add(const Duration(hours: 1)),
          isAllDay: event.allDay ?? false,
          source: 'device',
          externalId: event.eventId,
          status: 'todo',
        );
      }).toList();
    }
    
    return [];
  }
  
  // Add event to device calendar
  static Future<bool> addToDeviceCalendar(CalendarEvent event) async {
    final deviceEvent = Event(
      title: event.title,
      description: event.description,
      startDate: event.startTime,
      endDate: event.endTime,
      allDay: event.isAllDay,
    );
    
    return Add2Calendar.addEvent2Cal(deviceEvent);
  }
} 