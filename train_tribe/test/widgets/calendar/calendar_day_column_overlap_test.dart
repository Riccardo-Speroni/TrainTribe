import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/models/calendar_event.dart';
import 'package:train_tribe/widgets/calendar_widgets/calendar_columns.dart';

void main() {
  testWidgets('CalendarDayColumn renders three overlapping events', (tester) async {
    final day = DateTime.now();
    final events = [
      CalendarEvent(date: day, hour: 2, endHour: 6, departureStation: 'A', arrivalStation: 'B'),
      CalendarEvent(date: day, hour: 3, endHour: 5, departureStation: 'C', arrivalStation: 'D'),
      CalendarEvent(date: day, hour: 4, endHour: 6, departureStation: 'E', arrivalStation: 'F'),
    ];
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(size: Size(900, 800)), // wide triggers 7-day layout
        child: Scaffold(
          body: CalendarDayColumn(
            day: day,
            hours: List.generate(20, (i) => i),
            events: events,
            additionalEvents: const [],
            cellHeight: 8,
            draggedEvent: null,
            dragStartIndex: null,
            dragEndIndex: null,
            dragStartDay: null,
            onEditEvent: (_) {},
            onAddEvent: (_, __, [___]) {},
            onLongPressStart: (_, __) {},
            onLongPressMoveUpdate: (_, __, ___, ____) {},
            onLongPressEnd: (_) {},
            scrollController: ScrollController(),
            pageIndex: 0,
            isPastDay: false,
            isRailExpanded: false,
          ),
        ),
      ),
    ));

    expect(find.textContaining('A'), findsOneWidget);
    expect(find.textContaining('C'), findsOneWidget);
    expect(find.textContaining('E'), findsOneWidget);
  });
}
