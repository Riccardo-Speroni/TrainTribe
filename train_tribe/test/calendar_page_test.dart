import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/calendar_page.dart';
import 'package:train_tribe/models/calendar_event.dart';
import 'package:train_tribe/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  group('CalendarPage logic (testMode)', () {
    testWidgets('eventForCell finds direct event', (tester) async {
      const key = ValueKey('calendarPageTest');
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('it')],
        home: const CalendarPage(key: key, railExpanded: false, testMode: true),
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(key), findsOneWidget);
      final state = tester.state<CalendarPageState>(find.byKey(key));
      final day = DateTime.now();
      final e = CalendarEvent(
        id: 'e',
        generatedBy: null,
        date: DateTime(day.year, day.month, day.day),
        hour: 2,
        endHour: 4,
        departureStation: 'X',
        arrivalStation: 'Y',
        isRecurrent: false,
      );
      state.addTestEvent(e);
      expect(state.eventForCell(day, 2), e);
    });

    testWidgets('eventForCell returns recurrent copy for next day', (tester) async {
      const key = ValueKey('calendarPageTest2');
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('it')],
        home: const CalendarPage(key: key, railExpanded: false, testMode: true),
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(key), findsOneWidget);
      final state = tester.state<CalendarPageState>(find.byKey(key));
      final base = DateTime.now();
      final r = CalendarEvent(
        id: 'r1',
        generatedBy: null,
        date: DateTime(base.year, base.month, base.day),
        hour: 6,
        endHour: 8,
        departureStation: 'A',
        arrivalStation: 'B',
        isRecurrent: true,
        recurrenceEndDate: base.add(const Duration(days: 2)),
      );
      state.addTestEvent(r);
      final copy = state.eventForCell(base.add(const Duration(days: 1)), 6);
      expect(copy, isNotNull);
      expect(copy!.generatedBy, isNotNull);
      expect(copy.hour, 6);
    });

    testWidgets('overlapping events adjust width/alignment', (tester) async {
      const key = ValueKey('calendarPageTest3');
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('it')],
        home: const CalendarPage(key: key, railExpanded: false, testMode: true),
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(key), findsOneWidget);
      final state = tester.state<CalendarPageState>(find.byKey(key));
      final d = DateTime.now();
      final a = CalendarEvent(
        id: 'a',
        generatedBy: null,
        date: DateTime(d.year, d.month, d.day),
        hour: 10,
        endHour: 13,
        departureStation: 'S',
        arrivalStation: 'T',
        isRecurrent: false,
      );
      final b = CalendarEvent(
        id: 'b',
        generatedBy: null,
        date: DateTime(d.year, d.month, d.day),
        hour: 11,
        endHour: 12,
        departureStation: 'S',
        arrivalStation: 'U',
        isRecurrent: false,
      );
      state.addTestEvents([a, b]);
      state.adjustOverlappingForDay(d);
      expect(a.widthFactor, closeTo(0.5, 0.01));
      expect(b.widthFactor, closeTo(0.5, 0.01));
      expect(a.alignment!.x != b.alignment!.x, isTrue);
    });

    testWidgets('overlapping chain A-B-C keeps earlier width after later recalculation (current behavior)', (tester) async {
      const key = ValueKey('calendarPageChain');
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('it')],
        home: const CalendarPage(key: key, railExpanded: false, testMode: true),
      ));
      await tester.pumpAndSettle();
      final state = tester.state<CalendarPageState>(find.byKey(key));
      final d = DateTime(2025, 1, 1);
      final a = CalendarEvent(date: d, hour: 16, endHour: 24, departureStation: 'A', arrivalStation: 'B');
      final b = CalendarEvent(date: d, hour: 20, endHour: 28, departureStation: 'A', arrivalStation: 'B');
      final c = CalendarEvent(date: d, hour: 24, endHour: 32, departureStation: 'A', arrivalStation: 'B');
      state.addTestEvents([a, b, c]);
      state.adjustOverlappingForDay(d);
      // Document current algorithm outcome: A width may become 1/3 after B loop; B & C last recalculation to 1/2.
      expect(a.widthFactor, isNotNull);
      expect(b.widthFactor, isNotNull);
      expect(c.widthFactor, isNotNull);
      // Allow small tolerance; A should be narrower than B & C.
      expect(a.widthFactor! <= b.widthFactor!, isTrue);
      expect(b.widthFactor, closeTo(0.5, 0.01));
      expect(c.widthFactor, closeTo(0.5, 0.01));
    });

    testWidgets('station names injected via initialStationNames in testMode', (tester) async {
      const key = ValueKey('calendarPageStations');
      final injected = ['StationOne', 'StationTwo'];
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('it')],
        home: CalendarPage(key: key, railExpanded: false, testMode: true, initialStationNames: injected),
      ));
      await tester.pumpAndSettle();
      final state = tester.state<CalendarPageState>(find.byKey(key));
      expect(state.stationNamesForTest, injected);
    });
  });
}
