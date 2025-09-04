import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/trains_page.dart';
import 'package:train_tribe/utils/train_confirmation.dart';
import 'package:train_tribe/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class _MemoryStore implements ConfirmationStore {
  final Map<String, bool> _data = {}; // key: date|train|user
  @override
  Future<bool> getConfirmation({required String dateStr, required String trainId, required String userId}) async {
    return _data['$dateStr|$trainId|$userId'] == true;
  }

  @override
  Future<void> setConfirmation(
      {required String dateStr, required String trainId, required String userId, required bool confirmed, required Timestamp now}) async {
    _data['$dateStr|$trainId|$userId'] = confirmed;
  }
}

class _FakeConfirmationService extends TrainConfirmationService {
  int confirmCalls = 0;
  final _MemoryStore store;
  _FakeConfirmationService(this.store) : super(store: store);
  @override
  Future<(String?, String)> confirmRoute(
      {required String dateStr,
      required List<String> selectedRouteTrainIds,
      required String userId,
      required List<String> allEventTrainIds}) async {
    confirmCalls++;
    return super
        .confirmRoute(dateStr: dateStr, selectedRouteTrainIds: selectedRouteTrainIds, userId: userId, allEventTrainIds: allEventTrainIds);
  }
}

void main() {
  testWidgets('Confirm button changes label after tap using fake service', (tester) async {
    final fake = _FakeConfirmationService(_MemoryStore());
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('it')],
      home: TrainsPage(testMode: true, confirmationServiceOverride: fake, testUserId: 'u1'),
    ));
    await tester.pumpAndSettle();

    // One stub event with one route -> confirm button should exist
    final confirmFinder = find.byKey(const ValueKey('confirmBtn_event1_T1'));
    expect(confirmFinder, findsOneWidget);

    // Initial label 'Confirm'
    expect(find.textContaining('Confirm'), findsOneWidget);

    await tester.tap(confirmFinder);
    await tester.pump();

    expect(fake.confirmCalls, 1);
    // After tap label becomes 'Confirmed'
    expect(find.textContaining('Confirmed'), findsOneWidget);
  });

  testWidgets('Confirming second route unsets first for same event', (tester) async {
    final fake = _FakeConfirmationService(_MemoryStore());
    final events = {
      'eventX': [
        {
          'leg1': {
            'trip_id': 'A1',
            'from': 'S1',
            'to': 'S2',
            'stops': [
              {'stop_id': 'S1', 'departure_time': '08:00:00'},
              {'stop_id': 'S2', 'arrival_time': '09:00:00'}
            ],
            'friends': []
          }
        },
        {
          'leg1': {
            'trip_id': 'B1',
            'from': 'S1',
            'to': 'S2',
            'stops': [
              {'stop_id': 'S1', 'departure_time': '10:00:00'},
              {'stop_id': 'S2', 'arrival_time': '11:00:00'}
            ],
            'friends': []
          }
        },
      ]
    };
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('it')],
      home: TrainsPage(
        testMode: true,
        confirmationServiceOverride: fake,
        testUserId: 'u2',
        testEventsData: events,
      ),
    ));
    await tester.pumpAndSettle();

    final firstBtn = find.byKey(const ValueKey('confirmBtn_eventX_A1'));
    final secondBtn = find.byKey(const ValueKey('confirmBtn_eventX_B1'));
    expect(firstBtn, findsOneWidget);
    expect(secondBtn, findsOneWidget);

    // Confirm first route
    await tester.tap(firstBtn);
    await tester.pump();
    expect(find.descendant(of: firstBtn, matching: find.textContaining('Confirmed')), findsOneWidget);

    // Confirm second route, first should revert to Confirm
    await tester.tap(secondBtn);
    await tester.pump();
    expect(find.descendant(of: secondBtn, matching: find.textContaining('Confirmed')), findsOneWidget);
    expect(find.descendant(of: firstBtn, matching: find.textContaining('Confirm')), findsOneWidget);
  });

  testWidgets('Multi-leg route confirmation sets all legs and exclusivity maintained', (tester) async {
    final fake = _FakeConfirmationService(_MemoryStore());
    final events = {
      'eventY': [
        {
          'leg1': {
            'trip_id': 'L1',
            'from': 'S1',
            'to': 'S2',
            'stops': [
              {'stop_id': 'S1', 'departure_time': '07:00:00'},
              {'stop_id': 'S2', 'arrival_time': '07:30:00'}
            ],
            'friends': []
          },
          'leg2': {
            'trip_id': 'L2',
            'from': 'S2',
            'to': 'S3',
            'stops': [
              {'stop_id': 'S2', 'departure_time': '07:35:00'},
              {'stop_id': 'S3', 'arrival_time': '08:10:00'}
            ],
            'friends': []
          },
        },
        {
          'leg1': {
            'trip_id': 'M1',
            'from': 'S1',
            'to': 'S3',
            'stops': [
              {'stop_id': 'S1', 'departure_time': '07:15:00'},
              {'stop_id': 'S3', 'arrival_time': '08:05:00'}
            ],
            'friends': []
          }
        },
      ]
    };
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('it')],
      home: TrainsPage(
        testMode: true,
        confirmationServiceOverride: fake,
        testUserId: 'u3',
        testEventsData: events,
      ),
    ));
    await tester.pumpAndSettle();

    final multiLegBtn = find.byKey(const ValueKey('confirmBtn_eventY_L1+L2'));
    final singleBtn = find.byKey(const ValueKey('confirmBtn_eventY_M1'));
    expect(multiLegBtn, findsOneWidget);
    expect(singleBtn, findsOneWidget);

    await tester.tap(multiLegBtn);
    await tester.pump();
    expect(find.descendant(of: multiLegBtn, matching: find.textContaining('Confirmed')), findsOneWidget);
    expect(find.descendant(of: singleBtn, matching: find.textContaining('Confirm')), findsOneWidget);

    await tester.tap(singleBtn);
    await tester.pump();
    expect(find.descendant(of: singleBtn, matching: find.textContaining('Confirmed')), findsOneWidget);
    expect(find.descendant(of: multiLegBtn, matching: find.textContaining('Confirm')), findsOneWidget);
  });
}
