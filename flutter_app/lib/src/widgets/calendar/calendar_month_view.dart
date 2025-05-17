import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/calendar_event.dart';

class CalendarMonthView extends StatelessWidget {
  final DateTime selectedDate;
  final Map<DateTime, List<CalendarEvent>> eventsByDay;
  final Function(DateTime) onDaySelected;
  
  const CalendarMonthView({
    super.key,
    required this.selectedDate,
    required this.eventsByDay,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Month header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 18),
                tooltip: 'Previous Month',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  final prevMonth = DateTime(selectedDate.year, selectedDate.month - 1, 1);
                  onDaySelected(prevMonth);
                },
              ),
              const SizedBox(width: 4),
              Text(
                DateFormat('MMMM yyyy').format(selectedDate),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 18),
                tooltip: 'Next Month',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  final nextMonth = DateTime(selectedDate.year, selectedDate.month + 1, 1);
                  onDaySelected(nextMonth);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        
        // Calendar
        TableCalendar(
          focusedDay: selectedDate,
          firstDay: DateTime(DateTime.now().year - 1),
          lastDay: DateTime(DateTime.now().year + 1),
          selectedDayPredicate: (day) => isSameDay(day, selectedDate),
          onDaySelected: (selectedDay, focusedDay) {
            onDaySelected(selectedDay);
          },
          headerVisible: false,
          daysOfWeekHeight: 40,
          rowHeight: 60,
          eventLoader: (day) {
            final date = DateTime(day.year, day.month, day.day);
            return eventsByDay[date] ?? [];
          },
          calendarStyle: CalendarStyle(
            markersMaxCount: 3,
            markerDecoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: Colors.red.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, date, events) {
              if (events.isEmpty) return null;
              
              return Positioned(
                bottom: 1,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: events.take(3).map((event) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (event as CalendarEvent).color,
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),
        
        // Events list for selected day
        Expanded(
          child: _buildEventsList(context),
        ),
      ],
    );
  }

  Widget _buildEventsList(BuildContext context) {
    final date = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final events = eventsByDay[date] ?? [];
    
    if (events.isEmpty) {
      return const Center(
        child: Text('No events for this day'),
      );
    }
    
    // Sort events by start time
    events.sort((a, b) => a.startTime.compareTo(b.startTime));
    
    return ListView.builder(
      itemCount: events.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final event = events[index];
        final startTime = DateFormat('h:mm a').format(event.startTime);
        final endTime = DateFormat('h:mm a').format(event.endTime);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            border: Border.all(color: event.color),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            leading: Container(
              width: 16,
              height: double.infinity,
              color: event.color,
            ),
            title: Text(
              event.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('$startTime - $endTime'),
          ),
        );
      },
    );
  }
} 