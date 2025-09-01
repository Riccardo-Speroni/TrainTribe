import 'package:flutter/material.dart';
import '../../models/calendar_event.dart';

class CalendarEventWidget extends StatelessWidget {
  final double left;
  final double top;
  final double width;
  final double height;
  final CalendarEvent event;
  final bool isBeingDragged;
  final bool isPastDay;
  final double eventFontSize;
  final VoidCallback? onEditEvent;
  final VoidCallback? onLongPressStart;
  final Function(LongPressMoveUpdateDetails)? onLongPressMoveUpdate;
  final VoidCallback? onLongPressEnd;
  final BuildContext context;

  const CalendarEventWidget({
    super.key,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.event,
    required this.isBeingDragged,
    required this.isPastDay,
    required this.eventFontSize,
    this.onEditEvent,
    this.onLongPressStart,
    this.onLongPressMoveUpdate,
    this.onLongPressEnd,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: GestureDetector(
        onTap: onEditEvent,
        onLongPressStart: onLongPressStart != null ? (_) => onLongPressStart!() : null,
        onLongPressMoveUpdate: onLongPressMoveUpdate != null ? (details) => onLongPressMoveUpdate!(details) : null,
        onLongPressEnd: onLongPressEnd != null ? (_) => onLongPressEnd!() : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 50),
          margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
          decoration: BoxDecoration(
            color: isPastDay
                ? Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey
                : isBeingDragged
                    ? event.isRecurrent || event.generatedBy != null
                        ? Theme.of(context).brightness == Brightness.dark
                            ? Colors.deepPurpleAccent.withOpacity(0.7)
                            : Colors.purpleAccent.withOpacity(0.7)
                        : Theme.of(context).brightness == Brightness.dark
                            ? Theme.of(context).colorScheme.primary.withOpacity(0.7)
                            : Theme.of(context).colorScheme.primary.withOpacity(0.7)
                    : event.isRecurrent || event.generatedBy != null
                        ? Theme.of(context).brightness == Brightness.dark
                            ? Colors.deepPurpleAccent
                            : Colors.purpleAccent
                        : Theme.of(context).brightness == Brightness.dark
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(8.0),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.5),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '${event.departureStation}\n-\n${event.arrivalStation}',
              style: TextStyle(
                fontSize: eventFontSize,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
