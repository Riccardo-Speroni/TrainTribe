import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/trains_page.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:train_tribe/l10n/app_localizations.dart';
import 'package:train_tribe/utils/train_confirmation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MemoryStore implements ConfirmationStore {
  final Map<String, Map<String, bool>> byDate = {};
  String _key(String trainId, String userId) => '$trainId|$userId';
  @override
  Future<bool> getConfirmation({required String dateStr, required String trainId, required String userId}) async {
    return byDate[dateStr]?[_key(trainId, userId)] ?? false;
  }

  @override
  Future<void> setConfirmation(
      {required String dateStr, required String trainId, required String userId, required bool confirmed, required Timestamp now}) async {
    byDate.putIfAbsent(dateStr, () => {});
    byDate[dateStr]![_key(trainId, userId)] = confirmed;
  }
}

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
  testWidgets('Confirm button persists route confirmation in memory store (testMode)', (tester) async {
    final store = MemoryStore();
    final svc = TrainConfirmationService(store: store);
    // Use explicit testUserId so keying is predictable inside TrainCard
    await tester.pumpWidget(_wrap(TrainsPage(testMode: true, confirmationServiceOverride: svc, testUserId: 'u1')));
    await tester.pumpAndSettle();

    // Default test data in TrainsPage has eventId 'event1' and routeSignature 'T1'
    final btnFinder = find.byKey(const ValueKey('confirmBtn_event1_T1'));
    expect(btnFinder, findsOneWidget);
    await tester.tap(btnFinder);
    await tester.pumpAndSettle();

    // Memory store should now contain a confirmation for some date with key 'T1|u1'
    final confirmed = store.byDate.values.any((m) => m['T1|u1'] == true);
    expect(confirmed, isTrue);
  });
}
