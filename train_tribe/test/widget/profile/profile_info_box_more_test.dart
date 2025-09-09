import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/l10n/app_localizations.dart';
import 'package:train_tribe/widgets/profile_info_box.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: const [Locale('en')],
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  testWidgets('ProfileInfoBox table layout without picture picker and copy snackbar', (tester) async {
    // Hide picture picker branch
    ProfileInfoBox.debugHidePicturePicker = true;

    await tester.pumpWidget(_wrap(Builder(builder: (context) {
      final l = AppLocalizations.of(context);
      return ProfileInfoBox(
        username: 'table_user',
        name: 'Alice',
        surname: 'Smith',
        email: 'alice@smith.com',
        phone: '',
        picture: null,
        l: l,
        stacked: false, // table layout
      );
    })));
    await tester.pumpAndSettle();

    // Picture picker hidden
    expect(find.byType(Image), findsNothing);

    // Header username shown
    expect(find.text('table_user'), findsWidgets);

    // Table row keys exist
    expect(find.byKey(const ValueKey('profile_row_username')), findsOneWidget);
    expect(find.byKey(const ValueKey('profile_row_name')), findsOneWidget);
    expect(find.byKey(const ValueKey('profile_row_surname')), findsOneWidget);
    expect(find.byKey(const ValueKey('profile_row_email')), findsOneWidget);
    expect(find.byKey(const ValueKey('profile_row_phone_number')), findsOneWidget);

    // Phone empty renders '-'
    expect(find.text('-'), findsWidgets);

    // Copy username emits a SnackBar
    await tester.tap(find.byKey(const Key('profile_username_copy_button')));
    await tester.pump();
    expect(find.byType(SnackBar), findsOneWidget);

    // Reset flag
    ProfileInfoBox.debugHidePicturePicker = false;
  });
}
