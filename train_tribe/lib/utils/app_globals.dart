import 'package:flutter/material.dart';
import 'dart:ui';

// Global notifiers for locale and theme
ValueNotifier<Locale> appLocale = ValueNotifier(PlatformDispatcher.instance.locale);
ValueNotifier<ThemeMode> appTheme = ValueNotifier(ThemeMode.system);

/// Update the global locale (convenience wrapper for tests & UI callbacks)
void updateAppLocale(Locale locale) {
  if (appLocale.value != locale) {
    appLocale.value = locale;
  }
}

/// Update the global theme mode.
void updateAppTheme(ThemeMode mode) {
  if (appTheme.value != mode) {
    appTheme.value = mode;
  }
}

/// Reset globals (used only in tests to ensure clean state).
void resetAppGlobals({Locale? locale, ThemeMode? themeMode}) {
  appLocale.value = locale ?? PlatformDispatcher.instance.locale;
  appTheme.value = themeMode ?? ThemeMode.system;
}