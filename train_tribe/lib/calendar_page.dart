import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'l10n/app_localizations.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'utils/events_firebase.dart';
import 'utils/calendar_functions.dart';
import 'models/calendar_event.dart';
import 'widgets/event_dialogs.dart';
import 'widgets/calendar_columns.dart';

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
  double? _dragStartLocalY; // Y position where drag started (for cell selection)
  int? _dragStartPageIndex; // Salva la pagina/giorno di partenza per drag evento

  // Returns the event that starts in the slot for the specified day and time, if it exists.
  CalendarEvent? _getEventForCell(DateTime day, int hour) {
    for (var event in events) {
      if (isSameDay(event.date, day) && event.hour == hour) {
        return event;
      }
    }
    return null;
  }

  // Show the dialog to add a new event
  void _onAddEvent(DateTime day, int startIndex, [int? endIndex]) {
    showAddEventDialog(
      context: context,
      day: day,
      startIndex: startIndex,
      endIndex: endIndex,
      hours: hours,
      events: events,
      onEventAdded: (CalendarEvent newEvent) {
        setState(() {
          events.add(newEvent);
        });
      },
    );
  }

  // Adjust the logic to calculate the correct start hour for events
  void _onEditEvent(CalendarEvent event) {
    showEditEventDialog(
      context: context,
      event: event,
      hours: hours,
      events: events,
      onEventUpdated: () {
        setState(() {});
      },
      onEventDeleted: (String eventId) {
        setState(() {
          events.removeWhere((e) => e.id == eventId || e.generatedBy == eventId);
        });
      },
    );
  }

  void _handleLongPressStart(int cellIndex, DateTime day) {
    setState(() {
      int safeIndex = cellIndex.clamp(0, hours.length - 1);
      CalendarEvent? event = _getEventForCell(day, hours[safeIndex]);
      if (event != null) {
        // Caso: drag su evento esistente
        _draggedEvent = event;
        _dragStartIndex = safeIndex;
        _dragEndIndex = safeIndex;
        _dragStartDay = day;
        _dragStartLocalY = null;
        _dragStartPageIndex = null; // verrà impostato nel primo move update
      } else {
        // Caso: drag su cella vuota
        _draggedEvent = null;
        _dragStartIndex = safeIndex;
        _dragEndIndex = safeIndex;
        _dragStartDay = day;
        _dragStartLocalY = null;
        _dragStartPageIndex = null;
      }
    });
  }

  void _handleLongPressMoveUpdate(LongPressMoveUpdateDetails details,
      BuildContext context, ScrollController scrollController, int pageIndex) {
    if (_dragStartIndex != null && _dragStartDay != null) {
      setState(() {
        RenderBox box = context.findRenderObject() as RenderBox;
        Offset localPosition = box.globalToLocal(details.globalPosition);

        double absoluteY = localPosition.dy + scrollController.offset;
        int hoveredIndex = (absoluteY / cellHeight).floor().clamp(0, hours.length - 1);

        if (_draggedEvent != null) {
          // Drag evento esistente: calcola nuovo giorno e ora
          if (_dragStartLocalY == null) {
            _dragStartLocalY = absoluteY;
          }
          if (_dragStartPageIndex == null) {
            _dragStartPageIndex = pageIndex;
          }

          // Calcola lo shift verticale (slot) e orizzontale (giorno)
          int deltaCells = ((absoluteY - _dragStartLocalY!) / cellHeight).round();
          int newStartIndex = (_dragStartIndex! + deltaCells).clamp(0, hours.length - 1);

          // Calcola il nuovo giorno in base allo spostamento di pagina
          int deltaDays = pageIndex - _dragStartPageIndex!;
          DateTime newDay = _dragStartDay!.add(Duration(days: deltaDays));

          int maxIndex = hours.length - (_draggedEvent!.endHour - _draggedEvent!.hour);
          newStartIndex = newStartIndex.clamp(0, maxIndex);

          int newStartHour = hours[newStartIndex];
          int eventDuration = _draggedEvent!.endHour - _draggedEvent!.hour;
          int newEndHour = newStartHour + eventDuration;

          if (getAvailableEndHours(newDay, newStartHour, _draggedEvent)
              .contains(newEndHour)) {
            _draggedEvent!.hour = newStartHour;
            _draggedEvent!.endHour = newEndHour;
            _draggedEvent!.date = newDay;

            // Ensure the relative position of overlapping events remains consistent
            List<CalendarEvent> overlappingEvents = events.where((e) {
              return isSameDay(e.date, newDay) &&
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
                generatorEvent.date = newDay;
              }
            }
          }
          _dragEndIndex = newStartIndex;
          _dragStartDay = newDay; // aggiorna il giorno per la visualizzazione
        } else {
          // Caso: selezione multipla per creazione evento
          // Salva la posizione iniziale del drag la prima volta che si entra qui
          if (_dragStartLocalY == null) {
            _dragStartLocalY = absoluteY;
          }
          // Calcola la differenza in celle tra la posizione iniziale e quella attuale
          int deltaCells = ((absoluteY - _dragStartLocalY!) / cellHeight).round();
          int newEndIndex = (_dragStartIndex! + deltaCells).clamp(0, hours.length - 1);
          _dragEndIndex = newEndIndex;
        }
      });
    }
  }

  void _handleLongPressEnd(DateTime day) {
    if (_dragStartIndex != null && _dragEndIndex != null) {
      if (_draggedEvent != null) {
        // Caso: fine drag di un evento esistente
        _handleDragEventMove(_draggedEvent!.date);
      } else {
        // Caso: fine selezione multipla per creazione evento
        if (_dragStartIndex != _dragEndIndex || isSameDay(_dragStartDay!, day)) {
          _handleDragEventCreation(day);
        }
      }
    }
    setState(() {
      _draggedEvent = null;
      _dragStartIndex = null;
      _dragEndIndex = null;
      _dragStartDay = null;
      _dragStartLocalY = null;
      _dragStartPageIndex = null;
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
        _onAddEvent(day, startSlot, endSlot);
      }

      // Regoliamo gli eventi sovrapposti dopo la creazione
      _adjustOverlappingEvents(day);

      // Reset degli indici di drag
      _dragStartIndex = null;
      _dragEndIndex = null;
    }
  }

  // Define the missing method to handle drag event movement
  void _handleDragEventMove(DateTime day) async {
    if (_draggedEvent != null &&
        _dragStartIndex != null &&
        _dragEndIndex != null) {
      int newStartIndex = _dragEndIndex!.clamp(0, hours.length - 1);
      int newStartHour = hours[newStartIndex];
      int eventDuration = _draggedEvent!.endHour - _draggedEvent!.hour;
      int newEndHour = newStartHour + eventDuration;

      setState(() {
        // Update the dragged event's start hour and day
        _draggedEvent!.hour = newStartHour;
        _draggedEvent!.endHour = newEndHour;
        _draggedEvent!.date = day;

        // Adjust overlapping events dynamically
        _adjustOverlappingEvents(day);
      });

      // Aggiorna su Firestore nel path corretto
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final eventDoc = FirebaseFirestore.instance
            .collection('users/${user.uid}/events')
            .doc(_draggedEvent!.id);
        final eventStart = DateTime(
          day.year, day.month, day.day,
          6 + (newStartHour ~/ 4),
          (newStartHour % 4) * 15,
        );
        final eventEnd = DateTime(
          day.year, day.month, day.day,
          6 + (newEndHour ~/ 4),
          (newEndHour % 4) * 15,
        );
        await eventDoc.update({
          'event_start': Timestamp.fromDate(eventStart),
          'event_end': Timestamp.fromDate(eventEnd),
        });
      }
    }
    _resetDragState(); // Reset the drag state
  }

  // Reset the drag state after handling the drag event
  void _resetDragState() {
    setState(() {
      if (_draggedEvent != null) {
        _draggedEvent!.isBeingDragged = false;
      }
    });
    _draggedEvent = null;
    _dragStartIndex = null;
    _dragEndIndex = null;
    _dragStartDay = null;
  }

  // Adjust overlapping events after creation or movement
  void _adjustOverlappingEvents(DateTime day) {
    List<CalendarEvent> dayEvents = events.where((e) => isSameDay(e.date, day)).toList();

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

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    // Determine the number of days to display based on screen width
    final int daysToShow =
        screenWidth > 600 ? 7 : 3; // 7 days for desktop, 3 days for mobile
    final PageController pageController = PageController(initialPage: 0);

    return Scaffold(
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
                  // _buildTimeColumn(),
                  CalendarTimeColumn(cellHeight: cellHeight),
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
                    ? getWeekDays(startDay, daysToShow)
                    : getDays(startDay, daysToShow);

                // Generate recurrent events for the visible days
                List<CalendarEvent> recurrentEvents =
                    generateRecurrentEvents(visibleDays,events);

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
                            !isSameDay(day, DateTime.now());
                        bool isToday = isSameDay(day, DateTime.now());
                        return Expanded(
                          child: Container(
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              color: isToday
                                  ? Colors.orangeAccent[400]
                                  : (isPastDay
                                      ? Colors.grey[300]
                                      : Colors.blue[100]),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Text(
                              formattedDay,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isToday
                                    ? Colors.white
                                    : (isPastDay ? Colors.grey[600] : Colors.black),
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
                              bool isPastDay = day.isBefore(DateTime.now()) && !isSameDay(day, DateTime.now());
                              return Expanded(
                                child: CalendarDayColumn(
                                  day: day,
                                  hours: hours,
                                  events: events,
                                  additionalEvents: recurrentEvents,
                                  cellHeight: cellHeight,
                                  draggedEvent: _draggedEvent,
                                  dragStartIndex: _dragStartIndex,
                                  dragEndIndex: _dragEndIndex,
                                  dragStartDay: _dragStartDay,
                                  onEditEvent: _onEditEvent,
                                  onAddEvent: _onAddEvent,
                                  onLongPressStart: _handleLongPressStart,
                                  onLongPressMoveUpdate: _handleLongPressMoveUpdate,
                                  onLongPressEnd: _handleLongPressEnd,
                                  scrollController: _dayColumnsController,
                                  pageIndex: pageIndex,
                                  isPastDay: isPastDay, // <--- AGGIUNGI QUESTA RIGA
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
          _onAddEvent(
              DateTime.now(), 0); // Default to current day and first hour
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add),
      ),
    );
  }
}
