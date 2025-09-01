import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/utils/redirect_logic.dart';

void main() {
  group('computeRedirect', () {
    test('redirects to onboarding when not complete', () {
      final r = computeRedirect(const RedirectContext(
        onboardingComplete: false,
        isAuthenticated: false,
        hasProfileComplete: false,
        currentPath: '/login',
      ));
      expect(r, '/onboarding');
    });

    test('redirects unauthenticated to /login when accessing /root', () {
      final r = computeRedirect(const RedirectContext(
        onboardingComplete: true,
        isAuthenticated: false,
        hasProfileComplete: false,
        currentPath: '/root',
      ));
      expect(r, '/login');
    });

    test('redirects to complete_signup if profile incomplete', () {
      final r = computeRedirect(const RedirectContext(
        onboardingComplete: true,
        isAuthenticated: true,
        hasProfileComplete: false,
        currentPath: '/root',
      ));
      expect(r, '/complete_signup');
    });

    test('redirects to /root if already authed and on /login', () {
      final r = computeRedirect(const RedirectContext(
        onboardingComplete: true,
        isAuthenticated: true,
        hasProfileComplete: true,
        currentPath: '/login',
      ));
      expect(r, '/root');
    });

    test('no redirect when all conditions satisfied', () {
      final r = computeRedirect(const RedirectContext(
        onboardingComplete: true,
        isAuthenticated: true,
        hasProfileComplete: true,
        currentPath: '/root',
      ));
      expect(r, isNull);
    });
  });
}
