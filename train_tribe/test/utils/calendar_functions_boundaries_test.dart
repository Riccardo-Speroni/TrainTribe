import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/utils/calendar_functions.dart';

void main() {
  group('calendar_functions boundaries', () {
    test('formatTime near wrap-around slots', () {
      expect(formatTime(72), '00:00'); // midnight
      expect(formatTime(73), '00:15');
      expect(formatTime(75), '00:45');
      expect(formatTime(76), '01:00'); // special 25 -> 1 adjustment
    });

    test('getAvailableEndHours returns continuous range after start', () {
      final list = getAvailableEndHours(DateTime(2024), 10);
      expect(list.first, 11);
      expect(list.last, 76);
      // monotonic increasing
      for (int i = 1; i < list.length; i++) {
        expect(list[i], list[i - 1] + 1);
      }
    });
  });
}
