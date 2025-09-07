import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:train_tribe/trains_page.dart';
import 'package:train_tribe/l10n/app_localizations.dart';
import 'package:train_tribe/utils/train_confirmation.dart';
import 'package:train_tribe/widgets/trains_widgets/train_card.dart';

class _MemoryStore implements ConfirmationStore {
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

  testWidgets('Header uses short labels on tight width and long labels on wide', (tester) async {
    final svc = TrainConfirmationService(store: _MemoryStore());

    // Tight surface -> short day labels (DateFormat.E)
    await tester.binding.setSurfaceSize(const Size(360, 800));
    await tester.pumpWidget(_wrap(TrainsPage(testMode: true, confirmationServiceOverride: svc)));
    await tester.pumpAndSettle();

    // Compute expected short labels for today..+6
    final now = DateTime.now();
    final shortLabels = List.generate(7, (i) => toBeginningOfSentenceCase(DateFormat.E('en').format(now.add(Duration(days: i))))!);
    // At least one of the short labels should be present
    final anyShort = shortLabels.any((s) => find.text(s).evaluate().isNotEmpty);
    expect(anyShort, isTrue);

    // Wide surface -> long day labels (DateFormat.EEEE)
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    await tester.pumpAndSettle();
    final longLabels = List.generate(7, (i) => toBeginningOfSentenceCase(DateFormat.EEEE('en').format(now.add(Duration(days: i))))!);
    final anyLong = longLabels.any((s) => find.text(s).evaluate().isNotEmpty);
    expect(anyLong, isTrue);
  });

  testWidgets('Tap a card expands timeline with overlay using injected test events', (tester) async {
    final svc = TrainConfirmationService(store: _MemoryStore());
    // Build a routes map with many stops to ensure overlay appears when expanded
    final manyStops = [
      for (int i = 0; i < 20; i++)
        {
          'stop_id': 'S$i',
          if (i == 0) 'departure_time': '08:00:00' else 'arrival_time': '08:${(i * 2) % 60}'.padLeft(2, '0') + ':00',
        }
    ];
    final routes = [
      {
        'leg1': {
          'trip_id': 'T999',
          'from': 'S0',
          'to': 'S19',
          'stops': manyStops,
          'friends': [],
        }
      }
    ];
    final events = <String, List<dynamic>>{'evt': routes};

    await tester.binding.setSurfaceSize(const Size(800, 900));
    await tester.pumpWidget(_wrap(TrainsPage(
      testMode: true,
      confirmationServiceOverride: svc,
      testUserId: 'u1',
      testEventsData: events,
    )));
    await tester.pumpAndSettle();

    // Tap first TrainCard to expand
    final card = find.byType(TrainCard).first;
    await tester.tap(card);
    await tester.pumpAndSettle();

    // Overlay (vertical or horizontal) should appear when expanded with many stops
    final overlay = find.byKey(const ValueKey('scrollProgress_v'));
    final overlayH = find.byKey(const ValueKey('scrollProgress_h'));
    expect(overlay.evaluate().isNotEmpty || overlayH.evaluate().isNotEmpty, isTrue);
  });
}
