import 'package:flutter/material.dart';
import 'package:toggle_switch/toggle_switch.dart';
import 'package:train_tribe/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n/app_localizations.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _saveLanguagePreference(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);
    appLocale.value = locale;
  }

  Future<void> _saveThemePreference(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', index);
    appTheme.value = index == 0 ? ThemeMode.light : (index == 1 ? ThemeMode.dark : ThemeMode.system);
  }

  Future<int?> _getThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final int? theme_mode = prefs.getInt('theme_mode');
    return theme_mode;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('settings')), 
      ),
      body: Center(
        child: Column(
          children: [
            const Spacer(flex: 2),
            Text(localizations.translate('mood_status')), 
            ToggleSwitch(
              totalSwitches: 3,
              labels: [
                localizations.translate('before_each_event'),
                localizations.translate('daily'),
                localizations.translate('never'),
              ],
              onToggle: (index) {
                print('switched to: $index');
              },
            ),
            const Spacer(flex: 1),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.language),
                const SizedBox(width: 8),
                Text(localizations.translate('language')), 
              ],
            ),
            DropdownButton<Locale>(
              value: Locale(localizations.languageCode()), // Get the current locale
              onChanged: (Locale? newLocale) {
                if (newLocale != null) {
                  _saveLanguagePreference(newLocale); // Save the selected language
                } 
              },
              items: [
                DropdownMenuItem(
                  value: const Locale('en'),
                  child: Text(localizations.translate('english')), 

                ),
                DropdownMenuItem(
                  value: const Locale('it'),
                  child: Text(localizations.translate('italian')), 
                ),
              ],
            ),
            const Spacer(flex: 1),
            SwitchListTile(
              title: Text(localizations.translate('contacts_access')), 
              value: true, // This should be a variable that holds the current state
              onChanged: (bool value) {
                // Handle switch state change
              },
            ),
            const Spacer(flex: 1),
            SwitchListTile(
              title: Text(localizations.translate('location_access')), 
              value: true, // This should be a variable that holds the current state
              onChanged: (bool value) {
                // Handle switch state change
              },
            ),
            const Spacer(flex: 1),
            Text(localizations.translate('theme')), 
            FutureBuilder<int?>(
              future: _getThemePreference(),
              builder: (context, theme) {
                final initialIndex = theme.data ?? 2; // Default to 'system' theme
                return ToggleSwitch(
                  initialLabelIndex: initialIndex,
                  totalSwitches: 3,
                  labels: [
                    localizations.translate('light'),
                    localizations.translate('dark'),
                    localizations.translate('system'),
                  ],
                  onToggle: (index) {
                    if (index != null) {
                      _saveThemePreference(index);
                    }
                  },
                );
              },
            ),
            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }
}

