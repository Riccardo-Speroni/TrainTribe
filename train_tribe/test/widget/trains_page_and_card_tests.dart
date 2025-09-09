import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:train_tribe/trains_page.dart';
import 'package:train_tribe/l10n/app_localizations.dart';
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

// Minimal fake store to avoid touching Firebase in tests
class _FakeStore implements ConfirmationStore {
  @override
  Future<bool> getConfirmation({required String dateStr, required String trainId, required String userId}) async => false;

  @override
  Future<void> setConfirmation({
    required String dateStr,
    required String trainId,
    required String userId,
    required bool confirmed,
    required Timestamp now,
  }) async {}
}

void main() {
  testWidgets('TrainsPage build branches and selection header interactions', (tester) async {
    final svc = TrainConfirmationService(store: _FakeStore());

    await tester.pumpWidget(_wrap(TrainsPage(
      testMode: true,
      confirmationServiceOverride: svc,
      testUserId: 'u1',
    )));
    await tester.pumpAndSettle();

    // Header exists; tap a day to trigger _loadData (no-op in testMode)
    expect(find.byType(AppBar), findsOneWidget);
    await tester.tap(find.byType(GestureDetector).first);
    await tester.pump();

    // Body shows list (from testMode data)
    expect(find.byType(ListView), findsOneWidget);
  });
}
