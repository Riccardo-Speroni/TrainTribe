import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/utils/calendar_functions.dart';

void main() {
  test('getWeekDays aligns to Monday and returns requested count', () {
    // Pick a Wednesday
    final start = DateTime(2025, 1, 8); // Wednesday
    final week = getWeekDays(start, 7);
    expect(week.length, 7);
    // First should be Monday 6 Jan 2025
    expect(week.first.weekday, 1);
    expect(week.first, DateTime(2025, 1, 6));
  });
}
