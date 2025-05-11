import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'l10n/app_localizations.dart';

class CalendarEvent {
  DateTime date;
  int hour; // Start hour
  int duration;
  String title;
  double? widthFactor; // Factor to adjust width for overlapping events
  Alignment? alignment; // Alignment for the event cell

  CalendarEvent({
    required this.date,
    required this.hour,
    required this.duration,
    required this.title,
    this.widthFactor,
    this.alignment,
  });
}

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final double cellHeight = 20.0; // Slot Height
  // Adjust hours to represent 15-minute intervals starting from 6:00 to 00:00
  late final List<int> hours =
      List.generate(19 * 4, (index) => index); // 76 slots (19 hours * 4)
  final List<CalendarEvent> events = []; // List of created events

  int? _dragStartIndex; // Index of the cell where the drag started
  int? _dragEndIndex; // Index of the cell where the drag ended
  DateTime? _dragStartDay; // Day of the cell where the drag started
  CalendarEvent? _draggedEvent; // Event being dragged

  // Compute the week days starting from a given day
  List<DateTime> _getDays(DateTime startDay, int count) {
    return List.generate(count, (index) => startDay.add(Duration(days: index)));
  }

  // Compute the week days starting from the nearest Monday
  List<DateTime> _getWeekDays(DateTime startDay, int count) {
    DateTime monday = startDay.subtract(Duration(days: startDay.weekday - 1));
    return List.generate(count, (index) => monday.add(Duration(days: index)));
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

  // Helper to convert slot index to time string, starting from 6:00
  String _formatTime(int slot) {
    int hour = 6 + (slot ~/ 4); // Start from 6:00
    if (hour == 24) hour = 0; // Handle 00:00
    int minute = (slot % 4) * 15;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  // Update available durations to support 15-minute intervals
  List<int> _getAvailableDurations(DateTime day, int startSlot,
      [CalendarEvent? excludeEvent]) {
    List<int> availableDurations = [];
    int maxDuration =
        hours.length - startSlot; // Limit duration to fit within the table

    for (int duration = 1; duration <= maxDuration; duration++) {
      // Rimuovi il controllo di sovrapposizione
      availableDurations.add(duration);
    }
    return availableDurations;
  }

  // Show the dialog to add a new event
  void _showAddEventDialog(DateTime day, int startIndex, [int? endIndex]) {
    if (day.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      return;
    }
    final localizations = AppLocalizations.of(context);
    String eventTitle = '';
    bool isSaving = false; // Indicatore di caricamento
    int safeStart = startIndex.clamp(0, hours.length - 1);
    int startSlot = safeStart;
    int duration = endIndex != null ? (endIndex - startIndex + 1).abs() : 1;

    // Rimuovi il controllo di celle occupate
    int selectedStartSlot = startSlot;

    List<int> availableDurations =
        _getAvailableDurations(day, selectedStartSlot);
    int selectedDuration = availableDurations.contains(duration)
        ? duration
        : (availableDurations.isNotEmpty ? availableDurations.first : 1);
    DateTime selectedDay = day;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(localizations.translate('new_event')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: InputDecoration(
                      hintText: localizations.translate('event_title')),
                  onChanged: (value) {
                    eventTitle = value;
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text('${localizations.translate('day')}: '),
                    TextButton(
                      onPressed: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDay,
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (pickedDate != null) {
                          setStateDialog(() {
                            selectedDay = pickedDate;
                          });
                        }
                      },
                      child: Text(
                          DateFormat('EEE, MMM d', localizations.languageCode())
                              .format(selectedDay)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text('${localizations.translate('start_hour')}: '),
                    DropdownButton<int>(
                      value: selectedStartSlot,
                      items: hours
                          .map((slot) => DropdownMenuItem(
                                value: slot,
                                child: Text(_formatTime(slot)),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setStateDialog(() {
                            selectedStartSlot = value;
                            availableDurations = _getAvailableDurations(
                                selectedDay, selectedStartSlot);
                            if (!availableDurations
                                .contains(selectedDuration)) {
                              selectedDuration = availableDurations.isNotEmpty
                                  ? availableDurations.first
                                  : 1;
                            }
                          });
                        }
                      },
                    ),
                  ],
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
                                child: Text('${(d ~/ 4)}h ${(d % 4) * 15}m'),
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
                if (isSaving)
                  const CircularProgressIndicator(), // Indicatore di caricamento
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  if (eventTitle.isEmpty) {
                    eventTitle =
                        'Nuovo Evento'; // Imposta il titolo predefinito
                  }
                  setStateDialog(() {
                    isSaving = true;
                  });
                  await Future.delayed(const Duration(
                      seconds: 1)); // Simula il ritardo di salvataggio
                  setState(() {
                    events.add(CalendarEvent(
                      date: selectedDay,
                      hour: selectedStartSlot,
                      duration: selectedDuration,
                      title: eventTitle,
                    ));
                  });
                  Navigator.pop(context);
                },
                child: Text(localizations.translate('save')),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(localizations.translate('cancel')),
              ),
            ],
          );
        });
      },
    );
  }

  // Adjust the logic to calculate the correct start hour for events
  void _showEditEventDialog(CalendarEvent event) {
    final localizations = AppLocalizations.of(context);
    String eventTitle = event.title;
    int duration = event.duration;
    DateTime selectedDay = event.date;
    int selectedStartSlot = ((event.hour - 6) * 4)
        .clamp(0, hours.length - 1); // Adjust for 6:00 start
    TextEditingController controller = TextEditingController(text: event.title);
    List<int> availableDurations =
        _getAvailableDurations(event.date, selectedStartSlot, event);

    // Ensure the selectedStartSlot is valid
    if (!hours.contains(selectedStartSlot)) {
      selectedStartSlot = hours.first;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(localizations.translate('edit_event')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                      hintText: localizations.translate('event_title')),
                  onChanged: (value) {
                    eventTitle = value;
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text('${localizations.translate('day')}: '),
                    TextButton(
                      onPressed: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDay,
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (pickedDate != null) {
                          setStateDialog(() {
                            selectedDay = pickedDate;
                          });
                        }
                      },
                      child: Text(
                          DateFormat('EEE, MMM d', localizations.languageCode())
                              .format(selectedDay)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text('${localizations.translate('start_hour')}: '),
                    DropdownButton<int>(
                      value: selectedStartSlot,
                      items: hours
                          .map((slot) => DropdownMenuItem(
                                value: slot,
                                child: Text(_formatTime(slot)),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setStateDialog(() {
                            selectedStartSlot = value;
                            availableDurations = _getAvailableDurations(
                                selectedDay, selectedStartSlot, event);
                            if (!availableDurations.contains(duration)) {
                              duration = availableDurations.isNotEmpty
                                  ? availableDurations.first
                                  : 1;
                            }
                          });
                        }
                      },
                    ),
                  ],
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
                                child: Text('${(d ~/ 4)}h ${(d % 4) * 15}m'),
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
                    event.date = selectedDay;
                    event.hour =
                        6 + (selectedStartSlot ~/ 4); // Adjust for 6:00 start
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
                        content: Text(localizations
                            .translate('delete_event_confirmation')),
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

  void _handleLongPressStart(int cellIndex, DateTime day) {
    setState(() {
      _dragStartIndex = cellIndex.clamp(0, hours.length - 1); // Assicurarsi che l'indice sia valido
      _dragEndIndex = _dragStartIndex; // Inizialmente uguale all'indice di partenza
      _dragStartDay = day;
      _draggedEvent = _getEventForCell(day, hours[cellIndex]); // Imposta l'evento trascinato
    });
  }

  void _handleLongPressMoveUpdate(LongPressMoveUpdateDetails details,
      BuildContext context, ScrollController scrollController, int pageIndex) {
    if (_dragStartIndex != null && _dragStartDay != null) {
      setState(() {
        RenderBox box = context.findRenderObject() as RenderBox;
        Offset localPosition = box.globalToLocal(details.globalPosition);

        // Adjust dragOffset by including the scroll offset
        double dragOffsetY = localPosition.dy +
            scrollController.offset -
            (_dragStartIndex! * cellHeight); // Include scroll offset

        int deltaIndexY = (dragOffsetY / cellHeight).floor() - 4; // Smooth vertical movement

        // Calculate the new vertical index
        int newIndexY = (_dragStartIndex! + deltaIndexY).clamp(0, hours.length - 1);

        if (_draggedEvent != null) {
          // Calculate the maximum allowed index for the dragged event
          int maxIndex = hours.length - _draggedEvent!.duration;
          newIndexY = newIndexY.clamp(0, maxIndex);

          // Update the dragged event's start hour
          int newStartHour = hours[newIndexY];
          if (_getAvailableDurations(_dragStartDay!, newStartHour, _draggedEvent)
              .contains(_draggedEvent!.duration)) {
            _draggedEvent!.hour = newStartHour;

            // Ensure the relative position of overlapping events remains consistent
            List<CalendarEvent> overlappingEvents = events.where((e) {
              return _isSameDay(e.date, _dragStartDay!) &&
                  ((e.hour < _draggedEvent!.hour + _draggedEvent!.duration &&
                      e.hour + e.duration > _draggedEvent!.hour));
            }).toList();

            overlappingEvents.sort((a, b) => a.hour.compareTo(b.hour));
            for (int i = 0; i < overlappingEvents.length; i++) {
              overlappingEvents[i].alignment = Alignment(-1.0 + (2.0 / overlappingEvents.length) * i, 0.0);
              overlappingEvents[i].widthFactor = 1.0 / overlappingEvents.length;
            }
          }
        }

        // Update the drag end index
        if (newIndexY != _dragEndIndex) {
          _dragEndIndex = newIndexY;
        }
      });
    }
  }

  void _handleLongPressEnd(DateTime day) {
    if (_dragStartIndex != null && _dragEndIndex != null) {
      // Check if the event was not moved
      if (_dragStartIndex == _dragEndIndex && _isSameDay(_dragStartDay!, day)) {
        // Reset the state without modifying the event
        setState(() {
          _draggedEvent = null;
          _dragStartIndex = null;
          _dragEndIndex = null;
          _dragStartDay = null;
        });
        return;
      }

      if (_draggedEvent != null) {
        // Only update the event if it was actually moved
        if (_dragStartIndex != _dragEndIndex || !_isSameDay(_dragStartDay!, day)) {
          _handleDragEventMove(_draggedEvent!.date);
        }
      } else {
        // Handle the creation of a new event
        _handleDragEventCreation(day);
      }
    }
    // Reset the drag state
    setState(() {
      _draggedEvent = null;
      _dragStartIndex = null;
      _dragEndIndex = null;
      _dragStartDay = null;
    });
  }

  // This method handles the creation of an event after a drag gesture
  void _handleDragEventCreation(DateTime day) {
    if (_dragStartIndex != null && _dragEndIndex != null) {
      int startIndex = _dragStartIndex!.clamp(0, hours.length - 1);
      int endIndex = _dragEndIndex!.clamp(0, hours.length - 1);

      // Ensure the start index is always less than or equal to the end index
      if (startIndex > endIndex) {
        int temp = startIndex;
        startIndex = endIndex;
        endIndex = temp;
      }

      int startSlot = startIndex;
      int duration = (endIndex - startIndex + 1).abs();

      // If the duration is valid (at least 1 slot), show the dialog to create the event
      if (duration > 0) {
        _showAddEventDialog(day, startSlot, startSlot + duration - 1);
      }

      // Adjust overlapping events after creation
      _adjustOverlappingEvents(day);

      // Reset drag indices
      _dragStartIndex = null;
      _dragEndIndex = null;
    }
  }

  // Ensure proper alignment and width factor for overlapping events
  void _adjustOverlappingEvents(DateTime day) {
    List<CalendarEvent> dayEvents = events.where((e) => _isSameDay(e.date, day)).toList();

    for (var event in dayEvents) {
      List<CalendarEvent> overlappingEvents = dayEvents.where((e) {
        return e != event &&
            ((e.hour < event.hour + event.duration && e.hour + e.duration > event.hour));
      }).toList();

      overlappingEvents.add(event); // Include the current event
      overlappingEvents.sort((a, b) => a.hour.compareTo(b.hour));

      for (int i = 0; i < overlappingEvents.length; i++) {
        overlappingEvents[i].alignment = Alignment(-1.0 + (2.0 / overlappingEvents.length) * i, 0.0);
        overlappingEvents[i].widthFactor = 1.0 / overlappingEvents.length;
      }
    }
  }

  // This method handles the movement of an existing event after a drag gesture
  void _handleDragEventMove(DateTime day) {
    if (_draggedEvent != null &&
        _dragStartIndex != null &&
        _dragEndIndex != null) {
      int newStartIndex = _dragEndIndex!.clamp(0, hours.length - 1);
      int newStartHour = hours[newStartIndex];

      setState(() {
        // Update the dragged event's start hour and day
        _draggedEvent!.hour = newStartHour;
        _draggedEvent!.date = day;

        // Adjust overlapping events
        _adjustOverlappingEvents(day);
      });
    }
    _draggedEvent = null;
    _dragStartIndex = null;
    _dragEndIndex = null;
    _dragStartDay = null; // Reset drag state
  }

  Widget _buildEventCell(CalendarEvent event, int index, DateTime day,
      ScrollController scrollController, int pageIndex) {
    bool isBeingDragged = _draggedEvent == event;
    bool isPastEvent = event.date.isBefore(DateTime.now()) &&
        !_isSameDay(day, DateTime.now()); // Only events before today
    int daysToShow = MediaQuery.of(context).size.width > 600 ? 7 : 3;

    double columnWidth = MediaQuery.of(context).size.width / daysToShow;

    // Calculate the horizontal position (left) based on the event's day
    DateTime startDay = DateTime.now().subtract(Duration(
        days: DateTime.now().weekday - 1)); // Start from Monday
    startDay = startDay.add(Duration(days: pageIndex * daysToShow));
    List<DateTime> visibleDays = _getWeekDays(startDay, daysToShow);
    int dayIndex = visibleDays.indexWhere((d) => _isSameDay(d, event.date));
    double left = dayIndex >= 0 ? dayIndex * columnWidth : 0.0;

    return Positioned(
      left: left, // Use calculated horizontal position
      top: cellHeight * (event.hour - hours.first),
      width: columnWidth - 2,
      height: cellHeight * event.duration,
      child: GestureDetector(
        onTap: () => _showEditEventDialog(event),
        onLongPressStart: (_) => setState(() {
          _draggedEvent = event;
          _dragStartIndex = index;
          _dragEndIndex = index;
          _dragStartDay = day;
        }),
        onLongPressMoveUpdate: (details) => _handleLongPressMoveUpdate(
            details, context, scrollController, pageIndex),
        onLongPressEnd: (_) => _handleDragEventMove(day),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 50), // Smooth animation
          margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
          decoration: BoxDecoration(
            color: isBeingDragged
                ? Colors.blueAccent.withOpacity(0.7)
                : isPastEvent
                    ? Colors.grey[600]
                    : Colors.lightBlueAccent,
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
          child: Center(
            child: Text(
              event.title,
              style: const TextStyle(
                  fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCell(int cellIndex, DateTime day,
      ScrollController scrollController, int pageIndex) {
    if (day.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      // Prevent highlighting for past days
      return Container(
        height: cellHeight,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(4.0),
          color: Colors.transparent,
        ),
      );
    }

    bool isHighlighted = _dragStartIndex != null &&
        _dragEndIndex != null &&
        _dragStartDay != null &&
        _isSameDay(_dragStartDay!, day) &&
        _draggedEvent == null && // Ensure no event is being dragged
        ((cellIndex >= _dragStartIndex! && cellIndex <= _dragEndIndex!) ||
            (cellIndex <= _dragStartIndex! && cellIndex >= _dragEndIndex!));

    return GestureDetector(
      onTap: () => _showAddEventDialog(day, cellIndex),
      onLongPressStart: (_) => _handleLongPressStart(cellIndex, day),
      onLongPressMoveUpdate: (details) => _handleLongPressMoveUpdate(
          details, context, scrollController, pageIndex),
      onLongPressEnd: (_) => _handleLongPressEnd(day),
      child: Container(
        height: cellHeight,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(4.0),
          color:
              isHighlighted ? Colors.blue.withOpacity(0.7) : Colors.transparent,
        ),
      ),
    );
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
        children: List.generate(19, (index) {
          int hour = 6 + index; // Start from 6:00
          if (hour == 24) hour = 0; // Handle 00:00
          String label = hour == 0 ? "00:00" : "$hour:00";
          return Container(
            height: cellHeight * 4, // Adjust height to match 15-minute slots
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
        }),
      ),
    );
  }

  // This method builds the column for a specific day with drag support
  Widget _buildDayColumn(
      DateTime day, ScrollController scrollController, int pageIndex) {
    List<Widget> cells = [];
    List<Widget> eventWidgets = [];
    int index = 0;

    // Calculate the width of the cells based on screen width and number of visible days
    int daysToShow = MediaQuery.of(context).size.width > 600 ? 7 : 3;
    double cellWidth = MediaQuery.of(context).size.width / daysToShow;
    int correctionFactor = MediaQuery.of(context).size.width > 600 ? 12 : 30;

    while (index < hours.length) {
      int currentHour = hours[index];
      CalendarEvent? event = _getEventForCell(day, currentHour);

      // Always add an empty cell
      cells.add(_buildEmptyCell(index, day, scrollController, pageIndex));

      if (event != null) {
        // Find all events that overlap partially or completely
        List<CalendarEvent> overlappingEvents = events.where((e) {
          return _isSameDay(e.date, day) &&
              ((e.hour < event.hour + event.duration &&
                  e.hour + e.duration > event.hour));
        }).toList();

        // Calculate the width for each event based on the number of overlapping events
        int totalOverlapping =
            overlappingEvents.isNotEmpty ? overlappingEvents.length : 1;
        double widthFactor = (cellWidth - correctionFactor) / totalOverlapping;

        // Position each overlapping event with the calculated width
        for (int i = 0; i < overlappingEvents.length; i++) {
          CalendarEvent overlappingEvent = overlappingEvents[i];
          bool isBeingDragged = _draggedEvent == overlappingEvent;
          bool isPastEvent = overlappingEvent.date.isBefore(DateTime.now()) &&
              !_isSameDay(overlappingEvent.date, DateTime.now());

          eventWidgets.add(
            Positioned(
              left: widthFactor * i,
              top: cellHeight * (overlappingEvent.hour - hours.first),
              width: widthFactor,
              height: cellHeight * overlappingEvent.duration,
              child: GestureDetector(
                onTap: () => _showEditEventDialog(overlappingEvent),
                onLongPressStart: (_) => setState(() {
                  _draggedEvent = overlappingEvent;
                  _dragStartIndex = index;
                  _dragEndIndex = index;
                  _dragStartDay = day;
                }),
                onLongPressMoveUpdate: (details) => _handleLongPressMoveUpdate(
                    details, context, scrollController, pageIndex),
                onLongPressEnd: (_) => _handleDragEventMove(day),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 50),
                  margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
                  decoration: BoxDecoration(
                    color: isBeingDragged
                        ? Colors.blueAccent.withOpacity(0.7)
                        : isPastEvent
                            ? Colors.grey[600]
                            : Colors.lightBlueAccent,
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
                  child: Center(
                    child: Text(
                      overlappingEvent.title,
                      style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        // Increment index by event duration but still add empty cells for skipped slots
        for (int i = 1; i < event.duration; i++) {
          cells.add(_buildEmptyCell(index + i, day, scrollController, pageIndex));
        }
        index += event.duration;
      } else {
        index++;
      }
    }

    return SizedBox(
      width: cellWidth,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Column(
            children: cells, // Always include the cells
          ),
          ...eventWidgets, // Position events on top of the cells
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    // Determine the number of days to display based on screen width
    final int daysToShow =
        screenWidth > 600 ? 7 : 3; // 7 days for desktop, 3 days for mobile
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
          final DateTime startDay =
              DateTime.now().add(Duration(days: pageIndex * daysToShow));
          final List<DateTime> visibleDays = screenWidth > 600
              ? _getWeekDays(
                  startDay, daysToShow) // Start from Monday for desktop
              : _getDays(startDay, daysToShow);

          // Create a single ScrollController for the page
          final ScrollController scrollController = ScrollController();

          return Column(
            children: [
              // Header: empty time column + day headers
              Row(
                children: [
                  SizedBox(width: 60, height: 40),
                  ...visibleDays.map((day) {
                    final String dayFormat =
                        screenWidth > 600 ? 'EEEE, d MMM' : 'EEE, d MMM';
                    final String formattedDay = toBeginningOfSentenceCase(
                      DateFormat(dayFormat, localizations.languageCode())
                          .format(day),
                    )!;
                    bool isPastDay = day.isBefore(DateTime.now()) &&
                        !_isSameDay(day, DateTime.now()); // Exclude today
                    return Expanded(
                      child: Container(
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          color: isPastDay
                              ? Colors.grey[300]
                              : Colors.blue[100], // Gray for past days
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          formattedDay,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isPastDay ? Colors.grey[600] : Colors.black,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
              // Body: time column + days grid in vertical scroll
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController, // Attach the ScrollController
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTimeColumn(),
                      ...visibleDays.map((day) {
                        return Expanded(
                          child:
                              _buildDayColumn(day, scrollController, pageIndex),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Show a dialog to add a new event
          _showAddEventDialog(
              DateTime.now(), 0); // Default to current day and first hour
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add),
      ),
    );
  }
}
