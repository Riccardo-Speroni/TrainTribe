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
  // Test hooks
  final void Function(Locale locale)? debugOnSavedLanguage;
  final void Function(ThemeMode mode)? debugOnSavedTheme;

  const LocaleThemeSelector({
    super.key,
    this.showLanguage = true,
    this.showTheme = true,
    this.padding,
    this.iconColor,
    this.spacing = 4,
  this.debugOnSavedLanguage,
  this.debugOnSavedTheme,
  });

  Future<void> _saveLanguage(Locale locale) async {
  appLocale.value = locale; // update immediately for UI
  debugOnSavedLanguage?.call(locale);
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('language_code', locale.languageCode);
  }

  Future<void> _saveTheme(ThemeMode mode) async {
  appTheme.value = mode;
  debugOnSavedTheme?.call(mode);
  final prefs = await SharedPreferences.getInstance();
  final idx = mode == ThemeMode.light ? 0 : (mode == ThemeMode.dark ? 1 : 2);
  await prefs.setInt('theme_mode', idx);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final widgets = <Widget>[];

    if (showLanguage) {
      widgets.add(
        PopupMenuButton<Locale>(
          key: const Key('locale_selector_language'),
          tooltip: l.translate('change_language'),
            icon: Icon(
              Icons.language,
              color: iconColor ?? Theme.of(context).colorScheme.primary,
            ),
          onSelected: (loc) => _saveLanguage(loc),
          itemBuilder: (ctx) => [
            PopupMenuItem(
              key: const Key('locale_item_en'),
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
              key: const Key('locale_item_it'),
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
              key: const Key('locale_selector_theme'),
              tooltip: l.translate('change_theme'),
              icon: Icon(
                icon,
                color: iconColor ?? Theme.of(context).colorScheme.primary,
              ),
              onSelected: (m) => _saveTheme(m),
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  key: const Key('theme_item_light'),
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
                  key: const Key('theme_item_dark'),
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
                  key: const Key('theme_item_system'),
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
