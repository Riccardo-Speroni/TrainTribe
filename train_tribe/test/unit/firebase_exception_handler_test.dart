import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/utils/firebase_exception_handler.dart';
import 'package:train_tribe/l10n/app_localizations.dart';

// A minimal test app to provide localization context
class _TestApp extends StatelessWidget {
  final Widget child;
  final Locale locale;
  const _TestApp({required this.child, required this.locale});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: const [AppLocalizations.delegate],
      supportedLocales: const [Locale('en'), Locale('it')],
      home: Scaffold(body: child),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FirebaseExceptionHandler.signInErrorMessage', () {
    Future<String> msg0(WidgetTester tester, String code, {Locale locale = const Locale('en')}) async {
      String? result;
      await tester.pumpWidget(_TestApp(
        locale: locale,
        child: Builder(builder: (context) {
          result = FirebaseExceptionHandler.signInErrorMessage(context, code);
          return const SizedBox();
        }),
      ));
      await tester.pump();
      return result!;
    }

    testWidgets('returns specific translation for known codes', (tester) async {
      final msg = await msg0(tester, 'invalid-email');
      expect(msg.isNotEmpty, true);
      expect(msg, isNot(contains('invalid-email'))); // Should be translated
    });

    testWidgets('falls back to unexpected for unknown code', (tester) async {
      final msg = await msg0(tester, 'some-weird-code');
      expect(msg, isNotEmpty);
    });
  });

  group('FirebaseExceptionHandler.logInErrorMessage', () {
    Future<String> msg0(WidgetTester tester, String code, {Locale locale = const Locale('en')}) async {
      String? result;
      await tester.pumpWidget(_TestApp(
        locale: locale,
        child: Builder(builder: (context) {
          result = FirebaseExceptionHandler.logInErrorMessage(context, code);
          return const SizedBox();
        }),
      ));
      await tester.pump();
      return result!;
    }

    testWidgets('returns credential error for wrong-password', (tester) async {
      final msg = await msg0(tester, 'wrong-password');
      expect(msg.toLowerCase(), contains('invalid')); // English translation snippet
    });

    testWidgets('returns generic for unknown code', (tester) async {
      final msg = await msg0(tester, 'xyz');
      expect(msg.toLowerCase(), isNotEmpty);
    });
  });
}
