import 'package:flutter/material.dart';
import 'dart:math';
import 'l10n/app_localizations.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isSwitch = false;

  final List<String> moodQuestionsKeys = [
    'mood_question_1',
    'mood_question_2',
    'mood_question_3',
    'mood_question_4',
    'mood_question_5',
  ];

  late String selectedMoodQuestionKey;

  @override
  void initState() {
    super.initState();
    selectedMoodQuestionKey = moodQuestionsKeys[Random().nextInt(moodQuestionsKeys.length)];
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Center(
      child: Column(
        children: [
          const Spacer(flex: 1),
          Image.asset(
            'images/djungelskog.jpg',
            height: 200,
            width: 200,
          ),
          const Spacer(flex: 2),
          Text(localizations.translate(selectedMoodQuestionKey), style: const TextStyle(fontSize: 24)), 
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
