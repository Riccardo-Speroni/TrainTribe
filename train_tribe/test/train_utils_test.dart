import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/utils/train_utils.dart';

void main() {
  group('train_utils', () {
    test('shouldUseShortDayLabels true for narrow width', () {
      // width 600 -> per cell ~83 < 96 needed
      expect(shouldUseShortDayLabels(600), isTrue);
    });
    test('shouldUseShortDayLabels false for wide width', () {
      // width 900 -> per cell ~126 > 96
      expect(shouldUseShortDayLabels(900), isFalse);
    });
    test('routeSignature joins with plus', () {
      expect(routeSignature(['A', 'B', 'C']), 'A+B+C');
      expect(routeSignature([]), '');
    });
  });
}
