import 'package:flutter/material.dart';
import 'package:toggle_switch/toggle_switch.dart';
import 'package:train_tribe/main.dart';
import 'l10n/app_localizations.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

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
                  appLocale.value = newLocale; // Update the app's locale
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
            ToggleSwitch(
              totalSwitches: 3,
              labels: [
                localizations.translate('light'),
                localizations.translate('dark'),
                localizations.translate('system'),
              ],
              onToggle: (index) {
                print('switched to: $index');
              },
            ),
            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }
}

