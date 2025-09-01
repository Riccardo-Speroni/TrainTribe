import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/models/calendar_event.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('CalendarEvent.fromFirestore', () {
    test('parses start/end timestamps and maps to slots', () {
      final start = DateTime(2025, 1, 1, 6, 0); // slot 0
      final end = DateTime(2025, 1, 1, 7, 0); // hour 7 => slot 4
      final data = {
        'event_start': Timestamp.fromDate(start),
        'event_end': Timestamp.fromDate(end),
        'origin': 'Station A',
        'destination': 'Station B',
        'recurrent': true,
        'recurrence_end': Timestamp.fromDate(DateTime(2025, 2, 1)),
      };
      final event = CalendarEvent.fromFirestore('abc', data);
      expect(event.id, 'abc');
      expect(event.hour, 0);
      expect(event.endHour, 4);
      expect(event.departureStation, 'Station A');
      expect(event.arrivalStation, 'Station B');
      expect(event.isRecurrent, true);
      expect(event.recurrenceEndDate, isNotNull);
    });
  });
}
