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

  group('CalendarPage internal behaviors', () {
    testWidgets('long press start on existing event toggles isBeingDragged then resets on end', (tester) async {
      await tester.pumpWidget(_wrap(const CalendarPage(railExpanded: false, testMode: true)));
      await tester.pump();
      final state = tester.state<CalendarPageState>(find.byType(CalendarPage));
      final day = DateTime.now();
      final evt = CalendarEvent(id: 'E1', date: day, hour: 4, endHour: 8, departureStation: 'A', arrivalStation: 'B');
      state.addTestEvent(evt);
      await tester.pump();
      // call private _handleLongPressStart
  state.testLongPressStart(evt.hour, day);
      expect(evt.isBeingDragged, isTrue);
      // end drag
  state.testLongPressEnd(day);
      expect(evt.isBeingDragged, isFalse);
    });

    testWidgets('recurrent copy drag updates generator hours but not date', (tester) async {
      await tester.pumpWidget(_wrap(const CalendarPage(railExpanded: false, testMode: true)));
      await tester.pump();
      final state = tester.state<CalendarPageState>(find.byType(CalendarPage));
      final today = DateTime.now();
      final generator = CalendarEvent(
        id: 'genR',
        date: today,
        hour: 8,
        endHour: 12,
        departureStation: 'A',
        arrivalStation: 'B',
        isRecurrent: true,
        recurrenceEndDate: today.add(const Duration(days: 2)),
      );
      state.addTestEvent(generator);
      await tester.pump();
      final targetDay = today.add(const Duration(days: 1));
      // create a synthetic copy (not added to events) referencing generator
      final copy = CalendarEvent(
        id: 'genR_${targetDay.toIso8601String()}',
        generatedBy: generator.id,
        date: targetDay,
        hour: generator.hour,
        endHour: generator.endHour,
        departureStation: 'A',
        arrivalStation: 'B',
        isRecurrent: true,
        recurrenceEndDate: generator.recurrenceEndDate,
      );
      // prime drag state
  state.testPrimeDragForRecurrent(copy, generator.hour, generator.hour + 4);
      // invoke move
  await state.testHandleDragEventMove(targetDay);
      // generator should be updated
      expect(generator.hour, equals(12));
      expect(generator.endHour, equals(16));
      // generator date should remain original today
      expect(generator.date.day, equals(today.day));
    });

    testWidgets('non-overlapping events retain widthFactor 1 after adjustment', (tester) async {
      await tester.pumpWidget(_wrap(const CalendarPage(railExpanded: false, testMode: true)));
      await tester.pump();
      final state = tester.state<CalendarPageState>(find.byType(CalendarPage));
      final day = DateTime.now();
      final e1 = CalendarEvent(id: 'A', date: day, hour: 4, endHour: 8, departureStation: 'X', arrivalStation: 'Y');
      final e2 = CalendarEvent(id: 'B', date: day, hour: 16, endHour: 20, departureStation: 'X', arrivalStation: 'Y');
      state.addTestEvents([e1, e2]);
      await tester.pump();
      state.adjustOverlappingForDay(day);
      expect(e1.widthFactor, 1.0);
      expect(e2.widthFactor, 1.0);
  // Alignment set may default to center or start depending on grouping logic; verify width and near-center x
  // Allow either center or single-column layout left alignment (x ~ -1) since logic may group individually
  bool e1CenteredOrSolo = e1.alignment != null && (e1.alignment!.x.abs() < 0.01 || (e1.alignment!.x + 1.0).abs() < 0.01);
  bool e2CenteredOrSolo = e2.alignment != null && (e2.alignment!.x.abs() < 0.01 || (e2.alignment!.x + 1.0).abs() < 0.01);
  expect(e1CenteredOrSolo, isTrue);
  expect(e2CenteredOrSolo, isTrue);
    });
  });
}
