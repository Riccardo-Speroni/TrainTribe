import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/models/calendar_event.dart';

void main() {
  test('CalendarEvent generates unique id when not provided', () {
    final e1 = CalendarEvent(
      date: DateTime(2025, 1, 1),
      hour: 0,
      endHour: 4,
      departureStation: 'A',
      arrivalStation: 'B',
    );
    final e2 = CalendarEvent(
      date: DateTime(2025, 1, 2),
      hour: 4,
      endHour: 8,
      departureStation: 'C',
      arrivalStation: 'D',
    );
    expect(e1.id, isNotEmpty);
    expect(e2.id, isNotEmpty);
    expect(e1.id, isNot(e2.id));
  });
}
