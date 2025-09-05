import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/l10n/app_localizations.dart';
import 'package:train_tribe/models/calendar_event.dart';
import 'package:train_tribe/widgets/calendar_widgets/event_dialogs.dart';

Widget _wrap(Widget child) => MaterialApp(
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

  group('showAddEventDialog', () {
  testWidgets('shows validation error and can close without saving', (tester) async {
  await tester.pumpWidget(_wrap(const SizedBox()));
  await tester.pumpAndSettle();
  final rootContext = tester.element(find.byType(Scaffold));

      bool addedCalled = false;
      // Schedule dialog after first frame
      Future.microtask(() {
        showAddEventDialog(
          context: rootContext,
          day: DateTime.now().add(const Duration(days: 1)),
          startIndex: 0,
          stationNames: const ['Milan', 'Rome'],
          hours: List.generate(10, (i) => i),
          events: const [],
          onEventAdded: (_) => addedCalled = true,
        );
      });
      await tester.pumpAndSettle();

  // Attempt save with empty stations -> should display error (no Firebase path yet)
  await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Invalid station name'), findsOneWidget);
      expect(addedCalled, isFalse);

      // Enter valid departure & arrival
      final departureField = find.byType(TextField).at(0);
      final arrivalField = find.byType(TextField).at(1);
      await tester.enterText(departureField, 'Milan');
      await tester.enterText(arrivalField, 'Rome');
      await tester.pump();
  // DO NOT tap save again to avoid Firebase call; close with top-right close icon
  await tester.tap(find.byTooltip('Cancel'));
  await tester.pumpAndSettle();
  expect(find.byType(AlertDialog), findsNothing);
  expect(addedCalled, isFalse); // since we didn't save
    });

    testWidgets('toggle recurrence UI appears when checkbox checked', (tester) async {
  await tester.pumpWidget(_wrap(const SizedBox()));
  await tester.pumpAndSettle();
  final rootContext = tester.element(find.byType(Scaffold));

      Future.microtask(() {
        showAddEventDialog(
          context: rootContext,
          day: DateTime.now().add(const Duration(days: 2)),
          startIndex: 1,
          stationNames: const ['A', 'B'],
          hours: List.generate(8, (i) => i),
          events: const [],
          onEventAdded: (_) {},
        );
      });
      await tester.pumpAndSettle();

      // Initially recurrence date selector not shown (text 'End Recurrence') hidden behind condition)
  expect(find.textContaining('End Recurrence'), findsNothing);
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
  expect(find.textContaining('End Recurrence'), findsOneWidget);
    });
  });

  group('showEditEventDialog', () {
  testWidgets('edit dialog validation error path without saving', (tester) async {
  await tester.pumpWidget(_wrap(const SizedBox()));
  await tester.pumpAndSettle();
  final rootContext = tester.element(find.byType(Scaffold));

      final original = CalendarEvent(
        date: DateTime.now().add(const Duration(days: 3)),
        hour: 2,
        endHour: 4,
        departureStation: 'Milan',
        arrivalStation: 'Rome',
        isRecurrent: true,
        recurrenceEndDate: DateTime.now().add(const Duration(days: 30)),
      );
      final copy = CalendarEvent(
        generatedBy: original.id,
        date: original.date.add(const Duration(days: 7)),
        hour: original.hour,
        endHour: original.endHour,
        departureStation: original.departureStation,
        arrivalStation: original.arrivalStation,
        isRecurrent: original.isRecurrent,
        recurrenceEndDate: original.recurrenceEndDate,
      );

      bool updatedCalled = false;
      Future.microtask(() {
        showEditEventDialog(
          context: rootContext,
          event: copy,
          hours: List.generate(10, (i) => i),
          events: [original, copy],
          onEventUpdated: () => updatedCalled = true,
          onEventDeleted: (_) {},
          stationNames: const ['Milan', 'Rome', 'Florence'],
        );
      });
      await tester.pumpAndSettle();

      // Uncheck recurrence to go through non-recurrent branch then cause validation error by invalid arrival
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      final arrivalField = find.byType(TextField).at(1);
      await tester.enterText(arrivalField, 'InvalidCity');
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Invalid station name'), findsOneWidget);
      // Close without saving to avoid Firebase
      await tester.tap(find.byTooltip('Cancel'));
      await tester.pumpAndSettle();
      expect(updatedCalled, isFalse);
    });

    testWidgets('delete flow not executed (dialog open/close only)', (tester) async {
  await tester.pumpWidget(_wrap(const SizedBox()));
  await tester.pumpAndSettle();
  final rootContext = tester.element(find.byType(Scaffold));

      final original = CalendarEvent(
        date: DateTime.now().add(const Duration(days: 5)),
        hour: 1,
        endHour: 3,
        departureStation: 'A',
        arrivalStation: 'B',
      );
      final copy = CalendarEvent(
        generatedBy: original.id,
        date: original.date.add(const Duration(days: 7)),
        hour: 1,
        endHour: 3,
        departureStation: 'A',
        arrivalStation: 'B',
      );

  String? deletedId;
      Future.microtask(() {
        showEditEventDialog(
          context: rootContext,
          event: copy,
          hours: List.generate(6, (i) => i),
          events: [original, copy],
          onEventUpdated: () {},
          onEventDeleted: (id) => deletedId = id,
          stationNames: const ['A', 'B'],
        );
      });
      await tester.pumpAndSettle();

  // Simply close without triggering delete
  await tester.tap(find.byTooltip('Cancel'));
  await tester.pumpAndSettle();
  expect(deletedId, isNull);
    });
  });
}
