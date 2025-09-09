import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:train_tribe/trains_page.dart';
import 'package:train_tribe/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:train_tribe/utils/train_confirmation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Future<void> pumpUntilSettled(WidgetTester tester, {Duration timeout = const Duration(seconds: 8)}) async {
    final end = DateTime.now().add(timeout);
    await tester.pumpAndSettle();
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
      if (!tester.binding.hasScheduledFrame) {
        await tester.pumpAndSettle(const Duration(milliseconds: 50));
        if (!tester.binding.hasScheduledFrame) return;
      }
    }
  }

  group('TrainsPage (testMode)', () {
    testWidgets('Confirm button marks route as Confirmed', (tester) async {
      final fakeStore = _InMemoryConfirmationStore();
      final svc = TrainConfirmationService(store: fakeStore);

      final widget = MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('it')],
        home: Scaffold(
          body: TrainsPage(
            testMode: true,
            testUserId: 'u1',
            confirmationServiceOverride: svc,
          ),
        ),
      );

      await tester.pumpWidget(widget);
      await pumpUntilSettled(tester);

      // Default test data in TrainsPage has event1 with one leg T1
      final btnKey = const ValueKey('confirmBtn_event1_T1');
      expect(find.byKey(btnKey), findsOneWidget);

      // Initially shows "Confirm"
      expect(find.descendant(of: find.byKey(btnKey), matching: find.text('Confirm')), findsOneWidget);

      await tester.tap(find.byKey(btnKey));
      await pumpUntilSettled(tester);

      // After tap, should show "Confirmed"
      expect(find.descendant(of: find.byKey(btnKey), matching: find.text('Confirmed')), findsOneWidget);

      // And store should have confirmation for T1
      expect(await fakeStore.getConfirmation(dateStr: anyDate(), trainId: 'T1', userId: 'u1'), isTrue);
    });
  });
}

String anyDate() {
  // The service sets date with the value passed in, TrainsPage builds one for today.
  // Our fake store ignores exact date matching by design (matches any stored).
  // Return today's yyyy-MM-dd to match a likely call.
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

class _InMemoryConfirmationStore implements ConfirmationStore {
  final Map<String, bool> _map = {}; // key: date|train|user -> confirmed

  String _k(String date, String train, String user) => '$date|$train|$user';

  @override
  Future<bool> getConfirmation({required String dateStr, required String trainId, required String userId}) async {
    // If exact key not present, try any date for the same train/user (for test robustness across day changes)
    final exact = _map[_k(dateStr, trainId, userId)];
    if (exact != null) return exact;
    for (final e in _map.entries) {
      if (e.key.endsWith('|$trainId|$userId')) return e.value;
    }
    return false;
  }

  @override
  Future<void> setConfirmation(
      {required String dateStr, required String trainId, required String userId, required bool confirmed, required Timestamp now}) async {
    _map[_k(dateStr, trainId, userId)] = confirmed;
  }
}
