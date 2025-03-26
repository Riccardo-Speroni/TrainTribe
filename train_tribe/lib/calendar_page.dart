import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CalendarEvent {
  DateTime date;
  int hour; // Start hour
  int duration;
  String title;

  CalendarEvent({
    required this.date,
    required this.hour,
    required this.duration,
    required this.title,
  });
}

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final double cellHeight = 60.0; //Slot Height
  late final List<int> hours =
      List.generate(19, (index) => index + 6); // Hours from 6.00 to 24.00
  late final List<DateTime> weekDays =
      _getCurrentWeekDays(); // Current week days (from Monday to Sunday)

  final List<CalendarEvent> events = []; // List of created events

  // Variables for selection via long press
  DateTime? _draggingDay;
  int? _dragStartIndex;
  int? _dragCurrentIndex;

  // Computation of the current week days based on today.
  List<DateTime> _getCurrentWeekDays() {
    DateTime now = DateTime.now();
    int weekday = now.weekday; // 1 = Monday, 7 = Sunday
    DateTime monday = now.subtract(Duration(days: weekday - 1));
    return List.generate(7, (index) => monday.add(Duration(days: index)));
  }

  // Returns the event that starts in the slot for the specified day and time, if it exists.
  CalendarEvent? _getEventForCell(DateTime day, int hour) {
    for (var event in events) {
      if (_isSameDay(event.date, day) && event.hour == hour) {
        return event;
      }
    }
    return null;
  }

  // Check if two DateTime represent the same day.
  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  // Show the dialog to add a new event.
  // If [endIndex] is provided, it is used to calculate the duration.
  void _showAddEventDialog(DateTime day, int startIndex, [int? endIndex]) {
    String eventTitle = '';
    // Start index must be in range [0, hours.length - 1]
    int safeStart = startIndex.clamp(0, hours.length - 1);
    // Compute the duration based on the indices: if endIndex is null, the duration is 1.
    int duration = (endIndex != null
        ? (max(startIndex, endIndex) - min(startIndex, endIndex) + 1).toInt()
        : 1);
    int selectedDuration = duration;
    // Get the start hour from the list, using the safe index.
    int startHour = hours[safeStart];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(
              'New Event: ${DateFormat('EEE, MMM d').format(day)} at $startHour:00',
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(hintText: 'Event Title'),
                  onChanged: (value) {
                    eventTitle = value;
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text('Duration: '),
                    DropdownButton<int>(
                      value: selectedDuration,
                      items: [1, 2, 3, 4, 5, 6]
                          .map((d) => DropdownMenuItem(
                                value: d,
                                child: Text('$d h'),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setStateDialog(() {
                            selectedDuration = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (eventTitle.isNotEmpty) {
                    setState(() {
                      events.add(CalendarEvent(
                        date: day,
                        hour: startHour,
                        duration: selectedDuration,
                        title: eventTitle,
                      ));
                    });
                  }
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          );
        });
      },
    );
  }

  // Show the dialog to edit an existing event.
  void _showEditEventDialog(CalendarEvent event) {
    String eventTitle = event.title;
    int duration = event.duration;
    TextEditingController controller = TextEditingController(text: event.title);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Edit Event: ${DateFormat('EEE, MMM d').format(event.date)} at ${event.hour}:00',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(hintText: 'Event Title'),
                onChanged: (value) {
                  eventTitle = value;
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text('Duration: '),
                  DropdownButton<int>(
                    value: duration,
                    items: [1, 2, 3, 4, 5, 6]
                        .map((d) => DropdownMenuItem(
                              value: d,
                              child: Text('$d h'),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          duration = value;
                        });
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  event.title = eventTitle;
                  event.duration = duration;
                });
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // This method builds the time column (on the left)
  Widget _buildTimeColumn() {
    return Container(
      width: 60,
      child: Column(
        children: hours.map((hour) {
          String label = hour == 24 ? "00:00" : "$hour:00";
          return Container(
            height: cellHeight,
            alignment: Alignment.center,
            decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
            child: Text(
              label,
              style: const TextStyle(fontSize: 12),
            ),
          );
        }).toList(),
      ),
    );
  }

  // This method builds the column for a specific day.
  Widget _buildDayColumn(DateTime day) {
  List<Widget> cells = [];
  int index = 0;
  while (index < hours.length) {
    int currentHour = hours[index];
    CalendarEvent? event = _getEventForCell(day, currentHour);
    if (event != null) {
      cells.add(
        GestureDetector(
          onTap: () {
            _showEditEventDialog(event);
          },
          child: Container(
            height: cellHeight * event.duration,
            margin: const EdgeInsets.only(bottom: 1),
            decoration: BoxDecoration(
              color: Colors.lightBlueAccent,
              border: Border.all(color: Colors.grey),
            ),
            alignment: Alignment.center,
            child: Text(
              event.title,
              style: const TextStyle(fontSize: 12, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
      index += event.duration;
    } else {
      // Capture the current index in a local variable to avoid closure capture issues.
      final int cellIndex = index;
      cells.add(
        GestureDetector(
          onTap: () => _showAddEventDialog(day, cellIndex),
          child: Container(
            height: cellHeight,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
            ),
          ),
        ),
      );
      index++;
    }
  }

  // Overlay to highlight selection in case of long press drag.
  Widget overlay = Container();
  if (_draggingDay != null &&
      _isSameDay(_draggingDay!, day) &&
      _dragStartIndex != null &&
      _dragCurrentIndex != null) {
    int start = min(_dragStartIndex!, _dragCurrentIndex!);
    int end = max(_dragStartIndex!, _dragCurrentIndex!);
    overlay = Positioned(
      top: start * cellHeight,
      left: 0,
      right: 0,
      height: (end - start + 1) * cellHeight,
      child: Container(
        color: Colors.blue.withOpacity(0.3),
      ),
    );
  }

  // Wrap the entire column in a GestureDetector to handle long press selection.
  return Expanded(
    child: GestureDetector(
      // Use deferToChild so that child gesture detectors (onTap on cells) have priority.
      behavior: HitTestBehavior.deferToChild,
      onLongPressStart: (details) {
        RenderBox box = context.findRenderObject() as RenderBox;
        double localY = details.localPosition.dy;
        int cellIndex = localY ~/ cellHeight;
        setState(() {
          _draggingDay = day;
          _dragStartIndex = cellIndex.clamp(0, hours.length - 1);
          _dragCurrentIndex = cellIndex.clamp(0, hours.length - 1);
        });
      },
      onLongPressMoveUpdate: (details) {
        RenderBox box = context.findRenderObject() as RenderBox;
        double localY = details.localPosition.dy;
        int cellIndex = localY ~/ cellHeight;
        setState(() {
          _dragCurrentIndex = cellIndex.clamp(0, hours.length - 1);
        });
      },
      onLongPressEnd: (details) {
        if (_draggingDay != null &&
            _dragStartIndex != null &&
            _dragCurrentIndex != null) {
          int start = min(_dragStartIndex!, _dragCurrentIndex!);
          int end = max(_dragStartIndex!, _dragCurrentIndex!);
          if (end - start >= 0) {
            _showAddEventDialog(day, start, end);
          }
        }
        setState(() {
          _draggingDay = null;
          _dragStartIndex = null;
          _dragCurrentIndex = null;
        });
      },
      child: Stack(
        children: [
          Column(
            children: cells,
          ),
          overlay,
        ],
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: Column(
        children: [
          // Header: empty time column + day headers
          Row(
            children: [
              Container(width: 60, height: 40),
              ...weekDays.map((day) {
                return Expanded(
                  child: Container(
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      color: Colors.blue[200],
                    ),
                    child: Text(
                      DateFormat('EEE\nd MMM').format(day),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
          // Body: time column + days grid in vertical scroll
          Expanded(
            child: SingleChildScrollView(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTimeColumn(),
                  ...weekDays.map((day) => _buildDayColumn(day)).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
