import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/trains_page.dart';
import 'package:train_tribe/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:train_tribe/utils/train_confirmation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class _MemoryStore implements ConfirmationStore {
  final Map<String, bool> _data = {};
  @override
  Future<bool> getConfirmation({required String dateStr, required String trainId, required String userId}) async =>
      _data['$dateStr|$trainId|$userId'] == true;
  @override
  Future<void> setConfirmation(
      {required String dateStr, required String trainId, required String userId, required bool confirmed, required Timestamp now}) async {
    _data['$dateStr|$trainId|$userId'] = confirmed;
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('it');
  });
  List<String> fullNames() => List.generate(7, (i) => DateFormat.EEEE('en').format(DateTime.now().add(Duration(days: i))));
  List<String> shortNames() => List.generate(7, (i) => DateFormat.E('en').format(DateTime.now().add(Duration(days: i))));

  Widget buildPage(double width) => MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('it')],
        builder: (context, child) {
          // Override MediaQuery size to control LayoutBuilder constraints.
          final mq = MediaQuery.of(context);
          return MediaQuery(
            data: mq.copyWith(size: Size(width, mq.size.height)),
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: width,
                child: child,
              ),
            ),
          );
        },
        home: TrainsPage(
          testMode: true,
          testUserId: 'u',
          confirmationServiceOverride: TrainConfirmationService(store: _MemoryStore()),
        ),
      );

  testWidgets('Uses full day labels when width sufficient', (tester) async {
    final full = fullNames();
    final short = shortNames();
    await tester.pumpWidget(buildPage(1200));
    await tester.pumpAndSettle();
    final fullCount = full.where((n) => find.text(n).evaluate().isNotEmpty).length;
    final anyShort = short.any((n) => find.text(n).evaluate().isNotEmpty && !full.contains(n));
    expect(fullCount >= 2, isTrue, reason: 'Expected multiple full weekday names at wide width');
    expect(anyShort, isFalse, reason: 'No pure short labels expected at wide width');
  });

  testWidgets('Falls back to short day labels when width tight', (tester) async {
    final full = fullNames();
    final short = shortNames();
    await tester.pumpWidget(buildPage(320));
    await tester.pumpAndSettle();
    // Collect all rendered weekday labels
    final rendered = <String>[];
    for (final f in full) {
      if (find.text(f).evaluate().isNotEmpty) rendered.add(f);
    }
    for (final s in short) {
      if (find.text(s).evaluate().isNotEmpty && !rendered.contains(s)) rendered.add(s);
    }
    // Heuristic: average rendered label length should be closer to short names than full names.
    double avgLen = rendered.isEmpty ? 0 : rendered.map((e) => e.length).reduce((a, b) => a + b) / rendered.length;
    final fullAvg = full.map((e) => e.length).reduce((a, b) => a + b) / full.length;
    final shortAvg = short.map((e) => e.length).reduce((a, b) => a + b) / short.length;
    expect((avgLen - shortAvg).abs() < (avgLen - fullAvg).abs(), isTrue,
        reason: 'Rendered labels should be closer in length to short forms');
  });
}
