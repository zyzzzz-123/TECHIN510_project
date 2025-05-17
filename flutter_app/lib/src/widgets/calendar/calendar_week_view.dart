import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/calendar_event.dart';

class CalendarWeekView extends StatelessWidget {
  final DateTime selectedDate;
  final Map<DateTime, List<CalendarEvent>> eventsByDay;
  final Function(DateTime) onDaySelected;
  final Function(CalendarEvent) onEventTap;
  
  const CalendarWeekView({
    super.key,
    required this.selectedDate,
    required this.eventsByDay,
    required this.onDaySelected,
    required this.onEventTap,
  });

  @override
  Widget build(BuildContext context) {
    // Get the week days
    final weekDays = _generateWeekDays();
    
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Week header
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
                  tooltip: 'Previous Week',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    final prevWeek = weekDays.first.subtract(const Duration(days: 7));
                    onDaySelected(prevWeek);
                  },
                ),
                const SizedBox(width: 4),
                Text(
                  _getWeekRangeText(weekDays.first, weekDays.last),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 18),
                  tooltip: 'Next Week',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    final nextWeek = weekDays.first.add(const Duration(days: 7));
                    onDaySelected(nextWeek);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Day headers
          Row(
            children: weekDays.map((day) {
              final isSelected = _isSameDay(day, selectedDate);
              final isToday = _isSameDay(day, DateTime.now());
              
              return Expanded(
                child: GestureDetector(
                  onTap: () => onDaySelected(day),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Theme.of(context).colorScheme.primary : null,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          DateFormat('E').format(day),
                          style: TextStyle(
                            color: isSelected ? Colors.white : null,
                            fontWeight: isToday ? FontWeight.bold : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isToday ? Colors.red : null,
                          ),
                          child: Center(
                            child: Text(
                              day.day.toString(),
                              style: TextStyle(
                                color: isToday ? Colors.white : isSelected ? Colors.white : null,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          
          // Time slots and events
          SizedBox(
            height: 600, // or MediaQuery.of(context).size.height * 0.6
            child: _buildTimeSlots(context, weekDays),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlots(BuildContext context, List<DateTime> weekDays) {
    final timeSlots = _generateTimeSlots();
    final slotHeight = 40.0; // Height for each time slot row
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SizedBox(
        height: slotHeight * timeSlots.length,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time labels column
            Column(
              children: timeSlots.map((timeSlot) => SizedBox(
                height: slotHeight,
                width: 50,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    DateFormat('h:mm a').format(timeSlot),
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                  ),
                ),
              )).toList(),
            ),
            // Day columns
            ...weekDays.map((day) {
              final date = DateTime(day.year, day.month, day.day);
              final events = eventsByDay[date] ?? [];
              return Expanded(
                child: SizedBox(
                  height: slotHeight * timeSlots.length,
                  child: Stack(
                    children: [
                      // Time slot backgrounds
                      Column(
                        children: List.generate(timeSlots.length, (i) => Container(
                          height: slotHeight,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                        )),
                      ),
                      // Event blocks
                      ...events.map((event) {
                        // 只渲染事件在当天的部分
                        final dayStart = DateTime(day.year, day.month, day.day, 0, 0);
                        final dayEnd = DateTime(day.year, day.month, day.day, 23, 59, 59);
                        final eventStart = event.startTime.isBefore(dayStart) ? dayStart : event.startTime;
                        final eventEnd = event.endTime.isAfter(dayEnd) ? dayEnd : event.endTime;
                        // DDL渲染逻辑
                        if (event.title.startsWith('[DDL]')) {
                          // 只在due time对应slot渲染marker
                          if (event.endTime.isBefore(dayStart) || event.endTime.isAfter(dayEnd)) return const SizedBox.shrink();
                          // 找到due time对应的slot index
                          int markerIndex = 0;
                          for (int i = 0; i < timeSlots.length; i++) {
                            final slot = timeSlots[i];
                            if (!slot.isBefore(event.endTime)) {
                              markerIndex = i;
                              break;
                            }
                          }
                          final top = markerIndex * slotHeight;
                          return Positioned(
                            top: top,
                            left: 2,
                            right: 2,
                            height: 16,
                            child: GestureDetector(
                              onTap: () => onEventTap(event),
                              child: _buildDDLMarker(context, event),
                            ),
                          );
                        }
                        // event渲染逻辑
                        // 修正 index 计算逻辑，确保事件完整覆盖
                        int startIndex = 0;
                        int endIndex = timeSlots.length - 1;
                        for (int i = 0; i < timeSlots.length; i++) {
                          if (!timeSlots[i].isBefore(eventStart)) {
                            startIndex = i;
                            break;
                          }
                        }
                        for (int i = timeSlots.length - 1; i >= 0; i--) {
                          if (timeSlots[i].isBefore(eventEnd)) {
                            endIndex = i;
                            break;
                          }
                        }
                        if (endIndex < startIndex) return const SizedBox.shrink();
                        final top = startIndex * slotHeight;
                        final height = (endIndex - startIndex + 1) * slotHeight;
                        return Positioned(
                          top: top,
                          left: 2,
                          right: 2,
                          height: height,
                          child: GestureDetector(
                            onTap: () => onEventTap(event),
                            child: _buildEventCard(context, event),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, CalendarEvent event) {
    // final startTime = DateFormat('h:mm a').format(event.startTime);
    if (event.title.startsWith('[DDL]')) {
      // DDL样式：横条Chip
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.15),
          border: Border.all(color: Colors.red, width: 1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: SizedBox(
          width: double.infinity,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: const Icon(Icons.flag, color: Colors.red, size: 12)),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  event.title.replaceFirst('[DDL] ', ''),
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }
    // event类型：蓝色区块
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: event.color.withOpacity(0.2),
        border: Border.all(color: event.color, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                event.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDDLMarker(BuildContext context, CalendarEvent event) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(Icons.flag, color: Colors.red, size: 14),
        const SizedBox(width: 4),
        Text(
          event.title.replaceFirst('[DDL] ', ''),
          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(width: 6),
        Text(
          DateFormat('HH:mm').format(event.endTime),
          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500, fontSize: 11),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(left: 4),
            height: 2,
            color: Colors.red,
          ),
        ),
      ],
    );
  }

  List<DateTime> _generateWeekDays() {
    final List<DateTime> days = [];
    // Find first day of the week (Sunday)
    final firstDayOfWeek = selectedDate.subtract(Duration(days: selectedDate.weekday % 7));
    
    for (int i = 0; i < 7; i++) {
      days.add(firstDayOfWeek.add(Duration(days: i)));
    }
    
    return days;
  }

  List<DateTime> _generateTimeSlots() {
    final List<DateTime> slots = [];
    final referenceDate = DateTime(2022, 1, 1);
    for (int hour = 0; hour < 24; hour++) {
      slots.add(DateTime(referenceDate.year, referenceDate.month, referenceDate.day, hour, 0));
      slots.add(DateTime(referenceDate.year, referenceDate.month, referenceDate.day, hour, 30));
    }
    return slots;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _getWeekRangeText(DateTime start, DateTime end) {
    final startFormat = DateFormat.MMMd().format(start);
    final endFormat = DateFormat.MMMd().format(end);
    return '$startFormat - $endFormat, ${start.year}';
  }
} 