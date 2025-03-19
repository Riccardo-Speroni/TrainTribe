import 'package:flutter/material.dart';
import 'package:toggle_switch/toggle_switch.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Center(
        child: Column(
          children: [
            const Spacer(flex: 2),
            Text('Mood Status reset frequency'),
            ToggleSwitch(
              totalSwitches: 3,
              labels: ['Before Each Event', 'Daily', 'Never'],
              onToggle: (index) {
                print('switched to: $index');
              },
            ),
            const Spacer(flex: 1),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
              Icon(Icons.language),
              SizedBox(width: 8),
              Text('Language'),
              ],
            ),
            DropdownButton<String>(
              value: 'English',
              onChanged: (String? newValue) {
                // Handle language change
              },
              items: <String>['English', 'Italian']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            const Spacer(flex: 1),
            SwitchListTile(
              title: const Text('Contacts Access'),
              value: true, // This should be a variable that holds the current state
              onChanged: (bool value) {
                // Handle switch state change
              },
            ),
            const Spacer(flex: 1),
            SwitchListTile(
              title: const Text('Location Access'),
              value: true, // This should be a variable that holds the current state
              onChanged: (bool value) {
                // Handle switch state change
              },
            ),
            const Spacer(flex: 1),
            Text('Theme'),
            ToggleSwitch(
              totalSwitches: 3,
              labels: ['Light', 'Dark', 'System'],
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

