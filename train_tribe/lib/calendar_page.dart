import 'package:flutter/material.dart';
// Import for LinkedScrollControllerGroup
import 'package:intl/intl.dart';
import 'l10n/app_localizations.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart'; // Import the package
import 'package:uuid/uuid.dart'; // Add this import for generating unique IDs
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CalendarEvent {
  final String id; // Unique identifier for the event
  String? generatedBy; // ID of the original event for recurrent copies
  DateTime date;
  int hour; // Start hour
  int endHour; // End hour
  String departureStation;
  String arrivalStation;
  double? widthFactor; // Factor to adjust width for overlapping events
  Alignment? alignment; // Alignment for the event cell
  bool isBeingDragged = false; // Indicates if the event is being dragged
  bool isRecurrent; // Indicates if the event is recurrent
  DateTime? recurrenceEndDate; // End date for recurrence

  CalendarEvent({
    String? id,
    this.generatedBy,
    required this.date,
    required this.hour,
    required this.endHour,
    required this.departureStation,
    required this.arrivalStation,
    this.widthFactor,
    this.alignment,
    this.isRecurrent = false,
    this.recurrenceEndDate,
  }) : id = id ?? const Uuid().v4(); // Generate a unique ID if not provided

  // Factory per creare un evento da un documento Firebase
  factory CalendarEvent.fromFirestore(String id, Map<String, dynamic> data) {
    final DateTime start = (data['event_start'] as Timestamp).toDate();
    final DateTime end = (data['event_end'] as Timestamp).toDate();
    return CalendarEvent(
      id: id,
      date: DateTime(start.year, start.month, start.day),
      hour: ((start.hour - 6) * 4 + (start.minute ~/ 15)).clamp(0, 75),
      endHour: ((end.hour - 6) * 4 + (end.minute ~/ 15)).clamp(0, 76),
      departureStation: data['origin'] ?? '',
      arrivalStation: data['destination'] ?? '',
      isRecurrent: data['recurrent'] ?? false,
      recurrenceEndDate: data['recurrence_end'] != null
          ? (data['recurrence_end'] as Timestamp).toDate()
          : null,
    );
  }
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

  final LinkedScrollControllerGroup _scrollControllerGroup =
      LinkedScrollControllerGroup(); // Group for synchronized scrolling
  late final ScrollController _timeColumnController =
      _scrollControllerGroup.addAndGet(); // Controller for the time column
  late final ScrollController _dayColumnsController =
      _scrollControllerGroup.addAndGet(); // Controller for the day columns

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
    if (hour == 25) hour = 1; // Display 1:00 instead of 25:00
    int minute = (slot % 4) * 15;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  // Update the logic for available end hours
  List<int> _getAvailableEndHours(DateTime day, int startSlot,
      [CalendarEvent? excludeEvent]) {
    List<int> availableEndHours = [];
    for (int endSlot = startSlot + 1; endSlot <= hours.length; endSlot++) {
      availableEndHours.add(endSlot);
    }
    return availableEndHours;
  }

  // Show the dialog to add a new event
  void _showAddEventDialog(DateTime day, int startIndex, [int? endIndex]) {
    if (day.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      return;
    }
    final localizations = AppLocalizations.of(context);
    String departureStation = '';
    String arrivalStation = '';
    bool isSaving = false; // Indicatore di caricamento
    int safeStart = startIndex.clamp(0, hours.length - 1);
    int startSlot = safeStart;
    int selectedEndSlot = endIndex ?? startSlot + 1;

    List<int> availableEndHours =
        _getAvailableEndHours(day, startSlot);

    bool isRecurrent = false;
    DateTime? recurrenceEndDate = day.add(const Duration(days: 7)); // Default to one week later

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
                      hintText: localizations.translate('departure_station')),
                  onChanged: (value) {
                    departureStation = value;
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  decoration: InputDecoration(
                      hintText: localizations.translate('arrival_station')),
                  onChanged: (value) {
                    arrivalStation = value;
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
                          initialDate: day,
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (pickedDate != null) {
                          setStateDialog(() {
                            day = pickedDate;
                          });
                        }
                      },
                      child: Text(
                          DateFormat('EEE, MMM d', localizations.languageCode())
                              .format(day)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text('${localizations.translate('start_hour')}: '),
                    DropdownButton<int>(
                      value: startSlot,
                      items: hours
                          .map((slot) => DropdownMenuItem(
                                value: slot,
                                child: Text(_formatTime(slot)),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setStateDialog(() {
                            startSlot = value;
                            availableEndHours = _getAvailableEndHours(
                                day, startSlot);
                            if (!availableEndHours
                                .contains(selectedEndSlot)) {
                              selectedEndSlot = availableEndHours.isNotEmpty
                                  ? availableEndHours.first
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
                    Text('${localizations.translate('end_hour')}: '),
                    DropdownButton<int>(
                      value: selectedEndSlot,
                      items: availableEndHours
                          .map((slot) => DropdownMenuItem(
                                value: slot,
                                child: Text(_formatTime(slot)),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setStateDialog(() {
                            selectedEndSlot = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
                Row(
                  children: [
                    Checkbox(
                      value: isRecurrent,
                      onChanged: (value) {
                        setStateDialog(() {
                          isRecurrent = value ?? false;
                        });
                      },
                    ),
                    Text(localizations.translate('recurrent')),
                  ],
                ),
                if (isRecurrent)
                  Row(
                    children: [
                      Text('${localizations.translate('end_recurrence')}: '),
                      TextButton(
                        onPressed: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: recurrenceEndDate ?? day,
                            firstDate: day,
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (pickedDate != null) {
                            setStateDialog(() {
                              recurrenceEndDate = pickedDate;
                            });
                          }
                        },
                        child: Text(recurrenceEndDate != null
                            ? DateFormat('EEE, MMM d', localizations.languageCode())
                                .format(recurrenceEndDate!)
                            : localizations.translate('select_date')),
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
                  if (departureStation.isEmpty || arrivalStation.isEmpty) {
                    return; // Ensure both fields are filled
                  }
                  setStateDialog(() {
                    isSaving = true;
                  });

                  // Salva su Firestore con id generato da Firebase e path corretto
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    final eventsCollection = FirebaseFirestore.instance.collection('users/${user.uid}/events');
                    final eventStart = DateTime(
                      day.year, day.month, day.day,
                      6 + (startSlot ~/ 4),
                      (startSlot % 4) * 15,
                    );
                    final eventEnd = DateTime(
                      day.year, day.month, day.day,
                      6 + (selectedEndSlot ~/ 4),
                      (selectedEndSlot % 4) * 15,
                    );
                    final eventData = {
                      'origin': departureStation,
                      'destination': arrivalStation,
                      'event_start': Timestamp.fromDate(eventStart),
                      'event_end': Timestamp.fromDate(eventEnd),
                      'recurrence_end': isRecurrent && recurrenceEndDate != null
                          ? Timestamp.fromDate(recurrenceEndDate!)
                          : null,
                      'recurrent': isRecurrent,
                    };
                    final newEventRef = await eventsCollection.add(eventData);
                    final newEventId = newEventRef.id;
                    setState(() {
                      events.add(CalendarEvent(
                        id: newEventId,
                        date: day,
                        hour: startSlot,
                        endHour: selectedEndSlot,
                        departureStation: departureStation,
                        arrivalStation: arrivalStation,
                        isRecurrent: isRecurrent,
                        recurrenceEndDate: recurrenceEndDate,
                      ));
                    });
                  }

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
    String departureStation = event.departureStation;
    String arrivalStation = event.arrivalStation;
    DateTime selectedDay = event.date;
    int selectedStartSlot = event.hour;
    int selectedEndSlot = event.endHour;
    TextEditingController controller = TextEditingController(text: event.departureStation);
    List<int> availableEndHours = _getAvailableEndHours(event.date, selectedStartSlot, event);

    bool isRecurrent = event.isRecurrent;
    DateTime? recurrenceEndDate = event.recurrenceEndDate ?? event.date.add(const Duration(days: 7));

    // Locate the generator event if this is a copy
    CalendarEvent? generatorEvent = event.generatedBy != null
        ? events.firstWhere((e) => e.id == event.generatedBy, orElse: () => event)
        : event;

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
                  controller: TextEditingController(text: departureStation),
                  decoration: InputDecoration(
                      hintText: localizations.translate('departure_station')),
                  onChanged: (value) {
                    departureStation = value;
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: TextEditingController(text: arrivalStation),
                  decoration: InputDecoration(
                      hintText: localizations.translate('arrival_station')),
                  onChanged: (value) {
                    arrivalStation = value;
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
                          lastDate: DateTime.now().add(const Duration(days: 365)),
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
                            availableEndHours = _getAvailableEndHours(
                                selectedDay, selectedStartSlot, event);
                            if (!availableEndHours.contains(selectedEndSlot)) {
                              selectedEndSlot = availableEndHours.isNotEmpty
                                  ? availableEndHours.first
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
                    Text('${localizations.translate('end_hour')}: '),
                    DropdownButton<int>(
                      value: selectedEndSlot,
                      items: availableEndHours
                          .map((slot) => DropdownMenuItem(
                                value: slot,
                                child: Text(_formatTime(slot)),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setStateDialog(() {
                            selectedEndSlot = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
                Row(
                  children: [
                    Checkbox(
                      value: isRecurrent,
                      onChanged: (value) {
                        setStateDialog(() {
                          isRecurrent = value ?? false;
                        });
                      },
                    ),
                    Text(localizations.translate('recurrent')),
                  ],
                ),
                if (isRecurrent)
                  Row(
                    children: [
                      Text('${localizations.translate('end_recurrence')}: '),
                      TextButton(
                        onPressed: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: recurrenceEndDate ?? selectedDay,
                            firstDate: selectedDay,
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (pickedDate != null) {
                            setStateDialog(() {
                              recurrenceEndDate = pickedDate;
                            });
                          }
                        },
                        child: Text(recurrenceEndDate != null
                            ? DateFormat('EEE, MMM d', localizations.languageCode())
                                .format(recurrenceEndDate!)
                            : localizations.translate('select_date')),
                      ),
                    ],
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  if (departureStation.isEmpty || arrivalStation.isEmpty) {
                    return; // Ensure both fields are filled
                  }
                  setState(() {
                    if (isRecurrent) {
                      // Update the generator event and all its copies
                      generatorEvent.isRecurrent = true;
                      generatorEvent.recurrenceEndDate = recurrenceEndDate;
                      generatorEvent.departureStation = departureStation;
                      generatorEvent.arrivalStation = arrivalStation;
                      generatorEvent.hour = selectedStartSlot;
                      generatorEvent.endHour = selectedEndSlot;

                      for (var e in events) {
                        if (e.generatedBy == generatorEvent.id) {
                          e.departureStation = departureStation;
                          e.arrivalStation = arrivalStation;
                          e.hour = selectedStartSlot;
                          e.endHour = selectedEndSlot;
                          e.recurrenceEndDate = recurrenceEndDate;
                        }
                      }
                    } else {
                      // Update only the single event
                      generatorEvent.departureStation = departureStation;
                      generatorEvent.arrivalStation = arrivalStation;
                      generatorEvent.date = selectedDay;
                      generatorEvent.hour = selectedStartSlot;
                      generatorEvent.endHour = selectedEndSlot;
                      generatorEvent.isRecurrent = false;
                      generatorEvent.recurrenceEndDate = null;
                    }
                  });

                  // Aggiorna su Firestore
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    final eventDoc = FirebaseFirestore.instance.collection('events').doc(generatorEvent.id);
                    final eventStart = DateTime(
                      selectedDay.year, selectedDay.month, selectedDay.day,
                      6 + (selectedStartSlot ~/ 4),
                      (selectedStartSlot % 4) * 15,
                    );
                    final eventEnd = DateTime(
                      selectedDay.year, selectedDay.month, selectedDay.day,
                      6 + (selectedEndSlot ~/ 4),
                      (selectedEndSlot % 4) * 15,
                    );
                    await eventDoc.update({
                      'origin': departureStation,
                      'destination': arrivalStation,
                      'event_start': Timestamp.fromDate(eventStart),
                      'event_end': Timestamp.fromDate(eventEnd),
                      'recurrence_end': isRecurrent && recurrenceEndDate != null
                          ? Timestamp.fromDate(recurrenceEndDate!)
                          : null,
                      'recurrent': isRecurrent,
                    });
                  }

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
                      events.removeWhere((e) =>
                          e.id == generatorEvent.id || e.generatedBy == generatorEvent.id);
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
          int maxIndex = hours.length - (_draggedEvent!.endHour - _draggedEvent!.hour);
          newIndexY = newIndexY.clamp(0, maxIndex);

          // Update the dragged event's start hour
          int newStartHour = hours[newIndexY];
          int eventDuration = _draggedEvent!.endHour - _draggedEvent!.hour;
          int newEndHour = newStartHour + eventDuration;

          if (_getAvailableEndHours(_dragStartDay!, newStartHour, _draggedEvent)
              .contains(newEndHour)) {
            _draggedEvent!.hour = newStartHour;
            _draggedEvent!.endHour = newEndHour;

            // Ensure the relative position of overlapping events remains consistent
            List<CalendarEvent> overlappingEvents = events.where((e) {
              return _isSameDay(e.date, _dragStartDay!) &&
                  ((e.hour < _draggedEvent!.endHour &&
                      e.endHour > _draggedEvent!.hour));
            }).toList();

            overlappingEvents.sort((a, b) => a.hour.compareTo(b.hour));
            for (int i = 0; i < overlappingEvents.length; i++) {
              overlappingEvents[i].alignment = Alignment(-1.0 + (2.0 / overlappingEvents.length) * i, 0.0);
              overlappingEvents[i].widthFactor = 1.0 / overlappingEvents.length;
            }

            // Update the generator event if the dragged event is a copy
            if (_draggedEvent!.generatedBy != null) {
              CalendarEvent? generatorEvent = events.cast<CalendarEvent?>().firstWhere(
              (e) => e?.id == _draggedEvent!.generatedBy,
              orElse: () => null,
              );
              if (generatorEvent != null) {
              generatorEvent.hour = newStartHour;
              generatorEvent.endHour = newEndHour;
              }
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

      // Assicuriamoci che startIndex sia sempre minore o uguale a endIndex
      if (startIndex > endIndex) {
        int temp = startIndex;
        startIndex = endIndex;
        endIndex = temp;
      }

      int startSlot = startIndex;
      int endSlot = endIndex + 1; // Include l'ultimo slot nella selezione

      // Modifica: Permettiamo la creazione di eventi di un singolo slot
      if (endSlot >= startSlot) {
        _showAddEventDialog(day, startSlot, endSlot);
      }

      // Regoliamo gli eventi sovrapposti dopo la creazione
      _adjustOverlappingEvents(day);

      // Reset degli indici di drag
      _dragStartIndex = null;
      _dragEndIndex = null;
    }
  }

  // Define the missing method to handle drag event movement
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

        // Adjust overlapping events dynamically
        _adjustOverlappingEvents(day);
      });
    }
    _resetDragState(); // Reset the drag state
  }

  // Reset the drag state after handling the drag event
  void _resetDragState() {
    setState(() {
      _draggedEvent!.isBeingDragged = false;
    });
    _draggedEvent = null;
    _dragStartIndex = null;
    _dragEndIndex = null;
    _dragStartDay = null;
  }

  // Adjust overlapping events after creation or movement
  void _adjustOverlappingEvents(DateTime day) {
    List<CalendarEvent> dayEvents = events.where((e) => _isSameDay(e.date, day)).toList();

    // Reset alignment and width factor for all events
    for (var event in dayEvents) {
      event.alignment = Alignment.center;
      event.widthFactor = 1.0;
    }

    // Group and adjust overlapping events
    for (var event in dayEvents) {
      // Find all events that overlap with the current event
      List<CalendarEvent> overlappingEvents = dayEvents.where((e) {
        return e != event &&
            e.hour < event.endHour &&
            e.endHour > event.hour; // Correct overlap logic
      }).toList();

      // Include the current event in the overlapping group
      overlappingEvents.add(event);

      // Sort the overlapping events by start hour
      overlappingEvents.sort((a, b) => a.hour.compareTo(b.hour));

      // Recalculate alignment and width factor for all overlapping events
      for (int i = 0; i < overlappingEvents.length; i++) {
        overlappingEvents[i].alignment = Alignment(
          -1.0 + (2.0 / overlappingEvents.length) * i,
          0.0,
        );
        overlappingEvents[i].widthFactor = (1.0 / overlappingEvents.length);
      }
    }
  }

  // Helper to check if a date is within a recurrence range
  bool _isWithinRecurrence(DateTime date, CalendarEvent event) {
    if (!event.isRecurrent || event.recurrenceEndDate == null) {
      return false;
    }
    return date.isAfter(event.date.subtract(const Duration(days: 1))) &&
        date.isBefore(event.recurrenceEndDate!.add(const Duration(days: 1)));
  }

  // Generate copies of recurrent events every 7 days until the recurrence end date
  List<CalendarEvent> _generateRecurrentEvents(List<DateTime> visibleDays) {
    List<CalendarEvent> recurrentEvents = [];
    DateTime startOfWeek = visibleDays.first;
    DateTime endOfWeek = visibleDays.last;

    for (var event in events) {
      if (event.isRecurrent && event.recurrenceEndDate != null) {
        // Check if the event's recurrence overlaps with the visible week
        if (event.date.isBefore(endOfWeek.add(const Duration(days: 1))) &&
            event.recurrenceEndDate!.isAfter(startOfWeek.subtract(const Duration(days: 1)))) {
          // Generate a copy of the event every 7 days
          DateTime currentDate = event.date;
          while (currentDate.isBefore(event.recurrenceEndDate!.add(const Duration(days: 1)))) {
            if (currentDate.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
                currentDate.isBefore(endOfWeek.add(const Duration(days: 1))) &&
                !_isSameDay(currentDate, event.date)) {
              recurrentEvents.add(CalendarEvent(
                date: currentDate,
                hour: event.hour,
                endHour: event.endHour,
                departureStation: event.departureStation,
                arrivalStation: event.arrivalStation,
                isRecurrent: event.isRecurrent,
                recurrenceEndDate: event.recurrenceEndDate,
                generatedBy: event.id, // Link the copy to the original event
              ));
            }
            currentDate = currentDate.add(const Duration(days: 7));
          }
        }
      }
    }
    return recurrentEvents;
  }

  // Update the day column builder to fix event width and alignment
  Widget _buildDayColumn(
      DateTime day, ScrollController scrollController, int pageIndex,
      {List<CalendarEvent>? additionalEvents}) {
    List<Widget> cells = [];
    List<Widget> eventWidgets = [];
    int index = 0;

    // Calculate the width of the cells based on screen width and number of visible days
    int daysToShow = MediaQuery.of(context).size.width > 600 ? 7 : 3;
    double cellWidth = MediaQuery.of(context).size.width / daysToShow;

    // Collect all events for the day, including recurrent events
    List<CalendarEvent> dayEvents = events
        .where((event) => _isSameDay(event.date, day))
        .toList();

    if (additionalEvents != null) {
      dayEvents.addAll(additionalEvents
          .where((event) => _isSameDay(event.date, day))
          .toList());
    }

    // Sort events by start hour to ensure proper rendering order
    dayEvents.sort((a, b) => a.hour.compareTo(b.hour));

    while (index < hours.length) {
      int currentHour = hours[index];
      CalendarEvent? event = dayEvents.cast<CalendarEvent?>().firstWhere(
          (e) => e?.hour == currentHour && _isSameDay(e!.date, day),
          orElse: () => null);

      // Always add an empty cell
      cells.add(_buildEmptyCell(index, day, scrollController, pageIndex));

      if (event != null) {
        // Find all events that overlap partially or completely
        List<CalendarEvent> overlappingEvents = dayEvents.where((e) {
          return (e.hour < event.endHour && e.endHour > event.hour);
        }).toList();

        // Calculate the width for each event based on the number of overlapping events
        int totalOverlapping = overlappingEvents.isNotEmpty ? overlappingEvents.length : 1;
        int correctionFactor = MediaQuery.of(context).size.width > 600 ? 12 : 30;
        double widthFactor = (cellWidth - correctionFactor) / totalOverlapping;

        // Position each overlapping event with the calculated width
        for (int i = 0; i < overlappingEvents.length; i++) {
          CalendarEvent overlappingEvent = overlappingEvents[i];
          bool isBeingDragged = _draggedEvent == overlappingEvent;

          eventWidgets.add(
            Positioned(
              left: widthFactor * i,
              top: cellHeight * (overlappingEvent.hour - hours.first),
              width: widthFactor,
              height: cellHeight * (overlappingEvent.endHour - overlappingEvent.hour),
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
                        ? overlappingEvent.isRecurrent
                            ? Colors.purpleAccent.withOpacity(0.7)
                            : Colors.blueAccent.withOpacity(0.7)
                        : overlappingEvent.isRecurrent
                            ? Colors.purpleAccent
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
                      '${overlappingEvent.departureStation} - ${overlappingEvent.arrivalStation}',
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
        for (int i = 1; i < event.endHour - event.hour; i++) {
          cells.add(_buildEmptyCell(index + i, day, scrollController, pageIndex));
        }
        index += event.endHour - event.hour;
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
            children: cells,
          ),
          ...eventWidgets,
        ],
      ),
    );
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
      height: cellHeight * (event.endHour - event.hour),
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
                : event.isRecurrent
                    ? Colors.purpleAccent // Color recurrent events in purple
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
              '${event.departureStation} - ${event.arrivalStation}',
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

  @override
  void initState() {
    super.initState();
    _loadUserEvents();
  }

  Future<void> _loadUserEvents() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    List<CalendarEvent> loadedEvents = await fetchEventsFromFirebase(user.uid);
    setState(() {
      events.clear();
      events.addAll(loadedEvents);
    });
  }

  Future<List<CalendarEvent>> fetchEventsFromFirebase(String userId) async {
    final userEventsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('events');
    final userEventsSnapshot = await userEventsRef.get();
    List<CalendarEvent> result = [];

    for (var doc in userEventsSnapshot.docs) {
      final eventId = doc.id;
      final eventDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('events')
          .doc(eventId)
          .get();
      if (eventDoc.exists) {
        result.add(CalendarEvent.fromFirestore(eventDoc.id, eventDoc.data()!));
      }
    }
    print('Loaded ${result.length} events from Firebase for user $userId');
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    // Determine the number of days to display based on screen width
    final int daysToShow =
        screenWidth > 600 ? 7 : 3; // 7 days for desktop, 3 days for mobile
    final PageController pageController = PageController(initialPage: 0);

    // Generate recurrent events for the visible days
    List<CalendarEvent> recurrentEvents =
        _generateRecurrentEvents(_getWeekDays(DateTime.now(), daysToShow));

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('calendar')),
        backgroundColor: Colors.blueAccent,
      ),
      body: Row(
        children: [
          // Fixed time column with synchronized vertical scrolling
          ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false), // Disable scrollbar
            child: SingleChildScrollView(
              controller: _timeColumnController, // Use the linked controller
              child: Column(
                children: [
                  SizedBox(height: 40), // Align with the day headers
                  _buildTimeColumn(),
                ],
              ),
            ),
          ),
          // Scrollable day columns
          Expanded(
            child: PageView.builder(
              controller: pageController,
              itemBuilder: (context, pageIndex) {
                final DateTime startDay =
                    DateTime.now().add(Duration(days: pageIndex * daysToShow));
                final List<DateTime> visibleDays = screenWidth > 600
                    ? _getWeekDays(startDay, daysToShow)
                    : _getDays(startDay, daysToShow);

                // Generate recurrent events for the visible days
                List<CalendarEvent> recurrentEvents =
                    _generateRecurrentEvents(visibleDays);

                return Column(
                  children: [
                    // Header: day headers
                    Row(
                      children: visibleDays.map((day) {
                        final String dayFormat =
                            screenWidth > 600 ? 'EEEE, d MMM' : 'EEE, d MMM';
                        final String formattedDay = toBeginningOfSentenceCase(
                          DateFormat(dayFormat, localizations.languageCode())
                              .format(day),
                        )!;
                        bool isPastDay = day.isBefore(DateTime.now()) &&
                            !_isSameDay(day, DateTime.now());
                        return Expanded(
                          child: Container(
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              color: isPastDay
                                  ? Colors.grey[300]
                                  : Colors.blue[100],
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Text(
                              formattedDay,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color:
                                    isPastDay ? Colors.grey[600] : Colors.black,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    // Body: days grid in vertical scroll
                    Expanded(
                      child: ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false), // Disable scrollbar
                        child: SingleChildScrollView(
                          controller: _dayColumnsController, // Use the linked controller
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: visibleDays.map((day) {
                              return Expanded(
                                child: _buildDayColumn(
                                  day,
                                  _dayColumnsController,
                                  pageIndex,
                                  additionalEvents: recurrentEvents, // Pass recurrent events
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
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
