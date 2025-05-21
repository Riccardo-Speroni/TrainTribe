import 'package:flutter/material.dart';
import '../models/calendar_event.dart';
import 'calendar_cells.dart';
import '../utils/calendar_functions.dart';

class CalendarDayColumn extends StatelessWidget {
  final DateTime day;
  final List<int> hours;
  final List<CalendarEvent> events;
  final List<CalendarEvent>? additionalEvents;
  final double cellHeight;
  final CalendarEvent? draggedEvent;
  final int? dragStartIndex;
  final int? dragEndIndex;
  final DateTime? dragStartDay;
  final void Function(CalendarEvent) onEditEvent;
  final void Function(DateTime, int, [int?]) onAddEvent;
  final void Function(int, DateTime) onLongPressStart;
  final void Function(LongPressMoveUpdateDetails, BuildContext, ScrollController, int) onLongPressMoveUpdate;
  final void Function(DateTime) onLongPressEnd;
  final ScrollController scrollController;
  final int pageIndex;

  const CalendarDayColumn({
    super.key,
    required this.day,
    required this.hours,
    required this.events,
    this.additionalEvents,
    required this.cellHeight,
    required this.draggedEvent,
    required this.dragStartIndex,
    required this.dragEndIndex,
    required this.dragStartDay,
    required this.onEditEvent,
    required this.onAddEvent,
    required this.onLongPressStart,
    required this.onLongPressMoveUpdate,
    required this.onLongPressEnd,
    required this.scrollController,
    required this.pageIndex,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> cells = [];
    List<Widget> eventWidgets = [];
    int index = 0;

    int daysToShow = MediaQuery.of(context).size.width > 600 ? 7 : 3;
    double cellWidth = MediaQuery.of(context).size.width / daysToShow;

    List<CalendarEvent> dayEvents = events
        .where((event) => isSameDay(event.date, day))
        .toList();

    if (additionalEvents != null) {
      dayEvents.addAll(additionalEvents!
          .where((event) => isSameDay(event.date, day))
          .toList());
    }

    dayEvents.sort((a, b) => a.hour.compareTo(b.hour));

    while (index < hours.length) {
      int currentHour = hours[index];
      CalendarEvent? event = dayEvents.cast<CalendarEvent?>().firstWhere(
          (e) => e?.hour == currentHour && isSameDay(e!.date, day),
          orElse: () => null);

      bool hasEvent = event != null;

      // Se c'è un evento in questo slot, la cella vuota non deve ricevere gesture
      Widget emptyCell = IgnorePointer(
        ignoring: hasEvent,
        child: CalendarEmptyCell(
          cellIndex: index,
          day: day,
          cellHeight: cellHeight,
          dragStartIndex: dragStartIndex,
          dragEndIndex: dragEndIndex,
          dragStartDay: dragStartDay,
          draggedEvent: draggedEvent,
          onAddEvent: onAddEvent,
          onLongPressStart: onLongPressStart,
          onLongPressMoveUpdate: onLongPressMoveUpdate,
          onLongPressEnd: onLongPressEnd,
          scrollController: scrollController,
          pageIndex: pageIndex,
        ),
      );
      cells.add(emptyCell);

      if (event != null) {
        List<CalendarEvent> overlappingEvents = dayEvents.where((e) {
          return (e.hour < event.endHour && e.endHour > event.hour);
        }).toList();

        int totalOverlapping = overlappingEvents.isNotEmpty ? overlappingEvents.length : 1;
        int correctionFactor = MediaQuery.of(context).size.width > 600 ? 12 : 30;
        double widthFactor = (cellWidth - correctionFactor) / totalOverlapping;

        for (int i = 0; i < overlappingEvents.length; i++) {
          CalendarEvent overlappingEvent = overlappingEvents[i];
          bool isBeingDragged = draggedEvent == overlappingEvent;

          // Calcola l'indice di inizio slot per l'evento
          int eventStartIndex = overlappingEvent.hour - hours.first;

          eventWidgets.add(
            Positioned(
              left: widthFactor * i,
              top: cellHeight * (overlappingEvent.hour - hours.first),
              width: widthFactor,
              height: cellHeight * (overlappingEvent.endHour - overlappingEvent.hour),
              child: GestureDetector(
                onTap: () => onEditEvent(overlappingEvent),
                onLongPressStart: (_) => onLongPressStart(eventStartIndex, day),
                onLongPressMoveUpdate: (details) => onLongPressMoveUpdate(
                    details, context, scrollController, pageIndex),
                onLongPressEnd: (_) => onLongPressEnd(day),
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

        for (int i = 1; i < event.endHour - event.hour; i++) {
          cells.add(CalendarEmptyCell(
            cellIndex: index + i,
            day: day,
            cellHeight: cellHeight,
            dragStartIndex: dragStartIndex,
            dragEndIndex: dragEndIndex,
            dragStartDay: dragStartDay,
            draggedEvent: draggedEvent,
            onAddEvent: onAddEvent,
            onLongPressStart: onLongPressStart,
            onLongPressMoveUpdate: onLongPressMoveUpdate,
            onLongPressEnd: onLongPressEnd,
            scrollController: scrollController,
            pageIndex: pageIndex,
          ));
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
}

class CalendarTimeColumn extends StatelessWidget {
  final double cellHeight;
  const CalendarTimeColumn({super.key, required this.cellHeight});

  @override
  Widget build(BuildContext context) {
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
}
