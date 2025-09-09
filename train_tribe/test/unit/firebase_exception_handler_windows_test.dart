import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/utils/firebase_exception_handler.dart';
import 'package:train_tribe/l10n/app_localizations.dart';

class _App extends StatelessWidget {
  final void Function(BuildContext) run;
  const _App(this.run);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: const [AppLocalizations.delegate],
      supportedLocales: const [Locale('en'), Locale('it')],
      home: Builder(builder: (ctx) {
        run(ctx);
        return const SizedBox();
      }),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => FirebaseExceptionHandler.debugIsWindowsOverride = true);
  tearDown(() => FirebaseExceptionHandler.debugIsWindowsOverride = null);

  testWidgets('windows specific unknown-error branch (signIn)', (tester) async {
    late String msg;
    await tester.pumpWidget(_App((c) {
      msg = FirebaseExceptionHandler.signInErrorMessage(c, 'unknown-error');
    }));
    await tester.pump();
    expect(msg.isNotEmpty, true);
  });

  testWidgets('windows specific unknown-error branch (logIn)', (tester) async {
    late String msg;
    await tester.pumpWidget(_App((c) {
      msg = FirebaseExceptionHandler.logInErrorMessage(c, 'unknown-error');
    }));
    await tester.pump();
    expect(msg.isNotEmpty, true);
  });
}
