import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'l10n/app_localizations.dart';

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
  final double cellHeight = 60.0; // Slot Height
  late final List<int> hours = List.generate(19, (index) => index + 6); // Hours from 6.00 to 24.00
  final List<CalendarEvent> events = []; // List of created events

  int? _dragStartIndex; // Index of the cell where the drag started
  int? _dragEndIndex; // Index of the cell where the drag ended
  DateTime? _dragStartDay; // Day of the cell where the drag started

  // Compute the week days starting from a given day
  List<DateTime> _getDays(DateTime startDay, int count) {
    return List.generate(count, (index) => startDay.add(Duration(days: index)));
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

  // Calculate available durations for a new or modified event
  List<int> _getAvailableDurations(DateTime day, int startHour, [CalendarEvent? excludeEvent]) {
    List<int> availableDurations = [];
    for (int duration = 1; duration <= 6; duration++) {
      bool overlaps = events.any((event) {
        if (event == excludeEvent) return false; // Exclude the event being edited
        if (_isSameDay(event.date, day)) {
          int eventStart = event.hour;
          int eventEnd = event.hour + event.duration;
          int newEventStart = startHour;
          int newEventEnd = startHour + duration;
          return (newEventStart < eventEnd && newEventEnd > eventStart);
        }
        return false;
      });
      if (!overlaps) {
        availableDurations.add(duration);
      }
    }
    return availableDurations;
  }

  // Show the dialog to add a new event
  void _showAddEventDialog(DateTime day, int startIndex, [int? endIndex]) {
    final localizations = AppLocalizations.of(context);
    String eventTitle = '';
    bool isSaving = false; // Loading indicator
    int safeStart = startIndex.clamp(0, hours.length - 1);
    int startHour = hours[safeStart];
    int duration = endIndex != null ? (endIndex - startIndex + 1).abs() : 1;
    List<int> availableDurations = _getAvailableDurations(day, startHour);
    int selectedDuration = availableDurations.contains(duration) ? duration : (availableDurations.isNotEmpty ? availableDurations.first : 1);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(
              '${localizations.translate('new_event')}: ${DateFormat('EEE, MMM d', localizations.languageCode()).format(day)} ${localizations.translate('at')} $startHour:00',
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: InputDecoration(hintText: localizations.translate('event_title')),
                  onChanged: (value) {
                    eventTitle = value;
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text('${localizations.translate('duration')}: '),
                    DropdownButton<int>(
                      value: selectedDuration,
                      items: availableDurations
                          .map((d) => DropdownMenuItem(
                                value: d,
                                child: Text('$d ${localizations.translate('hours')}'),
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
                if (isSaving) const CircularProgressIndicator(), // Loading indicator
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  if (eventTitle.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(localizations.translate('error_empty_title'))),
                    );
                    return;
                  }
                  setStateDialog(() {
                    isSaving = true;
                  });
                  await Future.delayed(const Duration(seconds: 1)); // Simulate saving delay
                  setState(() {
                    events.add(CalendarEvent(
                      date: day,
                      hour: startHour,
                      duration: selectedDuration,
                      title: eventTitle,
                    ));
                  });
                  Navigator.pop(context);
                },
                child: Text(localizations.translate('save')),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(localizations.translate('cancel')),
              ),
            ],
          );
        });
      },
    );
  }

  // Show the dialog to edit an existing event
  void _showEditEventDialog(CalendarEvent event) {
    final localizations = AppLocalizations.of(context);
    String eventTitle = event.title;
    int duration = event.duration;
    TextEditingController controller = TextEditingController(text: event.title);
    List<int> availableDurations = _getAvailableDurations(event.date, event.hour, event);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(
              '${localizations.translate('edit_event')}: ${DateFormat('EEE, MMM d', localizations.languageCode()).format(event.date)} ${localizations.translate('at')} ${event.hour}:00',
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  decoration: InputDecoration(hintText: localizations.translate('event_title')),
                  onChanged: (value) {
                    eventTitle = value;
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text('${localizations.translate('duration')}: '),
                    DropdownButton<int>(
                      value: duration,
                      items: availableDurations
                          .map((d) => DropdownMenuItem(
                                value: d,
                                child: Text('$d ${localizations.translate('hours')}'),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setStateDialog(() {
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
                child: Text(localizations.translate('save')),
              ),
              TextButton(
                onPressed: () async {
                  bool confirmDelete = await showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text(localizations.translate('confirm_delete')),
                        content: Text(localizations.translate('delete_event_confirmation')),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(localizations.translate('yes')),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(localizations.translate('no')),
                          ),
                        ],
                      );
                    },
                  );
                  if (confirmDelete) {
                    setState(() {
                      events.remove(event);
                    });
                    Navigator.pop(context);
                  }
                },
                child: Text(localizations.translate('delete')),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(localizations.translate('cancel')),
              ),
            ],
          );
        });
      },
    );
  }

  // This method handles the creation of an event after a drag gesture
  void _handleDragEventCreation(DateTime day) {
    if (_dragStartIndex != null && _dragEndIndex != null) {
      int startIndex = _dragStartIndex!.clamp(0, hours.length - 1);
      int endIndex = _dragEndIndex!.clamp(0, hours.length - 1);
      int startHour = hours[startIndex];
      int duration = (endIndex - startIndex + 1).abs();

      List<int> availableDurations = _getAvailableDurations(day, startHour);
      if (availableDurations.contains(duration)) {
        _showAddEventDialog(day, startIndex, endIndex);
      }
    }
    _dragStartIndex = null;
    _dragEndIndex = null;
    _dragStartDay = null; // Reset the drag start day
  }

  // This method builds the time column (on the left)
  Widget _buildTimeColumn() {
    return Container(
      width: 60,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10.0),
          bottomLeft: Radius.circular(10.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: hours.map((hour) {
          String label = hour == 24 ? "00:00" : "$hour:00";
          return Container(
            height: cellHeight,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          );
        }).toList(),
      ),
    );
  }

  // This method builds the column for a specific day with drag support
  Widget _buildDayColumn(DateTime day) {
    List<Widget> cells = [];
    int index = 0;

    while (index < hours.length) {
      int currentHour = hours[index];
      CalendarEvent? event = _getEventForCell(day, currentHour);

      if (event != null) {
        // Existing event: allow tap to edit
        cells.add(
          GestureDetector(
            onTap: () {
              _showEditEventDialog(event); // Show popup to edit the event
            },
            child: Container(
              height: cellHeight * event.duration,
              margin: const EdgeInsets.only(bottom: 1),
              decoration: BoxDecoration(
                color: Colors.lightBlueAccent,
                borderRadius: BorderRadius.circular(8.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                event.title,
                style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
        index += event.duration;
      } else {
        // Empty cell: allow tap to add a new event or long press to drag
        final int cellIndex = index;
        cells.add(
          GestureDetector(
            onTap: () {
              _showAddEventDialog(day, cellIndex); // Show popup to add an event
            },
            onLongPressStart: (_) {
              setState(() {
                _dragStartIndex = cellIndex;
                _dragEndIndex = cellIndex;
                _dragStartDay = day; // Track the day where the drag started
              });
            },
            onLongPressMoveUpdate: (details) {
              setState(() {
                RenderBox box = context.findRenderObject() as RenderBox;
                Offset localPosition = box.globalToLocal(details.globalPosition);
                int newIndex = (localPosition.dy / cellHeight).floor();
                _dragEndIndex = newIndex.clamp(0, hours.length - 1);
              });
            },
            onLongPressEnd: (_) {
              _handleDragEventCreation(day);
              _dragStartDay = null; // Reset the drag start day
            },
            child: Container(
              height: cellHeight,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(4.0),
                color: (_dragStartIndex != null &&
                        _dragEndIndex != null &&
                        _dragStartDay != null &&
                        _isSameDay(_dragStartDay!, day) &&
                        cellIndex >= _dragStartIndex! &&
                        cellIndex <= _dragEndIndex!)
                    ? Colors.blue.withOpacity(0.7) // Improved highlight visibility
                    : Colors.transparent,
              ),
            ),
          ),
        );
        index++;
      }
    }

    return Expanded(
      child: Stack(
        children: [
          Column(children: cells),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    // Determine the number of days to display based on screen width
    final int daysToShow = screenWidth > 600 ? 7 : 3; // 7 days for desktop, 3 days for mobile
    final PageController pageController = PageController(initialPage: 0);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('calendar')),
        backgroundColor: Colors.blueAccent,
      ),
      body: PageView.builder(
        controller: pageController,
        onPageChanged: (pageIndex) {
          // Optionally handle page index changes if needed
        },
        itemBuilder: (context, pageIndex) {
          // Calculate the start day for the current page
          final DateTime startDay = DateTime.now().add(Duration(days: pageIndex * daysToShow));
          final List<DateTime> visibleDays = _getDays(startDay, daysToShow);

          return Column(
            children: [
              // Header: empty time column + day headers
              Row(
                children: [
                  Container(width: 60, height: 40),
                  ...visibleDays.map((day) {
                    final String dayFormat = screenWidth > 600 ? 'EEEE, d MMM' : 'EEE, d MMM';
                    final String formattedDay = toBeginningOfSentenceCase(
                      DateFormat(dayFormat, localizations.languageCode()).format(day),
                    )!;
                    return Expanded(
                      child: Container(
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          formattedDay,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
                      ...visibleDays.map((day) => _buildDayColumn(day)).toList(),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
