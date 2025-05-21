import 'package:flutter/material.dart';
import '../models/calendar_event.dart';
import '../utils/calendar_functions.dart';

class CalendarEmptyCell extends StatelessWidget {
  final int cellIndex;
  final DateTime day;
  final double cellHeight;
  final int? dragStartIndex;
  final int? dragEndIndex;
  final DateTime? dragStartDay;
  final CalendarEvent? draggedEvent;
  final void Function(DateTime, int) onAddEvent;
  final void Function(int, DateTime) onLongPressStart;
  final void Function(LongPressMoveUpdateDetails, BuildContext, ScrollController, int) onLongPressMoveUpdate;
  final void Function(DateTime) onLongPressEnd;
  final ScrollController scrollController;
  final int pageIndex;

  const CalendarEmptyCell({
    super.key,
    required this.cellIndex,
    required this.day,
    required this.cellHeight,
    required this.dragStartIndex,
    required this.dragEndIndex,
    required this.dragStartDay,
    required this.draggedEvent,
    required this.onAddEvent,
    required this.onLongPressStart,
    required this.onLongPressMoveUpdate,
    required this.onLongPressEnd,
    required this.scrollController,
    required this.pageIndex,
  });

  @override
  Widget build(BuildContext context) {
    if (day.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      return Container(
        height: cellHeight,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(4.0),
          color: Colors.transparent,
        ),
      );
    }

    bool isHighlighted = dragStartIndex != null &&
        dragEndIndex != null &&
        dragStartDay != null &&
        isSameDay(dragStartDay!, day) &&
        draggedEvent == null &&
        ((cellIndex >= dragStartIndex! && cellIndex <= dragEndIndex!) ||
            (cellIndex <= dragStartIndex! && cellIndex >= dragEndIndex!));

    return GestureDetector(
      onTap: () => onAddEvent(day, cellIndex),
      onLongPressStart: (_) => onLongPressStart(cellIndex, day),
      onLongPressMoveUpdate: (details) => onLongPressMoveUpdate(
          details, context, scrollController, pageIndex),
      onLongPressEnd: (_) => onLongPressEnd(day),
      child: Container(
        height: cellHeight,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(4.0),
          color: isHighlighted ? Colors.blue.withOpacity(0.7) : Colors.transparent,
        ),
      ),
    );
  }
}
