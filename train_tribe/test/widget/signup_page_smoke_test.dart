import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/signup_page.dart';
import 'package:train_tribe/l10n/app_localizations.dart';

void main() {
  testWidgets('SignUpPage initial page renders and next button disabled until email valid', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      localizationsDelegates: [AppLocalizations.delegate],
      supportedLocales: [Locale('en'), Locale('it')],
      home: SignUpPage(),
    ));
    await tester.pump();
    final btn = find.byKey(const Key('signupEmailNextButton'));
    expect(btn, findsOneWidget);
    final buttonWidget = tester.widget<ElevatedButton>(btn);
    expect(buttonWidget.onPressed, isNull); // disabled
  });
}
