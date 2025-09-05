import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:train_tribe/widgets/profile_info_box.dart';
import 'package:train_tribe/l10n/app_localizations.dart';
import 'package:train_tribe/dialogs/edit_profile_field_dialogs.dart';

// A helper that injects a fake localization context and allows opening dialogs without Firebase writes.
Widget _app(Widget child) => MaterialApp(
  localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
  supportedLocales: const [Locale('en'), Locale('it')],
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('Edit simple field dialog validation + save (skipWrites)', (tester) async {
    late AppLocalizations l;
    await tester.pumpWidget(_app(Builder(builder: (context){
      l = AppLocalizations.of(context);
      return Column(
        children: [
          TextButton(
            key: const Key('open_simple_btn'),
            onPressed: () => showEditSimpleFieldDialog(
              context,
              l,
              fieldKey: 'username',
              currentValue: 'old',
              buildTitle: () => 'Edit Username',
              validator: (v){ if(v.trim().length < 3) return 'invalid'; return null; },
              skipWrites: true,
              skipAsyncValidation: true,
            ),
            child: const Text('OpenSimple'),
          ),
        ],
      );
    })));
  await tester.pump();
  await tester.tap(find.byKey(const Key('open_simple_btn')));
    await tester.pumpAndSettle();

    // Too short triggers error
    await tester.enterText(find.byKey(const Key('edit_simple_field_input')), 'ab');
    await tester.tap(find.byKey(const Key('edit_simple_field_save')));
    await tester.pump();
    expect(find.text(l.translate('invalid')), findsOneWidget);

    // Fix value
    await tester.enterText(find.byKey(const Key('edit_simple_field_input')), 'abcd');
    await tester.tap(find.byKey(const Key('edit_simple_field_save')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('edit_simple_field_input')), findsNothing); // dialog closed
  });

  testWidgets('Edit phone dialog inline validation + save (skipWrites)', (tester) async {
    late AppLocalizations l;
    await tester.pumpWidget(_app(Builder(builder: (context){
      l = AppLocalizations.of(context);
      return Column(children: [
        TextButton(
          key: const Key('open_phone_btn'),
          onPressed: () => showEditPhoneDialog(
            context,
            l,
            '',
            skipWrites: true,
          ),
          child: const Text('OpenPhone'),
        )
      ]);
    })));
  await tester.pump();
  await tester.tap(find.byKey(const Key('open_phone_btn')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('edit_phone_prefix_input')), '+39');
    await tester.enterText(find.byKey(const Key('edit_phone_number_input')), '123'); // too short
    await tester.tap(find.byKey(const Key('edit_phone_save')));
    await tester.pump();

    // Should show error text translated (invalid phone)
    expect(find.text(l.translate('invalid_phone')), findsWidgets);

    // Provide a longer number
    await tester.enterText(find.byKey(const Key('edit_phone_number_input')), '3451234567');
    await tester.tap(find.byKey(const Key('edit_phone_save')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('edit_phone_save')), findsNothing);
  });
}
