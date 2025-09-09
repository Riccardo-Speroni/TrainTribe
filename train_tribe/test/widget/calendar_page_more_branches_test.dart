import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/calendar_page.dart';
import 'package:train_tribe/models/calendar_event.dart';
import 'package:train_tribe/utils/station_names.dart' as default_data;
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
  setUpAll(() async {
    await initializeDateFormatting('en');
  });

  group('CalendarPage extra branches', () {
    testWidgets('station names fallback loads default list in testMode', (tester) async {
      await tester.pumpWidget(_wrap(const CalendarPage(railExpanded: false, testMode: true)));
      await tester.pump();
      final state = tester.state<CalendarPageState>(find.byType(CalendarPage));
  // In testMode initState does not load stations automatically; invoke testing helper
  await state.loadDefaultStationsForTest();
  await tester.pump();
  expect(state.stationNamesForTest, isNotEmpty, reason: 'Should populate with default list');
  expect(state.stationNamesForTest.length, default_data.stationNames.length);
    });

    testWidgets('initialStationNames overrides default list', (tester) async {
      final custom = ['Alpha', 'Beta'];
      await tester.pumpWidget(_wrap(CalendarPage(railExpanded: false, testMode: true, initialStationNames: custom)));
      await tester.pump();
      final state = tester.state<CalendarPageState>(find.byType(CalendarPage));
      expect(state.stationNamesForTest, equals(custom));
    });

    testWidgets('header today vs future day colors differ', (tester) async {
      // Wide layout => 7 days including today + future days
      await tester.pumpWidget(_wrap(const MediaQuery(
        data: MediaQueryData(size: Size(1000, 800)),
        child: CalendarPage(railExpanded: false, testMode: true),
      )));
      await tester.pump();

      // Grab first Row that corresponds to headers (contains formatted day strings)
      final row = find.byType(Row).first;
      final dayTexts = find.descendant(of: row, matching: find.byType(Text));
      final colors = <Color?>{};
      for (final element in dayTexts.evaluate()) {
        final parent = element.findAncestorWidgetOfExactType<Container>();
        if (parent is Container) {
          final deco = parent.decoration;
          if (deco is BoxDecoration) {
            colors.add(deco.color);
          }
        }
      }
      expect(colors.length >= 2, isTrue, reason: 'Expect distinct color styles for today vs future days');
    });

    testWidgets('recurrent event copy returned by eventForCell on later day', (tester) async {
      await tester.pumpWidget(_wrap(const CalendarPage(railExpanded: false, testMode: true)));
      await tester.pump();
      final state = tester.state<CalendarPageState>(find.byType(CalendarPage));
      final today = DateTime.now();
      final generator = CalendarEvent(
        id: 'gen1',
        date: today,
        hour: 8,
        endHour: 12,
        departureStation: 'A',
        arrivalStation: 'B',
        isRecurrent: true,
        recurrenceEndDate: today.add(const Duration(days: 3)),
      );
      state.addTestEvent(generator);
      await tester.pump();
      final laterDay = today.add(const Duration(days: 2));
      final copy = state.eventForCell(laterDay, 8);
      expect(copy, isNotNull, reason: 'Should create a temporary recurrent copy');
      expect(copy!.generatedBy, equals('gen1'));
    });

    testWidgets('overlapping alignment recalculated after move', (tester) async {
      await tester.pumpWidget(_wrap(const CalendarPage(railExpanded: false, testMode: true)));
      await tester.pump();
      final state = tester.state<CalendarPageState>(find.byType(CalendarPage));
      final day = DateTime.now();
      final a = CalendarEvent(id: 'A', date: day, hour: 4, endHour: 12, departureStation: 'X', arrivalStation: 'Y');
      final b = CalendarEvent(id: 'B', date: day, hour: 6, endHour: 10, departureStation: 'X', arrivalStation: 'Y');
      final c = CalendarEvent(id: 'C', date: day, hour: 8, endHour: 16, departureStation: 'X', arrivalStation: 'Y');
      state.addTestEvents([a, b, c]);
      await tester.pump();
      state.adjustOverlappingForDay(day);
      // Expect widthFactor = 1/3 for all
      for (var e in [a, b, c]) {
        expect(e.widthFactor, closeTo(1/3, 0.0001));
      }
      // Simulate moving middle event earlier to change ordering
      state.simulateDragMove(b, day, 2); // new start slot earlier than a's start
      await tester.pump();
      // Recalculate expected width (still 1/3) but alignment order now may change
      final alignments = [a.alignment?.x, b.alignment?.x, c.alignment?.x];
      // All should be within [-1,1]
      for (var x in alignments) {
        expect(x != null && x >= -1.0 && x <= 1.0, isTrue);
      }
    });
  });
}
