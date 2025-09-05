import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/utils/app_globals.dart';

void main() {
  group('app_globals', () {
    test('updateAppLocale changes notifier value', () {
      final initial = appLocale.value;
      final newLocale = const Locale('it');
      updateAppLocale(newLocale);
      expect(appLocale.value, newLocale);
      // revert
      updateAppLocale(initial);
    });

    test('updateAppTheme changes notifier value', () {
      final initial = appTheme.value;
      updateAppTheme(ThemeMode.dark);
      expect(appTheme.value, ThemeMode.dark);
      updateAppTheme(initial);
    });

    test('resetAppGlobals resets to provided overrides', () {
      updateAppLocale(const Locale('en'));
      updateAppTheme(ThemeMode.light);
      resetAppGlobals(locale: const Locale('fr'), themeMode: ThemeMode.dark);
      expect(appLocale.value, const Locale('fr'));
      expect(appTheme.value, ThemeMode.dark);
    });
  });
}
