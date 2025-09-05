import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:train_tribe/onboarding_page.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:train_tribe/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Redirect logic (isolated)', () {
    testWidgets('redirects to onboarding when not completed and no user', (tester) async {
      const onboardingComplete = false; // simulated preference value

      final router = GoRouter(
        initialLocation: '/root',
        redirect: (context, state) {
          if (!onboardingComplete && state.matchedLocation != '/onboarding') {
            return '/onboarding';
          }
          return null;
        },
        routes: [
          GoRoute(path: '/onboarding', builder: (c, s) => const OnboardingPage()),
          // root route kept minimal to avoid pulling full app
          GoRoute(path: '/root', builder: (c, s) => const Placeholder()),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('it')],
          locale: const Locale('en'),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(OnboardingPage), findsOneWidget);
    });
  });
}
