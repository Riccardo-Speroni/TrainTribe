import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:train_tribe/main.dart';
import 'package:train_tribe/l10n/app_localizations.dart';
import 'package:train_tribe/utils/app_globals.dart';

class _Probe extends StatelessWidget {
  const _Probe();
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context).translate('friends');
    return Column(
      children: [
        Text(isDark ? 'theme:dark' : 'theme:light'),
        Text(loc, key: const Key('locText')),
      ],
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('MyApp reacts to theme and locale changes via ValueNotifiers', (tester) async {
    // Minimal router with a single route
    final router = GoRouter(
      initialLocation: '/',
      routes: [GoRoute(path: '/', builder: (c, s) => const Scaffold(body: _Probe()))],
    );
    // Ensure globals start at known state
    resetAppGlobals(locale: const Locale('en'), themeMode: ThemeMode.light);

    await tester.pumpWidget(MyApp(router: router));
    await tester.pumpAndSettle();

    expect(find.text('theme:light'), findsOneWidget);
    expect(find.byKey(const Key('locText')), findsOneWidget);
    expect(find.text('Friends'), findsOneWidget);

    // Switch to dark theme
    updateAppTheme(ThemeMode.dark);
    await tester.pumpAndSettle();
    expect(find.text('theme:dark'), findsOneWidget);

    // Switch locale to Italian and expect translation to change
    updateAppLocale(const Locale('it'));
    await tester.pumpAndSettle();
    expect(find.text('Amici'), findsOneWidget);
  });
}
