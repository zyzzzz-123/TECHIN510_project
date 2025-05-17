import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/calendar_event.dart';

class CalendarDayView extends StatefulWidget {
  final DateTime selectedDate;
  final List<CalendarEvent> events;
  final Function(CalendarEvent) onEventTap;
  final void Function(DateTime)? onDateChange;
  
  const CalendarDayView({
    super.key,
    required this.selectedDate,
    required this.events,
    required this.onEventTap,
    this.onDateChange,
  });

  @override
  State<CalendarDayView> createState() => _CalendarDayViewState();
}

class _CalendarDayViewState extends State<CalendarDayView> {
  int slotMinutes = 60; // 默认1小时
  final List<int> allowedSlots = [240, 120, 60, 30, 15]; // 支持4小时、2小时、1小时、30分钟、15分钟
  bool _hasChangedScale = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoScrollToNowOrFirstEvent());
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (_hasChangedScale) return;
    if (details.scale > 1.08) {
      // 放大，颗粒度更细
      final idx = allowedSlots.indexOf(slotMinutes);
      if (idx < allowedSlots.length - 1) {
        setState(() {
          slotMinutes = allowedSlots[idx + 1];
        });
        _hasChangedScale = true;
      }
    } else if (details.scale < 0.92) {
      // 缩小，颗粒度更粗
      final idx = allowedSlots.indexOf(slotMinutes);
      if (idx > 0) {
        setState(() {
          slotMinutes = allowedSlots[idx - 1];
        });
        _hasChangedScale = true;
      }
    }
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    _hasChangedScale = false;
  }

  void _autoScrollToNowOrFirstEvent() {
    final now = DateTime.now();
    final isToday = widget.selectedDate.year == now.year && widget.selectedDate.month == now.month && widget.selectedDate.day == now.day;
    final timeSlots = _generateTimeSlots(slotMinutes);
    final slotHeight = 60.0;
    final stackHeight = (slotHeight * timeSlots.length).clamp(0.0, (MediaQuery.of(context).size.height * 3).toDouble());
    if (isToday) {
      // 计算当前时间在时间轴上的像素位置
      final minutes = now.hour * 60 + now.minute;
      final totalMinutes = 24 * 60;
      final nowOffset = (minutes / totalMinutes) * stackHeight;
      // 让nowOffset出现在可视区域上1/3处
      final viewHeight = MediaQuery.of(context).size.height - 120; // 120近似header+padding
      final targetOffset = (nowOffset - viewHeight * (1/3)).clamp(0.0, _scrollController.position.maxScrollExtent);
      _scrollController.jumpTo(targetOffset);
    } else if (widget.events.isNotEmpty) {
      // 保持原有事件自动滚动
      final sortedEvents = List<CalendarEvent>.from(widget.events)
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
      final firstEvent = sortedEvents.first;
      int firstIndex = 0;
      for (int i = 0; i < timeSlots.length; i++) {
        if (!timeSlots[i].isBefore(firstEvent.startTime.subtract(const Duration(hours: 1)))) {
          firstIndex = i;
          break;
        }
      }
      final offset = (firstIndex * slotHeight).clamp(0.0, _scrollController.position.maxScrollExtent);
      _scrollController.jumpTo(offset);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sortedEvents = List<CalendarEvent>.from(widget.events)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    final eventLayout = _calculateEventColumns(sortedEvents);
    final timeSlots = _generateTimeSlots(slotMinutes);
    final slotHeight = 60.0;
    final maxStackHeight = (MediaQuery.of(context).size.height * 3).toDouble();
    final stackHeight = (slotHeight * timeSlots.length).clamp(0.0, maxStackHeight);
    return Column(
      children: [
        // Date header
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
                tooltip: '前一天',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  if (widget.onDateChange != null) {
                    widget.onDateChange!(widget.selectedDate.subtract(const Duration(days: 1)));
                  }
                },
              ),
              const SizedBox(width: 4),
              Text(
                DateFormat('EEE, MMM d, yyyy').format(widget.selectedDate),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 18),
                tooltip: '后一天',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  if (widget.onDateChange != null) {
                    widget.onDateChange!(widget.selectedDate.add(const Duration(days: 1)));
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Day schedule
        Expanded(
          child: GestureDetector(
            onScaleUpdate: _handleScaleUpdate,
            onScaleEnd: _handleScaleEnd,
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.vertical,
              child: ClipRect(
                child: SizedBox(
                  height: stackHeight,
                  child: Stack(
                    children: [
                      // 时间轴背景
                      Column(
                        children: List.generate(timeSlots.length, (i) => Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 70,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  DateFormat('h:mm a').format(timeSlots[i]),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              width: 1,
                              height: slotHeight,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(width: 8),
                            // 横穿整个内容区的淡灰色横线
                            Expanded(
                              child: Container(
                                height: 1,
                                color: Colors.grey.withOpacity(0.2),
                              ),
                            ),
                          ],
                        )),
                      ),
                      // 红色横条指示当前时间
                      if (widget.selectedDate.year == DateTime.now().year &&
                          widget.selectedDate.month == DateTime.now().month &&
                          widget.selectedDate.day == DateTime.now().day)
                        _buildNowIndicator(stackHeight),
                      // 事件块
                      ...(() {
                        final List<_DDLMarkerInfo> markerInfos = [];
                        final List<Widget> widgets = [];
                        // 先收集所有DDL marker的top
                        for (final entry in sortedEvents.asMap().entries) {
                          final idx = entry.key;
                          final event = entry.value;
                          final dayStart = DateTime(widget.selectedDate.year, widget.selectedDate.month, widget.selectedDate.day, 0, 0);
                          final dayEnd = DateTime(widget.selectedDate.year, widget.selectedDate.month, widget.selectedDate.day, 23, 59, 59);
                          if (event.title.startsWith('[DDL]')) {
                            if (event.endTime.isBefore(dayStart) || event.endTime.isAfter(dayEnd)) continue;
                            final due = event.endTime;
                            final minutes = due.hour * 60 + due.minute;
                            final totalMinutes = 24 * 60;
                            final baseTop = (minutes / totalMinutes) * stackHeight;
                            markerInfos.add(_DDLMarkerInfo(event: event, baseTop: baseTop));
                          }
                        }
                        // 按top排序，错开重叠
                        markerInfos.sort((a, b) => a.baseTop.compareTo(b.baseTop));
                        const double markerHeight = 18.0;
                        const double minGap = 13.0;
                        double lastBottom = -100;
                        List<double> markerTops = [];
                        for (var info in markerInfos) {
                          double top = info.baseTop;
                          if (top < lastBottom + minGap) {
                            top = lastBottom + minGap;
                          }
                          markerTops.add(top);
                          lastBottom = top + minGap;
                        }
                        // 如果最后一个超出stackHeight，整体向上平移
                        double overflow = 0;
                        if (markerTops.isNotEmpty && markerTops.last + markerHeight > stackHeight) {
                          overflow = markerTops.last + markerHeight - stackHeight;
                        }
                        for (int i = 0; i < markerInfos.length; i++) {
                          double top = (markerTops[i] - overflow).clamp(0.0, stackHeight - markerHeight);
                          widgets.add(Positioned(
                            top: top,
                            left: 80.0,
                            right: 8.0,
                            height: markerHeight,
                            child: GestureDetector(
                              onTap: () => widget.onEventTap(markerInfos[i].event),
                              child: _buildDDLMarker(context, markerInfos[i].event),
                            ),
                          ));
                        }
                        // 事件块
                        for (final entry in sortedEvents.asMap().entries) {
                          final idx = entry.key;
                          final event = entry.value;
                          final layout = eventLayout[idx];
                          final dayStart = DateTime(widget.selectedDate.year, widget.selectedDate.month, widget.selectedDate.day, 0, 0);
                          final dayEnd = DateTime(widget.selectedDate.year, widget.selectedDate.month, widget.selectedDate.day, 23, 59, 59);
                          final eventStart = event.startTime.isBefore(dayStart) ? dayStart : event.startTime;
                          final eventEnd = event.endTime.isAfter(dayEnd) ? dayEnd : event.endTime;
                          if (event.title.startsWith('[DDL]')) continue;
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
                          if (endIndex >= timeSlots.length) endIndex = timeSlots.length - 1;
                          if (endIndex < startIndex) continue;
                          final top = startIndex * slotHeight;
                          var height = (endIndex - startIndex + 1) * slotHeight;
                          if (top + height > stackHeight) {
                            height = (stackHeight - top).clamp(0.0, height);
                          }
                          final totalColumns = layout['totalColumns'] as int;
                          final columnIndex = layout['columnIndex'] as int;
                          final leftBase = 80.0;
                          final rightBase = 8.0;
                          final eventAreaWidth = MediaQuery.of(context).size.width - leftBase - rightBase;
                          final columnWidth = eventAreaWidth / totalColumns;
                          final left = leftBase + columnIndex * columnWidth;
                          final right = rightBase + (totalColumns - columnIndex - 1) * columnWidth;
                          widgets.add(Positioned(
                            top: top,
                            left: left,
                            right: right,
                            height: height,
                            child: GestureDetector(
                              onTap: () => widget.onEventTap(event),
                              child: _buildEventCard(context, event),
                            ),
                          ));
                        }
                        return widgets;
                      })(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEventCard(BuildContext context, CalendarEvent event) {
    if (event.title.startsWith('[DDL]')) {
      // DDL样式：横条Chip
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.15),
          border: Border.all(color: Colors.red, width: 1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.flag, color: Colors.red, size: 16),
            const SizedBox(width: 6),
            Text(
              event.title.replaceFirst('[DDL] ', ''),
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }
    // event类型：蓝色区块
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: event.color.withOpacity(0.2),
        border: Border.all(color: event.color, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        event.title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildNowIndicator(double stackHeight) {
    final now = DateTime.now();
    final minutes = now.hour * 60 + now.minute;
    final totalMinutes = 24 * 60;
    final top = (minutes / totalMinutes) * stackHeight;
    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: Row(
        children: [
          const SizedBox(width: 58), // 对齐时间轴
          const Icon(Icons.arrow_right_alt, color: Colors.red, size: 18),
          Container(
            width: 8,
            height: 2,
            color: Colors.red,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 2,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  List<DateTime> _generateTimeSlots([int minutes = 60]) {
    final List<DateTime> slots = [];
    final startOfDay = DateTime(widget.selectedDate.year, widget.selectedDate.month, widget.selectedDate.day);
    // 防止非法颗粒度
    final safeMinutes = (minutes == null || minutes <= 0) ? 60 : minutes;
    for (int min = 0; min < 24 * 60; min += safeMinutes) {
      slots.add(startOfDay.add(Duration(minutes: min)));
    }
    return slots;
  }

  // 事件分栏算法：返回每个事件的 {columnIndex, totalColumns}
  List<Map<String, int>> _calculateEventColumns(List<CalendarEvent> events) {
    final List<Map<String, int>> layout = List.generate(events.length, (_) => {'columnIndex': 0, 'totalColumns': 1});
    if (events.isEmpty) return layout;
    // 记录每个事件的重叠组
    List<List<int>> clusters = [];
    List<int> eventToCluster = List.filled(events.length, -1);
    for (int i = 0; i < events.length; i++) {
      bool found = false;
      for (int j = 0; j < clusters.length; j++) {
        for (int k in clusters[j]) {
          if (_isOverlap(events[i], events[k])) {
            clusters[j].add(i);
            eventToCluster[i] = j;
            found = true;
            break;
          }
        }
        if (found) break;
      }
      if (!found) {
        clusters.add([i]);
        eventToCluster[i] = clusters.length - 1;
      }
    }
    // 对每个 cluster 分配栏位
    for (var group in clusters) {
      // 按开始时间排序
      group.sort((a, b) => events[a].startTime.compareTo(events[b].startTime));
      // 贪心分栏
      List<DateTime> columnEnd = [];
      for (int idx in group) {
        bool placed = false;
        for (int col = 0; col < columnEnd.length; col++) {
          if (!events[idx].startTime.isBefore(columnEnd[col])) {
            layout[idx]['columnIndex'] = col;
            columnEnd[col] = events[idx].endTime;
            placed = true;
            break;
          }
        }
        if (!placed) {
          layout[idx]['columnIndex'] = columnEnd.length;
          columnEnd.add(events[idx].endTime);
        }
      }
      // 该组最大栏数
      for (int idx in group) {
        layout[idx]['totalColumns'] = columnEnd.length;
      }
    }
    return layout;
  }

  bool _isOverlap(CalendarEvent a, CalendarEvent b) {
    return a.startTime.isBefore(b.endTime) && b.startTime.isBefore(a.endTime);
  }

  // 新增DDL marker渲染方法
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
}

class _DDLMarkerInfo {
  final CalendarEvent event;
  final double baseTop;
  _DDLMarkerInfo({required this.event, required this.baseTop});
} 