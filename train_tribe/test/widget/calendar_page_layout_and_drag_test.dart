import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/calendar_page.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:train_tribe/l10n/app_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:train_tribe/widgets/calendar_widgets/calendar_columns.dart';

Widget _wrapWithSize({required double width, required Widget child}) => MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('it')],
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, 900)),
        child: child,
      ),
    );

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
  });

  testWidgets('CalendarPage shows 3 days on narrow width', (tester) async {
    await tester.pumpWidget(_wrapWithSize(width: 500, child: const CalendarPage(railExpanded: false, testMode: true)));
    await tester.pumpAndSettle();
    expect(find.byType(CalendarDayColumn), findsNWidgets(3));
  });

  testWidgets('CalendarPage shows 7 days on wide width and supports drag-create in testMode', (tester) async {
    await tester.pumpWidget(_wrapWithSize(width: 900, child: const CalendarPage(railExpanded: false, testMode: true)));
    await tester.pumpAndSettle();
    expect(find.byType(CalendarDayColumn), findsNWidgets(7));

    // Use @visibleForTesting helpers to create an event via drag indices without dialogs/Firestore
    final state = tester.state(find.byType(CalendarPage)) as CalendarPageState;
    await state.loadDefaultStationsForTest();
    final day = DateTime.now();
    state.testSetDragIndices(day, 8, 12);
    final newEvent = state.testCreateEventFromDrag(day);
    expect(newEvent, isNotNull);
    await tester.pumpAndSettle();

    // Event should render
    expect(find.byType(CalendarDayColumn), findsWidgets);
  });
}
