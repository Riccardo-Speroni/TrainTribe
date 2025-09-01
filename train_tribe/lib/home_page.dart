import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'l10n/app_localizations.dart';
import 'widgets/mood_toggle.dart';
// Removed loading overlay

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Legacy state for direct toggle removed; only keep question selection here.

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
    selectedMoodQuestionKey =
        moodQuestionsKeys[Random().nextInt(moodQuestionsKeys.length)];
  // Ensure background matches initial switch value.
  _loadMood();
  }

  Future<void> _loadMood() async { /* kept for potential future prefetch; widget handles loading */ }

  @override
  void dispose() { super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 24),
              Image.asset(
        Theme.of(context).brightness == Brightness.light
          ? 'images/complete_logo_black.png'
          : 'images/complete_logo.png',
        width: 300,
              ),
              const SizedBox(height: 31),
              Text(localizations.translate(selectedMoodQuestionKey),
                  style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 24),
              const MoodToggle(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
