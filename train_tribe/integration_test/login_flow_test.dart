import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App launches and shows onboarding or login', (tester) async {
    // Ensure app main completed (init async work) before pumping frames repeatedly
    app.main();
    // Multiple shorter pump frames to allow Firebase/init tasks without waiting fixed 5s
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    await tester.pumpAndSettle();

    // Accept either onboarding (skip button) or login form depending on stored prefs
    final loginButton = find.textContaining('Login');
    final skipButton = find.textContaining('Skip');
    expect(loginButton.evaluate().isNotEmpty || skipButton.evaluate().isNotEmpty, true,
        reason: 'Should show login (Login text) or onboarding (Skip button)');
  });
}
