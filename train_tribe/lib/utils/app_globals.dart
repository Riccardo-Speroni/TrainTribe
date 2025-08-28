import 'package:flutter/material.dart';
import 'dart:ui';

// Global notifiers for locale and theme
ValueNotifier<Locale> appLocale = ValueNotifier(PlatformDispatcher.instance.locale);
ValueNotifier<ThemeMode> appTheme = ValueNotifier(ThemeMode.system);