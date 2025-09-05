import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:train_tribe/widgets/profile_info_box.dart';
import 'package:train_tribe/l10n/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
  localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
  supportedLocales: const [Locale('en'), Locale('it')],
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('ProfileInfoBox shows values and copy/edit buttons', (tester) async {
    await tester.pumpWidget(_wrap(Builder(builder: (context){
      final l = AppLocalizations.of(context);
      return ProfileInfoBox(
        username: 'user123',
        name: 'John',
        surname: 'Doe',
        email: 'john@doe.com',
        phone: '123456',
        picture: null,
        l: l,
        stacked: true,
      );
    })));
    await tester.pumpAndSettle();

  // username appears twice (header + table row)
  expect(find.text('user123'), findsWidgets);
    expect(find.text('John'), findsOneWidget);
    expect(find.text('Doe'), findsOneWidget);
    expect(find.text('john@doe.com'), findsOneWidget);
    expect(find.text('123456'), findsOneWidget);

    expect(find.byKey(const Key('profile_username_copy_button')), findsOneWidget);
    expect(find.byKey(const Key('profile_username_edit_button')), findsOneWidget);
    expect(find.byKey(const Key('profile_name_edit_button')), findsOneWidget);
    expect(find.byKey(const Key('profile_surname_edit_button')), findsOneWidget);
    expect(find.byKey(const Key('profile_phone_edit_button')), findsOneWidget);
  });
}
