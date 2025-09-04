import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/services/app_services.dart';
import 'package:train_tribe/widgets/user_details_page.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:train_tribe/l10n/app_localizations.dart';
import 'fakes/fake_user_repository.dart';

Widget _wrapWithApp(Widget child, AppServices services) {
  return AppServicesScope(
    services: services,
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('it')],
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('UserDetailsPage', () {
    testWidgets('disables action when username taken and enables when unique', (tester) async {
      final fakeRepo = FakeUserRepository()..nextIsUnique = false; // first check returns taken
      final services = AppServices(
        firestore: FakeFirebaseFirestore(),
        auth: MockFirebaseAuth(),
        userRepository: fakeRepo,
      );

      final name = TextEditingController(text: 'John');
      final surname = TextEditingController(text: 'Doe');
      final username = TextEditingController();
      final phone = TextEditingController();

      await tester.pumpWidget(_wrapWithApp(
        UserDetailsPage(
          nameController: name,
          surnameController: surname,
          usernameController: username,
          phoneController: phone,
          onAction: () {},
          actionButtonText: 'Save',
        ),
        services,
      ));
      await tester.pumpAndSettle();

      // Enter a taken username
      final usernameField = find.byKey(const Key('usernameField'));
      await tester.tap(usernameField);
      await tester.pump();
      await tester.enterText(usernameField, 'john');
      await tester.pumpAndSettle();
      final ElevatedButton button = tester.widget(find.byKey(const Key('actionButton')));
      expect(button.onPressed, isNull, reason: 'Button should be disabled when username not unique');

      // Make repo return unique and change text (simulate user editing)
      fakeRepo.nextIsUnique = true;
      await tester.tap(usernameField);
      await tester.pump();
      await tester.enterText(usernameField, 'johnny');
      await tester.pumpAndSettle();
      final ElevatedButton button2 = tester.widget(find.byKey(const Key('actionButton')));
      expect(button2.onPressed, isNotNull, reason: 'Button should enable when username becomes unique');
    });

    testWidgets('composes valid E164 number on action', (tester) async {
      final fakeRepo = FakeUserRepository();
      fakeRepo.nextIsUnique = true;
      final services = AppServices(
        firestore: FakeFirebaseFirestore(),
        auth: MockFirebaseAuth(),
        userRepository: fakeRepo,
      );
      bool tapped = false;
      final name = TextEditingController(text: 'Jane');
      final surname = TextEditingController(text: 'Roe');
      final username = TextEditingController(text: 'janeroe');
      final phone = TextEditingController();

      await tester.pumpWidget(_wrapWithApp(
        UserDetailsPage(
          nameController: name,
          surnameController: surname,
          usernameController: username,
          phoneController: phone,
          onAction: () => tapped = true,
          actionButtonText: 'Save',
        ),
        services,
      ));
      await tester.pumpAndSettle();

      final dialField = find.byKey(const Key('dialField'));
      final phoneField = find.byKey(const Key('phoneField'));
      await tester.tap(dialField);
      await tester.pump();
      await tester.enterText(dialField, '+39');
      await tester.tap(phoneField);
      await tester.pump();
      await tester.enterText(phoneField, '3456789012');
      await tester.pump();
      final actionButton = find.byKey(const Key('actionButton'));
      await tester.ensureVisible(actionButton);
      await tester.pumpAndSettle();
      await tester.tap(actionButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
      expect(phone.text, '+393456789012');
    });
  });
}
