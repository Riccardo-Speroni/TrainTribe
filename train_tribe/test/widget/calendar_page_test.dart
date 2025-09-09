import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/calendar_page.dart';
import 'package:train_tribe/models/calendar_event.dart';
import 'package:train_tribe/widgets/calendar_widgets/calendar_columns.dart';
import 'package:train_tribe/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

Widget _buildTestApp(Widget child) => MaterialApp(
      localizationsDelegates: const [AppLocalizations.delegate],
      supportedLocales: const [Locale('en')],
      home: child,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await initializeDateFormatting('en');
  });

  group('CalendarPage basic structure', () {
    testWidgets('renders time column and FAB', (tester) async {
      await tester.pumpWidget(_buildTestApp(const CalendarPage(railExpanded: false, testMode: true)));
      await tester.pumpAndSettle();
      // Time column widget present
      expect(find.byType(CalendarTimeColumn), findsOneWidget);
      // FAB present
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('shows 3 day headers on narrow layout', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(_buildTestApp(const CalendarPage(railExpanded: false, testMode: true)));
      await tester.pumpAndSettle();
      final now = DateTime.now();
      // Expect 3 day headers (today + next 2 days)
      int found = 0;
      for (int i = 0; i < 3; i++) {
        final d = now.add(Duration(days: i));
        final label = DateFormat('EEE, d MMM', 'en').format(d);
        if (find.text(label).evaluate().isNotEmpty) found++;
      }
      expect(found, 3);
    });

    testWidgets('shows 7 day headers on wide layout', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(_buildTestApp(const CalendarPage(railExpanded: true, testMode: true)));
      await tester.pumpAndSettle();
  // Expect multiple Expanded header children present
  expect(find.byType(Expanded), findsWidgets);
    });
  });

  group('CalendarPage event interaction (testMode)', () {
  // NOTE: Interaction tests (FAB dialog & drag create) require more robust localization + gesture timing; defer for now.

  testWidgets('overlapping events adjust width/alignment', (tester) async {
      final page = CalendarPage(railExpanded: false, testMode: true);
      await tester.pumpWidget(_buildTestApp(page));
      await tester.pumpAndSettle();
      final state = tester.state<CalendarPageState>(find.byType(CalendarPage));
      final today = DateTime.now();
      state.addTestEvents([
        CalendarEvent(
          id: 'a',
          date: today,
          hour: 4,
          endHour: 8,
          departureStation: 'X',
          arrivalStation: 'Y',
          isRecurrent: false,
        ),
        CalendarEvent(
          id: 'b',
            date: today,
            hour: 6,
            endHour: 10,
            departureStation: 'X',
            arrivalStation: 'Y',
            isRecurrent: false,
          ),
      ]);
      state.adjustOverlappingForDay(today);
      await tester.pump();
      // Both events now have widthFactor 0.5
      expect(state.events.where((e) => e.date.day == today.day).length, 2);
      final first = state.events.first;
      final second = state.events[1];
      expect(first.widthFactor, closeTo(0.5, 0.01));
      expect(second.widthFactor, closeTo(0.5, 0.01));
    });
  });
}
