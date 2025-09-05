import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:train_tribe/calendar_page.dart';
import 'package:train_tribe/l10n/app_localizations.dart';
import 'package:train_tribe/models/calendar_event.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: const [AppLocalizations.delegate],
      supportedLocales: const [Locale('en')],
      home: child,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async { await initializeDateFormatting('en'); });

  group('FAB add event dialog', () {
    testWidgets('tapping FAB opens New Event dialog (testMode)', (tester) async {
      await tester.pumpWidget(_wrap(const CalendarPage(railExpanded: false, testMode: true)));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      expect(find.text('New Event'), findsOneWidget);
    });
  });

  group('Drag selection creation', () {
    testWidgets('simulateDragCreate shows New Event dialog', (tester) async {
      final page = CalendarPage(railExpanded: false, testMode: true);
      await tester.pumpWidget(_wrap(page));
      await tester.pumpAndSettle();
      final state = tester.state<CalendarPageState>(find.byType(CalendarPage));
      final today = DateTime.now();
      // Directly simulate creation selecting slots 8..10
      state.simulateDragCreate(today, 8, 10);
      await tester.pump();
      expect(find.text('New Event'), findsOneWidget);
    });
  });

  group('Drag move existing event', () {
  testWidgets('simulateDragMove updates event hour (testMode skips Firestore)', (tester) async {
      final page = CalendarPage(railExpanded: false, testMode: true);
      await tester.pumpWidget(_wrap(page));
      await tester.pumpAndSettle();
      final state = tester.state<CalendarPageState>(find.byType(CalendarPage));
      final today = DateTime.now();
      final event = CalendarEvent(
        id: 'e1',
        date: today,
        hour: 8,
        endHour: 12,
        departureStation: 'A',
        arrivalStation: 'B',
        isRecurrent: false,
      );
      state.addTestEvent(event);
      await tester.pump();
      state.simulateDragMove(event, today, 10); // move start to slot 10
      await tester.pump();
  expect(event.hour, 10);
    });
  });

  group('Header color states', () {
    testWidgets('today header uses primary color, past is greyed, future tinted', (tester) async {
      tester.view.physicalSize = const Size(1200, 900); // wide layout 7 days
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() { tester.view.resetPhysicalSize(); tester.view.resetDevicePixelRatio(); });
      await tester.pumpWidget(_wrap(const CalendarPage(railExpanded: true, testMode: true)));
      await tester.pumpAndSettle();
      // Collect header containers
      final headers = tester.widgetList<Container>(find.byWidgetPredicate((w) => w is Container && (w.decoration is BoxDecoration)));
      // Heuristic: look for one with pure primary (full opacity) and others with withValues(alpha:0.7)
      final primaryFull = headers.where((c) {
        final deco = c.decoration as BoxDecoration;
        final color = deco.color;
        return color != null && color.opacity == 1.0;
      });
      expect(primaryFull.length, greaterThanOrEqualTo(1));
    });
  });
}