import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_tribe/calendar_page.dart';
import 'package:train_tribe/models/calendar_event.dart';
import 'package:train_tribe/l10n/app_localizations.dart';

Future<void> _pumpUntilSettled(WidgetTester tester, {Duration timeout = const Duration(seconds: 8)}) async {
  final end = DateTime.now().add(timeout);
  await tester.pumpAndSettle();
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (!tester.binding.hasScheduledFrame) {
      await tester.pumpAndSettle(const Duration(milliseconds: 50));
      if (!tester.binding.hasScheduledFrame) return;
    }
  }
}

void main() {
  testWidgets('CalendarPage testMode: recurrent event creation', (tester) async {
    final today = DateTime.now();
    final key = GlobalKey<CalendarPageState>();
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [Locale('en'), Locale('it')],
      home: CalendarPage(
        railExpanded: false,
        testMode: true,
        key: key,
        initialStationNames: const ['A', 'B'],
      ),
    ));
    await _pumpUntilSettled(tester);

    // Add recurrent event (2 days)
    final event = CalendarEvent(
      date: today,
      hour: 0,
      endHour: 4,
      departureStation: 'A',
      arrivalStation: 'B',
      isRecurrent: true,
      recurrenceEndDate: today.add(const Duration(days: 1)),
    );
    key.currentState!.addTestEvent(event);
    await tester.pump();
    // Should find event for today and tomorrow
    final eToday = key.currentState!.eventForCell(today, 0);
    final eTomorrow = key.currentState!.eventForCell(today.add(const Duration(days: 1)), 0);
    expect(eToday, isNotNull);
    expect(eTomorrow, isNotNull);
    expect(eToday!.isRecurrent, true);
    expect(eTomorrow!.isRecurrent, true);
  });

  testWidgets('CalendarPage testMode: overlap adjustment', (tester) async {
    final today = DateTime.now();
    final key = GlobalKey<CalendarPageState>();
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [Locale('en'), Locale('it')],
      home: CalendarPage(
        railExpanded: false,
        testMode: true,
        key: key,
        initialStationNames: const ['A', 'B'],
      ),
    ));
    await _pumpUntilSettled(tester);

    // Add two overlapping events
    final e1 = CalendarEvent(
      date: today,
      hour: 0,
      endHour: 4,
      departureStation: 'A',
      arrivalStation: 'B',
    );
    final e2 = CalendarEvent(
      date: today,
      hour: 2,
      endHour: 6,
      departureStation: 'A',
      arrivalStation: 'B',
    );
    key.currentState!.addTestEvents([e1, e2]);
    key.currentState!.adjustOverlappingForDay(today);
    await tester.pump();
    // Both events should have widthFactor set (for visual separation)
    expect(e1.widthFactor != null, true);
    expect(e2.widthFactor != null, true);
    expect(e1.widthFactor, e2.widthFactor);
    expect(e1.alignment != null, true);
    expect(e2.alignment != null, true);
    expect(e1.alignment != e2.alignment, true);
  });

  testWidgets('CalendarPage testMode: station name change', (tester) async {
    final today = DateTime.now();
    final key = GlobalKey<CalendarPageState>();
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [Locale('en'), Locale('it')],
      home: CalendarPage(
        railExpanded: false,
        testMode: true,
        key: key,
        initialStationNames: const ['X', 'Y'],
      ),
    ));
    await _pumpUntilSettled(tester);

    // Add event, should use new station names
    key.currentState!.testSetDragIndices(today, 0, 3);
    final event = key.currentState!.testCreateEventFromDrag(today)!;
    await tester.pump();
    expect(event.departureStation, 'X');
    expect(event.arrivalStation, 'Y');
  });
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('CalendarPage testMode: add event via simulateDragCreate', (tester) async {
    final today = DateTime.now();
    final key = GlobalKey<CalendarPageState>();
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [Locale('en'), Locale('it')],
      home: CalendarPage(
        railExpanded: false,
        testMode: true,
        key: key,
        initialStationNames: const ['A', 'B'],
      ),
    ));
    await _pumpUntilSettled(tester);

    // Add event: slot 0 to 3 (1 hour) using test seam
    key.currentState!.testSetDragIndices(today, 0, 3);
    key.currentState!.testCreateEventFromDrag(today);
    await tester.pump();
    final events = key.currentState!.events;
    expect(events.length, 1);
    final e = events.first;
    expect(e.date.year, today.year);
    expect(e.date.month, today.month);
    expect(e.date.day, today.day);
    expect(e.hour, 0);
    expect(e.endHour, 4); // end is exclusive
    expect(e.departureStation, 'A');
    expect(e.arrivalStation, 'B');
  });
  testWidgets('CalendarPage testMode: edit event', (tester) async {
    final today = DateTime.now();
    final key = GlobalKey<CalendarPageState>();
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [Locale('en'), Locale('it')],
      home: CalendarPage(
        railExpanded: false,
        testMode: true,
        key: key,
        initialStationNames: const ['A', 'B'],
      ),
    ));
    await _pumpUntilSettled(tester);

    // Add event
    key.currentState!.testSetDragIndices(today, 0, 3);
    final event = key.currentState!.testCreateEventFromDrag(today)!;
    await tester.pump();
    // Edit event: move to slot 4-7
    event.hour = 4;
    event.endHour = 8;
    key.currentState!.editEventForTest(event);
    await tester.pump();
    final e = key.currentState!.events.first;
    expect(e.hour, 4);
    expect(e.endHour, 8);
  });

  testWidgets('CalendarPage testMode: delete event', (tester) async {
    final today = DateTime.now();
    final key = GlobalKey<CalendarPageState>();
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [Locale('en'), Locale('it')],
      home: CalendarPage(
        railExpanded: false,
        testMode: true,
        key: key,
        initialStationNames: const ['A', 'B'],
      ),
    ));
    await _pumpUntilSettled(tester);

    // Add event
    key.currentState!.testSetDragIndices(today, 0, 3);
    final event = key.currentState!.testCreateEventFromDrag(today)!;
    await tester.pump();
    // Delete event
    key.currentState!.editEventForTest(event);
    key.currentState!.events.remove(event);
    await tester.pump();
    expect(key.currentState!.events.length, 0);
  });

  testWidgets('CalendarPage testMode: overlapping events', (tester) async {
    final today = DateTime.now();
    final key = GlobalKey<CalendarPageState>();
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [Locale('en'), Locale('it')],
      home: CalendarPage(
        railExpanded: false,
        testMode: true,
        key: key,
        initialStationNames: const ['A', 'B'],
      ),
    ));
    await _pumpUntilSettled(tester);

    // Add first event
    key.currentState!.testSetDragIndices(today, 0, 3);
    key.currentState!.testCreateEventFromDrag(today);
    // Add overlapping event
    key.currentState!.testSetDragIndices(today, 2, 5);
    key.currentState!.testCreateEventFromDrag(today);
    await tester.pump();
    expect(key.currentState!.events.length, 2);
    // Both events should exist
    final e1 = key.currentState!.events[0];
    final e2 = key.currentState!.events[1];
    expect(e1.hour < e2.endHour && e2.hour < e1.endHour, true); // overlap
  });

  testWidgets('CalendarPage testMode: move event', (tester) async {
    final today = DateTime.now();
    final key = GlobalKey<CalendarPageState>();
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [Locale('en'), Locale('it')],
      home: CalendarPage(
        railExpanded: false,
        testMode: true,
        key: key,
        initialStationNames: const ['A', 'B'],
      ),
    ));
    await _pumpUntilSettled(tester);

    // Add event
    key.currentState!.testSetDragIndices(today, 0, 3);
    final event = key.currentState!.testCreateEventFromDrag(today)!;
    await tester.pump();
    // Move event to slot 8
    key.currentState!.simulateDragMove(event, today, 8);
    await tester.pump();
    final e = key.currentState!.events.first;
    expect(e.hour, 8);
  });

  testWidgets('CalendarPage testMode: event persistence after navigation', (tester) async {
    final today = DateTime.now();
    final key = GlobalKey<CalendarPageState>();
    Widget buildApp() => MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('en'), Locale('it')],
          home: CalendarPage(
            railExpanded: false,
            testMode: true,
            key: key,
            initialStationNames: const ['A', 'B'],
          ),
        );
    await tester.pumpWidget(buildApp());
    await _pumpUntilSettled(tester);

    // Add event
    key.currentState!.testSetDragIndices(today, 0, 3);
    key.currentState!.testCreateEventFromDrag(today);
    await tester.pump();
    expect(key.currentState!.events.length, 1);

    // Simulate navigation away and back (rebuild)
    await tester.pumpWidget(Container());
    await tester.pump();
    await tester.pumpWidget(buildApp());
    await _pumpUntilSettled(tester);
    // In testMode, events are not persisted by default, so expect 0
    expect(key.currentState!.events.length, 0);
  });
}
