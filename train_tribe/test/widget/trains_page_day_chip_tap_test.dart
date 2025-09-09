import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/trains_page.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:train_tribe/l10n/app_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:train_tribe/utils/train_confirmation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  setUpAll(() async {
    await initializeDateFormatting('en');
  });

  testWidgets('Tapping day chips updates selection and reloads data in testMode', (tester) async {
    // Fake in-memory store to avoid touching Firebase in TrainConfirmationService
    final store = _MemoryStore();
    final svc = TrainConfirmationService(store: store);
    await tester.pumpWidget(_wrap(TrainsPage(testMode: true, confirmationServiceOverride: svc)));
    await tester.pumpAndSettle();

    // There should be 7 day chips. Filter AnimatedContainers that look like day chips (have borderRadius 20).
    final chips = find.byWidgetPredicate((w) {
      if (w is AnimatedContainer) {
        final d = w.decoration;
        if (d is BoxDecoration) {
          final br = d.borderRadius;
          return br is BorderRadius && br.topLeft.x == 20.0; // day chips use 20 radius
        }
      }
      return false;
    });
    expect(chips, findsNWidgets(7));

    // Ensure they are visible/hittable and tap the 3rd.
    await tester.ensureVisible(chips.at(2));
    await tester.pump();
    await tester.tap(chips.at(2), warnIfMissed: false);
    await tester.pumpAndSettle();

    // Tap a different one to ensure setState path is executed.
    await tester.ensureVisible(chips.at(4));
    await tester.pump();
    await tester.tap(chips.at(4), warnIfMissed: false);
    await tester.pumpAndSettle();

    // Expect body list exists (either empty or with items) and no crash.
    expect(find.byType(ListView), findsOneWidget);
  });
}

class _MemoryStore implements ConfirmationStore {
  final Map<String, Map<String, bool>> _byDate = {};
  String _key(String trainId, String userId) => '$trainId|$userId';

  @override
  Future<bool> getConfirmation({required String dateStr, required String trainId, required String userId}) async {
    return _byDate[dateStr]?[_key(trainId, userId)] ?? false;
  }

  @override
  Future<void> setConfirmation(
      {required String dateStr, required String trainId, required String userId, required bool confirmed, required Timestamp now}) async {
    _byDate.putIfAbsent(dateStr, () => {});
    _byDate[dateStr]![_key(trainId, userId)] = confirmed;
  }
}
