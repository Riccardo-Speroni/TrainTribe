/// Phone number utilities for sanitization, validation and composition.
library;

const String kItalyPrefix = '+39';
const int kItalyNumberLen = 10;
const int kGenericMinLen = 6; // Adjust if needed
const int kGenericMaxLen = 12; // Adjust if needed

/// Keep only '+' followed by up to 3 digits.
String sanitizePrefix(String input) {
  var digits = input.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length > 3) digits = digits.substring(0, 3);
  return '+$digits';
}

/// Keep only digits for the local number.
String sanitizeNumber(String input) {
  return input.replaceAll(RegExp(r'[^0-9]'), '');
}

/// Validate the prefix: '+' followed by 1-3 digits.
bool validatePrefix(String prefix) => RegExp(r'^\+[0-9]{1,3}$').hasMatch(prefix);

/// Validate that number contains digits only.
bool validateNumberDigits(String number) => RegExp(r'^[0-9]+$').hasMatch(number);

/// Validate number length: Italy (+39) must be 10; otherwise generic bounds.
bool validateNumberLength(String number, String prefix, {int minLen = kGenericMinLen, int maxLen = kGenericMaxLen}) {
  if (prefix == kItalyPrefix) return number.length == kItalyNumberLen;
  return number.length >= minLen && number.length <= maxLen;
}

/// Compose E.164 if valid. Returns '' if empty is allowed and number is empty; null if invalid.
String? composeE164(String prefix, String number, {bool allowEmpty = true, int minLen = kGenericMinLen, int maxLen = kGenericMaxLen}) {
  final p = prefix.trim();
  final n = number.trim();
  if (n.isEmpty) {
    return allowEmpty ? '' : null;
  }
  if (!validatePrefix(p)) return null;
  if (!validateNumberDigits(n)) return null;
  if (!validateNumberLength(n, p, minLen: minLen, maxLen: maxLen)) return null;
  return '$p$n';
}

/// Split an E.164 phone into prefix (+CC) and the remaining number.
class PhoneParts {
  final String prefix; // e.g., +39
  final String number; // e.g., 3451234567
  const PhoneParts(this.prefix, this.number);
}

/// Normalize an arbitrary contact number string to E.164, assuming a default prefix when missing.
String? normalizeRawToE164(
  String raw, {
  String defaultPrefix = kItalyPrefix,
  int minLen = kGenericMinLen,
  int maxLen = kGenericMaxLen,
}) {
  if (raw.trim().isEmpty) return null;
  var s = raw.trim();
  // Convert leading 00 to +
  if (s.startsWith('00')) {
    s = '+${s.substring(2)}';
  }
  if (s.startsWith('+')) {
    // Split and recompose to ensure validation rules apply
    final parts = splitE164(s);
    if (parts == null) return null;
    final number = sanitizeNumber(parts.number);
    return composeE164(parts.prefix, number, allowEmpty: false, minLen: minLen, maxLen: maxLen);
  }
  // Treat as national number
  final digits = sanitizeNumber(s);
  if (digits.isEmpty) return null;
  return composeE164(defaultPrefix, digits, allowEmpty: false, minLen: minLen, maxLen: maxLen);
}

PhoneParts? splitE164(String e164) {
  final raw = e164.trim();
  if (!raw.startsWith('+')) return null;
  final digits = raw.substring(1).replaceAll(RegExp(r'\s'), '');
  if (digits.isEmpty) return null;
  // Prefer +39 when present; otherwise default to first 2 digits, then 1.
  String cc;
  String rest;
  if (digits.startsWith('39') && digits.length > 2) {
    cc = '39';
    rest = digits.substring(2);
  } else if (digits.length >= 2) {
    cc = digits.substring(0, 2);
    rest = digits.substring(2);
  } else {
    cc = digits.substring(0, 1);
    rest = digits.substring(1);
  }
  return PhoneParts('+$cc', rest);
}
