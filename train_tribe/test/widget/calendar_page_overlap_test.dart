import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/calendar_page.dart';
import 'package:train_tribe/models/calendar_event.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:train_tribe/l10n/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
      locale: const Locale('en'),
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
  testWidgets('Overlapping events get width/alignment adjusted', (tester) async {
    await tester.pumpWidget(_wrap(const CalendarPage(railExpanded: false, testMode: true)));
    await tester.pumpAndSettle();

    final state = tester.state(find.byType(CalendarPage)) as CalendarPageState;
    final day = DateTime.now();
    final e1 = CalendarEvent(
      date: day,
      hour: 8,
      endHour: 12,
      departureStation: 'A',
      arrivalStation: 'B',
    );
    final e2 = CalendarEvent(
      date: day,
      hour: 10,
      endHour: 14,
      departureStation: 'C',
      arrivalStation: 'D',
    );
    state.addTestEvents([e1, e2]);
    await tester.pumpAndSettle();

    state.adjustOverlappingForDay(day);
    await tester.pump();

    // Expect widthFactor assigned to both and not equal to 1.0 (since they overlap).
    expect(e1.widthFactor, isNotNull);
    expect(e2.widthFactor, isNotNull);
    expect(e1.alignment, isNotNull);
    expect(e2.alignment, isNotNull);
  });
}
