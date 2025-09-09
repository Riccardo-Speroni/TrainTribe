import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/testing/test_root_page.dart';
import 'package:train_tribe/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RootPage adaptive layout & localization', () {
  Widget buildWithWidth(double width, {Locale locale = const Locale('en')}) {
    return MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('it')],
        home: MediaQuery(
          data: MediaQueryData(size: Size(width, 800)),
      child: const TestRootPage(),
        ),
    );
    }

    testWidgets('shows NavigationBar when width < 600', (tester) async {
      await tester.pumpWidget(buildWithWidth(500));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('shows custom AppRail when width >= 600', (tester) async {
      await tester.pumpWidget(buildWithWidth(900));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('rail expansion toggle switches icon', (tester) async {
      await tester.pumpWidget(buildWithWidth(900));
      await tester.pumpAndSettle();
      final expandFinder = find.byIcon(Icons.chevron_right);
      expect(expandFinder, findsOneWidget);
      await tester.tap(expandFinder);
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
    });

    testWidgets('Italian localization labels appear', (tester) async {
      await tester.pumpWidget(buildWithWidth(500, locale: const Locale('it')));
      await tester.pumpAndSettle();
      expect(find.text('Amici'), findsOneWidget);
    });

    testWidgets('bottom navigation changes selected index on tap', (tester) async {
      await tester.pumpWidget(buildWithWidth(500, locale: const Locale('en')));
      await tester.pumpAndSettle();
      NavigationBar nav = tester.widget(find.byType(NavigationBar));
      expect(nav.selectedIndex, 0);
      await tester.tap(find.text('Friends'));
      await tester.pumpAndSettle();
      nav = tester.widget(find.byType(NavigationBar));
      expect(nav.selectedIndex, 1);
    });
  });
}
