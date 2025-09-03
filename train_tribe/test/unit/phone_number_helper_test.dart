import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/utils/phone_number_helper.dart';

void main() {
  group('phone_number_helper', () {
    test('sanitizePrefix keeps digits and + limited to 3', () {
      expect(sanitizePrefix('+391234'), '+391');
      expect(sanitizePrefix('0039'), '+003');
    });

    test('sanitizeNumber strips non digits', () {
      expect(sanitizeNumber('(345) 12-34'), '3451234');
    });

    test('validatePrefix rules', () {
      expect(validatePrefix('+1'), true);
      expect(validatePrefix('+123'), true);
      expect(validatePrefix('+1234'), false);
      expect(validatePrefix('123'), false);
    });

    test('validateNumberLength Italy vs generic', () {
      expect(validateNumberLength('1234567890', '+39'), true);
      expect(validateNumberLength('123456789', '+39'), false);
      expect(validateNumberLength('123456', '+12'), true);
      expect(validateNumberLength('1', '+12'), false);
    });

    test('composeE164 success & failures', () {
      expect(composeE164('+39', '3451234567'), '+393451234567');
      expect(composeE164('+39', '345123456'), isNull); // wrong length for +39
      expect(composeE164('+1', ''), ''); // allowed empty
      expect(composeE164('+abc', '123'), isNull);
    });

    test('splitE164 works', () {
      final parts = splitE164('+393451234567');
      expect(parts, isNotNull);
      expect(parts!.prefix, '+39');
      expect(parts.number, '3451234567');
    });

    test('normalizeRawToE164 handles 00 and national', () {
      expect(normalizeRawToE164('00393451234567'), '+393451234567');
      expect(normalizeRawToE164('3451234567'), '+393451234567');
      expect(normalizeRawToE164(''), isNull);
    });
  });
}
