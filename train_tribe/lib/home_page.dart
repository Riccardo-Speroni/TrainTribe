import 'package:flutter/material.dart';
import 'l10n/app_localizations.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isSwitch = false;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Center(
      child: Column(
        children: [
          const Spacer(flex: 1),
          Image.asset(
            'images/logo.png',
            height: 300,
            width: 300,
          ),
          const Spacer(flex: 2),
          Text(localizations.translate('mood_question'), style: const TextStyle(fontSize: 24)), 
          Switch(
            value: isSwitch,
            onChanged: (bool newBool) {
              setState(() {
                isSwitch = newBool;
              });
            },
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}
