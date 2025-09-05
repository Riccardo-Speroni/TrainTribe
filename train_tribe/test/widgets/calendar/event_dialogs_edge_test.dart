import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/l10n/app_localizations.dart';
import 'package:train_tribe/models/calendar_event.dart';
import 'package:train_tribe/widgets/calendar_widgets/event_dialogs.dart';

Widget _host(Widget child) => MaterialApp(
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

void main(){
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(()=> eventDialogsDebugBypassFirebase = true);

  group('event_dialogs edge cases', (){
    testWidgets('add dialog: invalid then valid stations but empty save does nothing (no callback)', (tester) async {
      await tester.pumpWidget(_host(const SizedBox()));
      await tester.pumpAndSettle();
      final ctx = tester.element(find.byType(Scaffold));
      bool added = false;
      Future.microtask(() { showAddEventDialog(
        context: ctx,
        day: DateTime.now().add(const Duration(days: 1)),
        startIndex: 0,
        stationNames: const ['S1','S2'],
        hours: List.generate(5,(i)=>i),
        events: const [],
        onEventAdded: (_)=> added = true,
      ); });
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save')); // error
      await tester.pumpAndSettle();
      expect(find.text('Invalid station name'), findsOneWidget);
      // Enter only departure and try again (arrival empty -> still no add / no error because empty triggers early return)
      await tester.enterText(find.byType(TextField).first, 'S1');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(added, isFalse);
      await tester.tap(find.byTooltip('Cancel'));
      await tester.pumpAndSettle();
    });

    testWidgets('edit dialog: recurrent branch updates generator & copies when checkbox stays on', (tester) async {
      await tester.pumpWidget(_host(const SizedBox()));
      await tester.pumpAndSettle();
      final ctx = tester.element(find.byType(Scaffold));
      final base = DateTime.now().add(const Duration(days: 4));
      final gen = CalendarEvent(
        date: base,
        hour: 0,
        endHour: 2,
        departureStation: 'AA',
        arrivalStation: 'BB',
        isRecurrent: true,
        recurrenceEndDate: base.add(const Duration(days: 14)),
      );
      final copy = CalendarEvent(
        generatedBy: gen.id,
        date: base.add(const Duration(days: 7)),
        hour: 0,
        endHour: 2,
        departureStation: 'AA',
        arrivalStation: 'BB',
        isRecurrent: true,
        recurrenceEndDate: gen.recurrenceEndDate,
      );
      bool updated=false;
      Future.microtask(() { showEditEventDialog(
        context: ctx,
        event: copy,
        hours: List.generate(8,(i)=>i),
        events: [gen, copy],
        onEventUpdated: ()=> updated=true,
        onEventDeleted: (_){},
        stationNames: const ['AA','BB','CC'],
      ); });
      await tester.pumpAndSettle();
      // Change arrival station to CC to propagate
      await tester.enterText(find.byType(TextField).at(1), 'CC');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(updated, isTrue);
      // Dialog closed
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('edit dialog: delete confirm path triggers callback id', (tester) async {
      await tester.pumpWidget(_host(const SizedBox()));
      await tester.pumpAndSettle();
      final ctx = tester.element(find.byType(Scaffold));
      final ev = CalendarEvent(
        date: DateTime.now().add(const Duration(days: 6)),
        hour: 1,
        endHour: 2,
        departureStation: 'D1',
        arrivalStation: 'D2',
      );
      String? deleted;
      Future.microtask(() { showEditEventDialog(
        context: ctx,
        event: ev,
        hours: List.generate(6,(i)=>i),
        events: [ev],
        onEventUpdated: (){},
        onEventDeleted: (id)=> deleted = id,
        stationNames: const ['D1','D2'],
      ); });
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      // Confirm dialog
      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();
      expect(deleted, ev.id);
    });
  });
}
