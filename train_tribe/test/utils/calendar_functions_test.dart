import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/models/calendar_event.dart';
import 'package:train_tribe/utils/calendar_functions.dart';

void main() {
  group('calendar_functions', () {
    test('getDays returns correct count & sequence', () {
      final start = DateTime(2024, 1, 1);
      final days = getDays(start, 3);
      expect(days.length, 3);
      expect(days[1], start.add(const Duration(days: 1)));
    });

    test('getWeekDays starts on Monday', () {
      final start = DateTime(2024, 1, 3); // Wednesday
      final days = getWeekDays(start, 7);
      expect(days.first.weekday, 1); // Monday
      expect(days.length, 7);
    });

    test('isSameDay detects equality', () {
      final a = DateTime(2024, 5, 10, 5, 30);
      final b = DateTime(2024, 5, 10, 23, 59);
      expect(isSameDay(a, b), true);
      expect(isSameDay(a, b.add(const Duration(days: 1))), false);
    });

    test('formatTime boundaries', () {
      expect(formatTime(0), '06:00');
      expect(formatTime(1), '06:15');
      // 72 -> 24:00 becomes 00:00
      expect(formatTime(72), '00:00');
    });

    test('isWithinRecurrence respects recurrence window', () {
      final base = DateTime(2024, 1, 1);
      final event = CalendarEvent(
        date: base,
        hour: 0,
        endHour: 4,
        departureStation: 'A',
        arrivalStation: 'B',
        isRecurrent: true,
        recurrenceEndDate: base.add(const Duration(days: 21)),
      );
      expect(isWithinRecurrence(base, event), true);
      expect(isWithinRecurrence(base.add(const Duration(days: 21)), event), true);
      expect(isWithinRecurrence(base.subtract(const Duration(days: 1)), event), false);
      expect(isWithinRecurrence(base.add(const Duration(days: 30)), event), false);
    });

    test('generateRecurrentEvents creates weekly copies inside visible window', () {
      final base = DateTime(2024, 1, 1);
      final event = CalendarEvent(
        date: base,
        hour: 0,
        endHour: 4,
        departureStation: 'A',
        arrivalStation: 'B',
        isRecurrent: true,
        recurrenceEndDate: base.add(const Duration(days: 28)),
      );
      final visible = getDays(base, 35); // 5 weeks
      final copies = generateRecurrentEvents(visible, [event]);
      // Expect 4 copies (weeks after the original within 28 days)
      expect(copies.length, 4);
      // Each copy should have generatedBy pointing to original id
      expect(copies.every((c) => c.generatedBy == event.id), true);
    });
  });
}
