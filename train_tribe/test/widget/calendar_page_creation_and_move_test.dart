import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/calendar_page.dart';
import 'package:train_tribe/models/calendar_event.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:train_tribe/l10n/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('it')],
      home: child,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async { await initializeDateFormatting('en'); });

  group('CalendarPage creation & move edge cases', () {
    testWidgets('creating single-slot event via simulateDragCreate adds event', (tester) async {
      await tester.pumpWidget(_wrap(const CalendarPage(railExpanded: false, testMode: true)));
      await tester.pump();
      final state = tester.state<CalendarPageState>(find.byType(CalendarPage));
      final day = DateTime.now();
  state.testSetDragIndices(day, 5, 5);
  final created = state.testCreateEventFromDrag(day);
  await tester.pump();
  expect(created, isNotNull);
  expect(created!.hour, 5);
  expect(created.endHour, 6); // endSlot = index+1
    });

    testWidgets('simulateDragMove ignores event not in list', (tester) async {
      await tester.pumpWidget(_wrap(const CalendarPage(railExpanded: false, testMode: true)));
      await tester.pump();
      final state = tester.state<CalendarPageState>(find.byType(CalendarPage));
      final ghost = CalendarEvent(id: 'ghost', date: DateTime.now(), hour: 4, endHour: 8, departureStation: 'A', arrivalStation: 'B');
      state.simulateDragMove(ghost, DateTime.now(), 10); // should no-op
      await tester.pump();
      expect(state.events, isEmpty);
    });

    testWidgets('drag creation with inverted indices swaps correctly', (tester) async {
      await tester.pumpWidget(_wrap(const CalendarPage(railExpanded: false, testMode: true)));
      await tester.pump();
      final state = tester.state<CalendarPageState>(find.byType(CalendarPage));
      final day = DateTime.now();
      // set indices reversed then trigger creation
  state.testSetDragIndices(day, 12, 8);
  final created = state.testCreateEventFromDrag(day);
  await tester.pump();
  expect(created, isNotNull);
  expect(created!.hour, 8);
  expect(created.endHour, 13); // end index (12) +1 -> 13
    });

    testWidgets('drag move respects event duration and clamps inside bounds', (tester) async {
      await tester.pumpWidget(_wrap(const CalendarPage(railExpanded: false, testMode: true)));
      await tester.pump();
      final state = tester.state<CalendarPageState>(find.byType(CalendarPage));
      final day = DateTime.now();
      final evt = CalendarEvent(id: 'evt', date: day, hour: 70, endHour: 75, departureStation: 'A', arrivalStation: 'B');
      state.addTestEvent(evt);
      await tester.pump();
      // attempt to move event beyond max slots
  state.simulateDragMove(evt, day, 90); // beyond bounds triggers clamp
  await tester.pump();
  expect(evt.endHour <= 76, isTrue, reason: 'End hour clamped to max');
  expect(evt.hour >= 0, isTrue);
    });
  });
}
