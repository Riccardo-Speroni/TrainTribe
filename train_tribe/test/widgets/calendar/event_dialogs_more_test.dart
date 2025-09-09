import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/l10n/app_localizations.dart';
import 'package:train_tribe/models/calendar_event.dart';
import 'package:train_tribe/widgets/calendar_widgets/event_dialogs.dart';

Widget _app(Widget child) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      locale: const Locale('en'),
      home: Scaffold(body: child),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() { eventDialogsDebugBypassFirebase = true; });

  group('event_dialogs extra coverage', () {
    testWidgets('add dialog: end slot reset after start slot change + recurrence toggle', (tester) async {
      await tester.pumpWidget(_app(const SizedBox()));
      await tester.pumpAndSettle();
      final ctx = tester.element(find.byType(Scaffold));
      Future.microtask(() {
        showAddEventDialog(
          context: ctx,
          day: DateTime.now().add(const Duration(days: 1)),
          startIndex: 0,
          stationNames: const ['AAA', 'BBB'],
          hours: List.generate(12, (i) => i),
          events: const [],
          onEventAdded: (_) {},
        );
      });
      await tester.pumpAndSettle();
      // Fill valid stations
      await tester.enterText(find.byType(TextField).at(0), 'AAA');
      await tester.enterText(find.byType(TextField).at(1), 'BBB');
      // Open end dropdown (second dropdown) and choose slot 2 (06:30)
      final endDropdown = find.byType(DropdownButton<int>).last;
      await tester.tap(endDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('06:30').last);
      await tester.pumpAndSettle();
      // Open start dropdown and change start to slot 4 (07:00) causing previous end(2) invalid -> reset to 5 (07:15)
      final startDropdown = find.byType(DropdownButton<int>).first;
      await tester.tap(startDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('07:00').last);
      await tester.pumpAndSettle();
      // Verify end dropdown value reset (should not still be 06:30)
      final updatedEnd = tester.widget<DropdownButton<int>>(endDropdown);
      expect(updatedEnd.value, isNot(2));
      // Toggle recurrence to show recurrence row
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      expect(find.textContaining('End Recurrence'), findsOneWidget);
      // Close without saving
      await tester.tap(find.byTooltip('Cancel'));
      await tester.pumpAndSettle();
    });

    testWidgets('edit dialog recurrent event shows recurrence row', (tester) async {
      await tester.pumpWidget(_app(const SizedBox()));
      await tester.pumpAndSettle();
      final ctx = tester.element(find.byType(Scaffold));
      final base = DateTime.now().add(const Duration(days: 3));
      final event = CalendarEvent(
        date: base,
        hour: 4,
        endHour: 6,
        departureStation: 'DEP',
        arrivalStation: 'ARR',
        isRecurrent: true,
        recurrenceEndDate: base.add(const Duration(days: 21)),
      );
      Future.microtask(() {
        showEditEventDialog(
          context: ctx,
          event: event,
          hours: List.generate(12, (i) => i),
          events: [event],
          onEventUpdated: () {},
          onEventDeleted: (_) {},
          stationNames: const ['DEP', 'ARR'],
        );
      });
      await tester.pumpAndSettle();
      expect(find.textContaining('End Recurrence'), findsOneWidget);
      // Close dialog
      await tester.tap(find.byTooltip('Cancel'));
      await tester.pumpAndSettle();
    });

    testWidgets('edit dialog start slot change resets invalid end slot', (tester) async {
      await tester.pumpWidget(_app(const SizedBox()));
      await tester.pumpAndSettle();
      final ctx = tester.element(find.byType(Scaffold));
      final base = DateTime.now().add(const Duration(days: 2));
      final event = CalendarEvent(
        date: base,
        hour: 1,
        endHour: 3,
        departureStation: 'A',
        arrivalStation: 'B',
      );
      Future.microtask(() {
        showEditEventDialog(
          context: ctx,
          event: event,
          hours: List.generate(15, (i) => i),
          events: [event],
          onEventUpdated: () {},
          onEventDeleted: (_) {},
          stationNames: const ['A', 'B'],
        );
      });
      await tester.pumpAndSettle();
      // First DropdownButton is start slot, second is end slot
      final startDropdown = find.byType(DropdownButton<int>).first;
      // Open menu
      await tester.tap(startDropdown);
      await tester.pumpAndSettle();
      // Select a higher start slot so previous end (3) becomes invalid; choose slot 3
      await tester.tap(find.text('06:45').last); // slot 3 -> time 06:45
      await tester.pumpAndSettle();
      // Now change start to slot 4 so end 3 invalid and should reset to 5
      await tester.tap(startDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('07:00').last); // slot 4
      await tester.pumpAndSettle();
      // End dropdown should not show 06:45 anymore as selected
      final endDropdown = find.byType(DropdownButton<int>).last;
      final endWidget = tester.widget<DropdownButton<int>>(endDropdown);
      expect(endWidget.value, isNot(3));
      await tester.tap(find.byTooltip('Cancel'));
      await tester.pumpAndSettle();
    });
  });
}
