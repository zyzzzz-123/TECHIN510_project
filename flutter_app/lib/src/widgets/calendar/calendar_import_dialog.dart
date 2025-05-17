import 'package:flutter/material.dart';
import 'package:device_calendar/device_calendar.dart' as device_cal;

class CalendarImportDialog extends StatefulWidget {
  final List<device_cal.Calendar> deviceCalendars;
  final Function(String) onCalendarSelected;
  
  const CalendarImportDialog({
    super.key,
    required this.deviceCalendars,
    required this.onCalendarSelected,
  });

  @override
  State<CalendarImportDialog> createState() => _CalendarImportDialogState();
}

class _CalendarImportDialogState extends State<CalendarImportDialog> {
  String? _selectedCalendarId;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Import Calendar'),
      content: SizedBox(
        width: double.maxFinite,
        child: widget.deviceCalendars.isEmpty
            ? const Center(child: Text('No calendars found'))
            : ListView.builder(
                shrinkWrap: true,
                itemCount: widget.deviceCalendars.length,
                itemBuilder: (context, index) {
                  final calendar = widget.deviceCalendars[index];
                  final isSelected = _selectedCalendarId == calendar.id;
                  
                  return ListTile(
                    title: Text(calendar.name ?? 'Unnamed Calendar'),
                    subtitle: Text(calendar.accountName ?? ''),
                    leading: Icon(
                      Icons.calendar_today,
                      color: _getCalendarColor(calendar),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedCalendarId = calendar.id;
                      });
                    },
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedCalendarId == null
              ? null
              : () {
                  widget.onCalendarSelected(_selectedCalendarId!);
                  Navigator.of(context).pop();
                },
          child: const Text('Import'),
        ),
      ],
    );
  }

  Color _getCalendarColor(device_cal.Calendar calendar) {
    if (calendar.color != null) {
      return Color(calendar.color!);
    }
    return Colors.blue;
  }
} 