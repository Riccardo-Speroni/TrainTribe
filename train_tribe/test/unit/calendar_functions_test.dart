import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/utils/calendar_functions.dart';
import 'package:train_tribe/models/calendar_event.dart';

void main() {
  group('calendar_functions', () {
    test('getDays generates correct number and sequence', () {
      final start = DateTime(2025, 1, 1);
      final days = getDays(start, 5);
      expect(days.length, 5);
      expect(days[0], start);
      expect(days[4], start.add(const Duration(days: 4)));
    });

    test('isSameDay compares only date portion', () {
      final a = DateTime(2025, 1, 1, 10, 30);
      final b = DateTime(2025, 1, 1, 23, 59);
      final c = DateTime(2025, 1, 2, 0, 0);
      expect(isSameDay(a, b), true);
      expect(isSameDay(a, c), false);
    });

    test('formatTime maps slot to readable HH:mm', () {
      expect(formatTime(0), '06:00');
      expect(formatTime(1), '06:15');
      expect(formatTime(4), '07:00');
    });

    test('formatTime wraps at midnight (slot 72 -> 00:00)', () {
      expect(formatTime(72), '00:00');
    });

    test('formatTime wraps after midnight (slot 76 -> 01:00)', () {
      expect(formatTime(76), '01:00');
    });

    test('getAvailableEndHours returns increasing slots after start', () {
      final list = getAvailableEndHours(DateTime(2025, 1, 1), 10);
      expect(list.first, 11);
      expect(list.last, 76);
      expect(list, isA<List<int>>());
    });

    test('isWithinRecurrence false for non recurrent', () {
      final event = CalendarEvent(
        date: DateTime(2025, 1, 1),
        hour: 0,
        endHour: 4,
        departureStation: 'A',
        arrivalStation: 'B',
      );
      expect(isWithinRecurrence(DateTime(2025, 1, 8), event), false);
    });

    test('isWithinRecurrence true within range', () {
      final event = CalendarEvent(
        date: DateTime(2025, 1, 1),
        hour: 0,
        endHour: 4,
        departureStation: 'A',
        arrivalStation: 'B',
        isRecurrent: true,
        recurrenceEndDate: DateTime(2025, 1, 31),
      );
      expect(isWithinRecurrence(DateTime(2025, 1, 8), event), true);
      expect(isWithinRecurrence(DateTime(2025, 2, 1), event), false);
    });

    test('generateRecurrentEvents creates weekly copies in visible range', () {
      final base = CalendarEvent(
        date: DateTime(2025, 1, 1),
        hour: 0,
        endHour: 4,
        departureStation: 'A',
        arrivalStation: 'B',
        isRecurrent: true,
        recurrenceEndDate: DateTime(2025, 1, 31),
      );
      final visible = List.generate(35, (i) => DateTime(2025, 1, 1).add(Duration(days: i)));
      final generated = generateRecurrentEvents(visible, [base]);
      // Should generate events for each 7 days excluding original (approx 4 additional Wednesdays in Jan 2025)
      expect(generated.length, greaterThanOrEqualTo(4));
      expect(generated.any((e) => e.generatedBy == base.id), true);
      // None should be same day as base
      expect(generated.any((e) => isSameDay(e.date, base.date)), false);
    });

    test('generateRecurrentEvents returns empty when recurrence end before start', () {
      final base = CalendarEvent(
        date: DateTime(2025, 1, 10),
        hour: 0,
        endHour: 4,
        departureStation: 'A',
        arrivalStation: 'B',
        isRecurrent: true,
        recurrenceEndDate: DateTime(2025, 1, 5), // end before start
      );
      final visible = List.generate(14, (i) => DateTime(2025, 1, 1).add(Duration(days: i)));
      final generated = generateRecurrentEvents(visible, [base]);
      expect(generated, isEmpty);
    });

    test('generateRecurrentEvents ignores events entirely outside visible range', () {
      final base = CalendarEvent(
        date: DateTime(2025, 2, 1),
        hour: 0,
        endHour: 4,
        departureStation: 'A',
        arrivalStation: 'B',
        isRecurrent: true,
        recurrenceEndDate: DateTime(2025, 3, 1),
      );
      final visible = List.generate(14, (i) => DateTime(2025, 1, 1).add(Duration(days: i)));
      final generated = generateRecurrentEvents(visible, [base]);
      expect(generated, isEmpty);
    });

    test('generateRecurrentEvents includes boundary weeks correctly', () {
      final base = CalendarEvent(
        date: DateTime(2025, 1, 29), // near end of visible window
        hour: 0,
        endHour: 4,
        departureStation: 'A',
        arrivalStation: 'B',
        isRecurrent: true,
        recurrenceEndDate: DateTime(2025, 2, 28),
      );
      final visible = List.generate(35, (i) => DateTime(2025, 1, 1).add(Duration(days: i))); // through Feb 4
      final generated = generateRecurrentEvents(visible, [base]);
      // Next recurrence would be Feb 5 (outside) so none should appear
      expect(generated, isEmpty);
    });
  });
}
