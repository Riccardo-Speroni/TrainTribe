import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/models/calendar_event.dart';
import 'package:train_tribe/widgets/calendar_widgets/calendar_event_widget.dart';

void main() {
  group('CalendarEventWidget', () {
    testWidgets('renders basic event text', (tester) async {
      final event = CalendarEvent(
        date: DateTime.now(),
        hour: 4,
        endHour: 8,
        departureStation: 'MIL',
        arrivalStation: 'ROM',
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(builder: (context) {
            return Stack(children: [
              CalendarEventWidget(
                left: 0,
                top: 0,
                width: 120,
                height: 100,
                event: event,
                isBeingDragged: false,
                isPastDay: false,
                eventFontSize: 12,
                context: context,
              ),
            ]);
          }),
        ),
      ));

      expect(find.textContaining('MIL'), findsOneWidget);
      expect(find.textContaining('ROM'), findsOneWidget);
      // Ensure Positioned + AnimatedContainer exist
      expect(find.byType(AnimatedContainer), findsOneWidget);
    });

    testWidgets('applies recurrent color (light theme)', (tester) async {
      final event = CalendarEvent(
        date: DateTime.now(),
        hour: 4,
        endHour: 8,
        departureStation: 'AAA',
        arrivalStation: 'BBB',
        isRecurrent: true,
        recurrenceEndDate: DateTime.now().add(const Duration(days: 30)),
      );

      await tester.pumpWidget(MaterialApp(
        theme: ThemeData.light(),
        home: Scaffold(
          body: Builder(builder: (context) {
            return Stack(children: [
              CalendarEventWidget(
                left: 0,
                top: 0,
                width: 120,
                height: 100,
                event: event,
                isBeingDragged: false,
                isPastDay: false,
                eventFontSize: 12,
                context: context,
              ),
            ]);
          }),
        ),
      ));

      final animated = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
      final decoration = animated.decoration as BoxDecoration;
      expect(decoration.color, equals(Colors.purpleAccent));
    });

    testWidgets('applies dragged recurrent color with alpha (dark theme)', (tester) async {
      final event = CalendarEvent(
        date: DateTime.now(),
        hour: 4,
        endHour: 6,
        departureStation: 'X',
        arrivalStation: 'Y',
        isRecurrent: true,
        recurrenceEndDate: DateTime.now().add(const Duration(days: 7)),
      );

      await tester.pumpWidget(MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: Builder(builder: (context) {
            return Stack(children: [
              CalendarEventWidget(
                left: 0,
                top: 0,
                width: 120,
                height: 80,
                event: event,
                isBeingDragged: true,
                isPastDay: false,
                eventFontSize: 10,
                context: context,
              ),
            ]);
          }),
        ),
      ));

      final animated = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
      final decoration = animated.decoration as BoxDecoration;
      // deepPurpleAccent.withValues(alpha: 0.7) -> compare alpha & value
      expect(decoration.color!.alpha, closeTo(0.7 * 255, 1));
      expect(decoration.color!.red, equals(Colors.deepPurpleAccent.red));
    });

    testWidgets('past day uses grey color', (tester) async {
      final event = CalendarEvent(
        date: DateTime.now().subtract(const Duration(days: 2)),
        hour: 4,
        endHour: 5,
        departureStation: 'OLD',
        arrivalStation: 'NOW',
      );

      await tester.pumpWidget(MaterialApp(
        theme: ThemeData.light(),
        home: Scaffold(
          body: Builder(builder: (context) {
            return Stack(children: [
              CalendarEventWidget(
                left: 0,
                top: 0,
                width: 120,
                height: 60,
                event: event,
                isBeingDragged: false,
                isPastDay: true,
                eventFontSize: 12,
                context: context,
              ),
            ]);
          }),
        ),
      ));

      final animated = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
      final decoration = animated.decoration as BoxDecoration;
      expect(decoration.color, equals(Colors.grey));
    });
  });
}
