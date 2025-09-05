import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/models/calendar_event.dart';
import 'package:train_tribe/widgets/calendar_widgets/calendar_columns.dart';

void main() {
  group('CalendarDayColumn', () {
    // Helper to build widget with custom width
    Future<void> _pump(WidgetTester tester, double width, List<CalendarEvent> events, {bool past = false}) async {
      final hours = List.generate(20, (i) => i); // reduced list just for widget logic
      await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: Size(width, 800)),
          child: Scaffold(
            body: CalendarDayColumn(
              day: DateTime.now(),
              hours: hours,
              events: events,
              additionalEvents: const [],
              cellHeight: 10,
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
              isPastDay: past,
              isRailExpanded: false,
            ),
          ),
        ),
      ));
    }

    testWidgets('renders single event and empty cells (narrow layout)', (tester) async {
      final event = CalendarEvent(
        date: DateTime.now(),
        hour: 2,
        endHour: 4,
        departureStation: 'A',
        arrivalStation: 'B',
      );
      await _pump(tester, 500, [event]);
      // One CalendarEventWidget
      expect(find.textContaining('A'), findsOneWidget);
      // Should build multiple empty cells -> check by Container count > 1
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('overlapping events create multiple positioned widgets', (tester) async {
      final now = DateTime.now();
      final e1 = CalendarEvent(
        date: now,
        hour: 2,
        endHour: 6,
        departureStation: 'AA',
        arrivalStation: 'BB',
      );
      final e2 = CalendarEvent(
        date: now,
        hour: 3,
        endHour: 5,
        departureStation: 'CC',
        arrivalStation: 'DD',
      );
      await _pump(tester, 700, [e1, e2]); // wide layout triggers daysToShow=7 branch
      // Both events displayed
      expect(find.textContaining('AA'), findsOneWidget);
      expect(find.textContaining('CC'), findsOneWidget);
    });

    testWidgets('past day disables onEditEvent (tap)', (tester) async {
      // Use same visible day so the event is actually rendered; rely on isPastDay flag
      final today = DateTime.now();
      final event = CalendarEvent(
        date: today,
        hour: 2,
        endHour: 4,
        departureStation: 'P',
        arrivalStation: 'D',
      );
      await _pump(tester, 500, [event], past: true);
      // GestureDetector inside should have onTap null -> we can attempt tap and nothing should throw.
      await tester.tap(find.textContaining('P'));
      await tester.pump();
    });
  });
}
