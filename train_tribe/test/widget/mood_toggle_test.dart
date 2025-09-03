import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/l10n/app_localizations.dart';
import 'package:train_tribe/widgets/mood_toggle.dart';
import 'package:train_tribe/utils/mood_repository.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: const [AppLocalizations.delegate],
      supportedLocales: const [Locale('en'), Locale('it')],
      home: Scaffold(body: Center(child: child)),
    );

class _FakeMoodRepository implements MoodRepository {
  int saveCalls = 0;
  final List<bool> savedValues = [];
  final bool loadValue;
  final bool shouldFailSave;
  _FakeMoodRepository({bool loadValue = false, bool shouldFailSave = false})
      : loadValue = loadValue,
        shouldFailSave = shouldFailSave;

  @override
  Future<bool> load(String userId) async => loadValue;

  @override
  Future<void> save(String userId, bool mood) async {
    saveCalls++;
    savedValues.add(mood);
    if (shouldFailSave) {
      throw Exception('fail');
    }
  }
}

void main() {
  testWidgets('mood toggle reflects initialValue and toggles visually + saves', (tester) async {
    bool? changed;
    final repo = _FakeMoodRepository();
    await tester.pumpWidget(_wrap(MoodToggle(
      initialValue: false,
      onChanged: (v) => changed = v,
      repository: repo,
      userIdOverride: 'user1',
      saveDebounce: const Duration(milliseconds: 10), // speed up test
    )));
    await tester.pump();

    expect(find.byIcon(Icons.person_outline), findsOneWidget);

    await tester.tap(find.byType(AnimatedToggleSwitch<bool>));
    await tester.pump();
    // wait debounce
    await tester.pump(const Duration(milliseconds: 20));

    expect(find.byIcon(Icons.groups), findsOneWidget);
    expect(changed, true);
    expect(repo.saveCalls, 1);
    expect(repo.savedValues.single, true);
  });

  testWidgets('mood toggle reverts on save failure and shows snackbar', (tester) async {
    final repo = _FakeMoodRepository(shouldFailSave: true);
    await tester.pumpWidget(_wrap(MoodToggle(
      initialValue: false,
      repository: repo,
      userIdOverride: 'user2',
      saveDebounce: const Duration(milliseconds: 10),
    )));
    await tester.pump();

    expect(find.byIcon(Icons.person_outline), findsOneWidget);

    await tester.tap(find.byType(AnimatedToggleSwitch<bool>));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    // Should have attempted save and failed -> revert to original (person icon)
    expect(repo.saveCalls, 1);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
    // Snackbar displayed
    expect(find.byType(SnackBar), findsOneWidget);
  });
}
