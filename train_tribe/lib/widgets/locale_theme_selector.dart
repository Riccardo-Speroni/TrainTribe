import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_globals.dart';
import '../l10n/app_localizations.dart';

/// Reusable selector row for language and theme.
/// Usage:
///   LocaleThemeSelector(); // both
///   LocaleThemeSelector(showTheme: false); // only language
class LocaleThemeSelector extends StatelessWidget {
  final bool showLanguage;
  final bool showTheme;
  final EdgeInsetsGeometry? padding;
  final Color? iconColor;
  final double spacing;

  const LocaleThemeSelector({
    super.key,
    this.showLanguage = true,
    this.showTheme = true,
    this.padding,
    this.iconColor,
    this.spacing = 4,
  });

  Future<void> _saveLanguage(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);
    appLocale.value = locale;
  }

  Future<void> _saveTheme(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    final idx = mode == ThemeMode.light ? 0 : (mode == ThemeMode.dark ? 1 : 2);
    await prefs.setInt('theme_mode', idx);
    appTheme.value = mode;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final widgets = <Widget>[];

    if (showLanguage) {
      widgets.add(
        PopupMenuButton<Locale>(
          tooltip: l.translate('change_language'),
            icon: Icon(
              Icons.language,
              color: iconColor ?? Theme.of(context).colorScheme.primary,
            ),
          onSelected: (loc) => _saveLanguage(loc),
          itemBuilder: (ctx) => [
            PopupMenuItem(
              value: const Locale('en'),
              child: Row(
                children: [
                  if (appLocale.value.languageCode == 'en') const Icon(Icons.check, size: 16),
                  if (appLocale.value.languageCode == 'en') const SizedBox(width: 6),
                  const Text('English'),
                ],
              ),
            ),
            PopupMenuItem(
              value: const Locale('it'),
              child: Row(
                children: [
                  if (appLocale.value.languageCode == 'it') const Icon(Icons.check, size: 16),
                  if (appLocale.value.languageCode == 'it') const SizedBox(width: 6),
                  const Text('Italiano'),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (showTheme) {
      if (widgets.isNotEmpty) widgets.add(SizedBox(width: spacing));
      widgets.add(
        ValueListenableBuilder<ThemeMode>(
          valueListenable: appTheme,
          builder: (context, mode, _) {
            IconData icon;
            switch (mode) {
              case ThemeMode.light:
                icon = Icons.light_mode;
                break;
              case ThemeMode.dark:
                icon = Icons.dark_mode;
                break;
              case ThemeMode.system:
                icon = Icons.brightness_4;
                break;
            }
            return PopupMenuButton<ThemeMode>(
              tooltip: l.translate('change_theme'),
              icon: Icon(
                icon,
                color: iconColor ?? Theme.of(context).colorScheme.primary,
              ),
              onSelected: (m) => _saveTheme(m),
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: ThemeMode.light,
                  child: Row(
                    children: [
                      if (mode == ThemeMode.light) const Icon(Icons.check, size: 16),
                      if (mode == ThemeMode.light) const SizedBox(width: 6),
                      Text(l.translate('light')),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: ThemeMode.dark,
                  child: Row(
                    children: [
                      if (mode == ThemeMode.dark) const Icon(Icons.check, size: 16),
                      if (mode == ThemeMode.dark) const SizedBox(width: 6),
                      Text(l.translate('dark')),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: ThemeMode.system,
                  child: Row(
                    children: [
                      if (mode == ThemeMode.system) const Icon(Icons.check, size: 16),
                      if (mode == ThemeMode.system) const SizedBox(width: 6),
                      Text(l.translate('system')),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: widgets,
      ),
    );
  }
}
