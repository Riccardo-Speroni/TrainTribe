import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:train_tribe/utils/events_firebase.dart';

void main() {
  group('fetchEventsFromFirebase', () {
    test('returns list of CalendarEvent from user events subcollection', () async {
  final fake = FakeFirebaseFirestore();
      final userId = 'u1';
      final col = fake.collection('users').doc(userId).collection('events');
      await col.doc('e1').set({
        'event_start': Timestamp.fromDate(DateTime(2025, 1, 1, 6, 0)),
        'event_end': Timestamp.fromDate(DateTime(2025, 1, 1, 7, 0)),
        'origin': 'Station X',
        'destination': 'Station Y',
        'recurrent': false,
      });
      await col.doc('e2').set({
        'event_start': Timestamp.fromDate(DateTime(2025, 1, 2, 8, 0)),
        'event_end': Timestamp.fromDate(DateTime(2025, 1, 2, 9, 0)),
        'origin': 'Station A',
        'destination': 'Station B',
        'recurrent': true,
        'recurrence_end': Timestamp.fromDate(DateTime(2025, 2, 1)),
      });

  final events = await fetchEventsFromFirebase(userId, firestore: fake);
      expect(events.length, 2);
      expect(events.any((e) => e.departureStation == 'Station X'), true);
      expect(events.any((e) => e.isRecurrent), true);
    });

    test('returns empty list when no events', () async {
  final fake = FakeFirebaseFirestore();
  final events = await fetchEventsFromFirebase('none', firestore: fake);
      expect(events, isEmpty);
    });
  });
}
