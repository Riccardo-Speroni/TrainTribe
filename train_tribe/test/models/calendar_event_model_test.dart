import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/models/calendar_event.dart';

void main() {
  group('CalendarEvent.fromFirestore', () {
    test('maps timestamp range to slots and clamps correctly', () {
      final start = DateTime(2024, 1, 1, 5, 30); // before 6:00 -> clamp to 0
      final end = DateTime(2024, 1, 1, 23, 59); // late evening
      final data = {
        'event_start': Timestamp.fromDate(start),
        'event_end': Timestamp.fromDate(end),
        'origin': 'MIL',
        'destination': 'ROM',
        'recurrent': true,
        'recurrence_end': Timestamp.fromDate(DateTime(2024, 2, 1)),
      };
      final ev = CalendarEvent.fromFirestore('abc', data);
      expect(ev.id, 'abc');
      expect(ev.hour, 0); // clamped
      expect(ev.endHour, greaterThan(ev.hour));
      expect(ev.isRecurrent, isTrue);
      expect(ev.recurrenceEndDate, isNotNull);
      expect(ev.departureStation, 'MIL');
    });
  });
}
