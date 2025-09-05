import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:train_tribe/widgets/locale_theme_selector.dart';
import 'package:train_tribe/l10n/app_localizations.dart';
import 'package:train_tribe/utils/app_globals.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    appLocale.value = const Locale('en');
    appTheme.value = ThemeMode.system;
  });

  Future<void> _pump(WidgetTester tester, {Locale? locale}) async {
    await tester.pumpWidget(ValueListenableBuilder<Locale>(
      valueListenable: appLocale,
      builder: (_, loc, __) => MaterialApp(
        locale: loc,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('it')],
        home: Scaffold(body: Center(child: LocaleThemeSelector())),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('changes language to Italian', (tester) async {
    Locale? saved;
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('it')],
      home: Scaffold(body: Center(child: LocaleThemeSelector(debugOnSavedLanguage: (l){ saved = l; }))),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('locale_selector_language')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('locale_item_it')));
    await tester.pumpAndSettle();

    expect(saved, const Locale('it'));
    expect(appLocale.value.languageCode, 'it');
  });

  testWidgets('changes theme to dark', (tester) async {
    ThemeMode? saved;
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('it')],
      home: Scaffold(body: Center(child: LocaleThemeSelector(debugOnSavedTheme: (m){ saved = m; }))),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('locale_selector_theme')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('theme_item_dark')));
    await tester.pumpAndSettle();

    expect(saved, ThemeMode.dark);
    expect(appTheme.value, ThemeMode.dark);
  });
}
