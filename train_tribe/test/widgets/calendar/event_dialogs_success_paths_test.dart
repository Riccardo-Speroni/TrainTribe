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
  setUp(() {
    eventDialogsDebugBypassFirebase = true; // ensure no Firestore/Auth
  });

  testWidgets('showAddEventDialog saves successfully with valid stations (bypass active)', (tester) async {
    await tester.pumpWidget(_wrap(const SizedBox()));
    await tester.pumpAndSettle();
    final rootContext = tester.element(find.byType(Scaffold));

    bool added = false;
    Future.microtask(() {
      showAddEventDialog(
        context: rootContext,
        day: DateTime.now().add(const Duration(days: 1)),
        startIndex: 2,
        stationNames: const ['Milan', 'Rome'],
        hours: List.generate(12, (i) => i),
        events: const [],
        onEventAdded: (_) => added = true,
      );
    });
    await tester.pumpAndSettle();

    // Fill valid stations
    await tester.enterText(find.byType(TextField).at(0), 'Milan');
    await tester.enterText(find.byType(TextField).at(1), 'Rome');
    await tester.pump();
    // Save
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(added, isTrue);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('showEditEventDialog save updates recurrent event and closes', (tester) async {
    await tester.pumpWidget(_wrap(const SizedBox()));
    await tester.pumpAndSettle();
    final rootContext = tester.element(find.byType(Scaffold));

    // Generator + one child
    final generator = CalendarEvent(
      date: DateTime.now().add(const Duration(days: 3)),
      hour: 2,
      endHour: 4,
      departureStation: 'Milan',
      arrivalStation: 'Rome',
      isRecurrent: true,
      recurrenceEndDate: DateTime.now().add(const Duration(days: 30)),
    );
    final child = CalendarEvent(
      generatedBy: generator.id,
      date: generator.date.add(const Duration(days: 7)),
      hour: generator.hour,
      endHour: generator.endHour,
      departureStation: generator.departureStation,
      arrivalStation: generator.arrivalStation,
      isRecurrent: generator.isRecurrent,
      recurrenceEndDate: generator.recurrenceEndDate,
    );
    bool updated = false;
    Future.microtask(() {
      showEditEventDialog(
        context: rootContext,
        event: child,
        hours: List.generate(10, (i) => i),
        events: [generator, child],
        onEventUpdated: () => updated = true,
        onEventDeleted: (_) {},
        stationNames: const ['Milan', 'Rome', 'Florence'],
      );
    });
    await tester.pumpAndSettle();

    // Keep recurrent checked; fill valid stations; save
    await tester.enterText(find.byType(TextField).at(0), 'Milan');
    await tester.enterText(find.byType(TextField).at(1), 'Florence');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(updated, isTrue);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('showEditEventDialog delete flow confirms and calls onEventDeleted', (tester) async {
    await tester.pumpWidget(_wrap(const SizedBox()));
    await tester.pumpAndSettle();
    final rootContext = tester.element(find.byType(Scaffold));

    final ev = CalendarEvent(
      date: DateTime.now().add(const Duration(days: 1)),
      hour: 1,
      endHour: 3,
      departureStation: 'A',
      arrivalStation: 'B',
    );
    String? deleted;
    Future.microtask(() {
      showEditEventDialog(
        context: rootContext,
        event: ev,
        hours: List.generate(6, (i) => i),
        events: [ev],
        onEventUpdated: () {},
        onEventDeleted: (id) => deleted = id,
        stationNames: const ['A', 'B'],
      );
    });
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();

    expect(deleted, isNotNull);
    expect(find.byType(AlertDialog), findsNothing);
  });
}
