import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animated_toggle_switch/animated_toggle_switch.dart';
// Removed loading overlay

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isSwitch = false;
  // loading removed
  Timer? _debounceTimer;
  Timer? _colorChangeTimer; // timer to delay bg color swap until animation end
  bool _bgIsOn = false; // background color state applied after animation

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
    _loadMood();
  }

  Future<void> _loadMood() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data();
        final mood = data?['mood'];
        if (mounted) {
          setState(() {
            isSwitch = mood == null ? true : (mood as bool);
          });
        }
        // Create field if missing
        if (mood == null) {
          FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({'mood': isSwitch}, SetOptions(merge: true));
        }
      } else {
        // user doc missing: create with default mood true
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({'mood': true}, SetOptions(merge: true));
        if (mounted) {
          setState(() {
            isSwitch = true;
          });
        }
      }
    } catch (e) {
      // ignore
    }
  }

  void _onToggle(bool value) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() {
      isSwitch = value;
    });
    // Delay visual background color change until animation completes (300ms)
    _colorChangeTimer?.cancel();
    _colorChangeTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _bgIsOn = value);
    });
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({'mood': value}, SetOptions(merge: true));
      } catch (e) {
        if (mounted) {
          setState(() => isSwitch = !value); // revert
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(AppLocalizations.of(context)
                    .translate('unexpected_error'))),
          );
        }
      } finally {}
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
  _colorChangeTimer?.cancel();
    super.dispose();
  }

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
              SizedBox(
                width: 260,
                child: AnimatedToggleSwitch<bool>.dual(
                  current: isSwitch,
                  first: false,
                  second: true,
                  spacing: 100.0,
                  style: ToggleStyle(
                    indicatorColor: const Color.fromARGB(255, 255, 255, 255),
                    backgroundColor: _bgIsOn
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.18)
                        : Theme.of(context).colorScheme.error.withOpacity(0.18),
                  ),
                  borderWidth: 4.0,
                  customIconBuilder: (context, local, global) {
                    final value = local.value;
                    return Icon(
                      value ? Icons.groups : Icons.person_outline,
                      color: value ? Colors.green : Colors.red,
                      size: 34,
                    );
                  },
                  height: 70,
                  onChanged: (b) => _onToggle(b),
                  animationCurve: Curves.easeInOut,
                  animationDuration: const Duration(milliseconds: 300),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
