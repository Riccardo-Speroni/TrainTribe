class RedirectContext {
  final bool onboardingComplete;
  final bool isAuthenticated;
  final bool hasProfileComplete;
  final String currentPath; // fullPath in GoRouter

  const RedirectContext({
    required this.onboardingComplete,
    required this.isAuthenticated,
    required this.hasProfileComplete,
    required this.currentPath,
  });
}

/// Pure redirect decision extracted from main.dart for easier unit testing.
/// Returns a path to redirect to, or null if no redirect required.
String? computeRedirect(RedirectContext ctx) {
  // Rule 1: force onboarding if not complete
  if (!ctx.onboardingComplete && ctx.currentPath != '/onboarding') {
    return '/onboarding';
  }

  // Rule 2: unauthenticated user allowed only limited paths
  if (!ctx.isAuthenticated) {
    const allowed = ['/onboarding', '/login', '/signup'];
    if (!allowed.contains(ctx.currentPath)) return '/login';
    return null;
  }

  // Rule 3: profile incomplete -> force complete_signup
  if (!ctx.hasProfileComplete && ctx.currentPath != '/complete_signup') {
    return '/complete_signup';
  }

  // Rule 4: already authed & complete profile: prevent lingering on auth pages
  if (ctx.hasProfileComplete && (ctx.currentPath == '/login' || ctx.currentPath == '/signup')) {
    return '/root';
  }

  return null; // no redirect
}
