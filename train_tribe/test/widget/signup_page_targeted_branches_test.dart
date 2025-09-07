import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:train_tribe/signup_page.dart';
import 'package:train_tribe/l10n/app_localizations.dart';
import 'package:train_tribe/widgets/logo_pattern_background.dart';
import 'package:train_tribe/utils/loading_indicator.dart';
import 'package:train_tribe/widgets/user_details_page.dart';
import 'package:train_tribe/widgets/profile_picture_picker.dart';
import 'package:image_picker/image_picker.dart';

Widget _wrap(Widget child) => MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('it')],
      home: child,
    );

void main() {
  testWidgets('build shows pattern background on wide screens (desktop/web)', (tester) async {
    await tester.pumpWidget(_wrap(const SignUpPage()));
    await tester.pumpAndSettle();

    // On non-mobile, LogoPatternBackground should wrap the content
    expect(find.byType(LogoPatternBackground), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
    // And the "already have account" link is visible on page 0
    expect(find.text('Already have an account? Login'), findsOneWidget);
  });

  testWidgets('wide-screen: shows correct page content and login link only on page 0', (tester) async {
    await tester.pumpWidget(_wrap(const SignUpPage()));
    await tester.pump();

    final state = tester.state<SignUpPageState>(find.byType(SignUpPage));
    state.setForceWideScreenForTest(true);
    await tester.pumpAndSettle();

    // Page 0: link visible
    expect(find.text('Already have an account? Login'), findsOneWidget);
    // Navigate to page 1
    await tester.enterText(find.byType(TextField).first, 'user@example.com');
    await tester.pump();
    await tester.tap(find.byKey(const Key('signupEmailNextButton')));
    await tester.pumpAndSettle();
    expect(find.text('Already have an account? Login'), findsNothing);
    // Navigate to page 2
    await tester.enterText(find.byKey(const Key('signupPasswordField')), 'Abcd1234');
    await tester.enterText(find.byKey(const Key('signupConfirmPasswordField')), 'Abcd1234');
    await tester.pump();
    await tester.tap(find.byKey(const Key('signupPasswordNextButton')));
    await tester.pumpAndSettle();
    expect(find.text('Already have an account? Login'), findsNothing);
  });

  testWidgets('build shows PageView and bottom login link on mobile branch', (tester) async {
    await tester.pumpWidget(_wrap(const SignUpPage()));
    await tester.pump();
    // Force mobile branch via test seam
    final state = tester.state<SignUpPageState>(find.byType(SignUpPage));
    state.setForceWideScreenForTest(false);
    await tester.pumpAndSettle();

    // PageView present, bottom login link visible and centered
    expect(find.byType(PageView), findsOneWidget);
    expect(find.text('Already have an account? Login'), findsOneWidget);
  });

  testWidgets('_showErrorDialog displays an alert with message and dismisses', (tester) async {
    await tester.pumpWidget(_wrap(const SignUpPage()));
    await tester.pump();

    final state = tester.state<SignUpPageState>(find.byType(SignUpPage));
    state.showErrorDialogForTest('Oops');
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.textContaining('Oops'), findsOneWidget);

    await tester.tap(find.text('OK')); // uses localized 'ok' but English maps to 'OK'
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('_createUserInFirebase blocks invalid phone format before Firebase call', (tester) async {
    await tester.pumpWidget(_wrap(const SignUpPage()));
    await tester.pumpAndSettle();

    final state = tester.state<SignUpPageState>(find.byType(SignUpPage));

    // Fill fields with minimal valid values
    state.emailController.text = 'user@example.com';
    state.passwordController.text = 'Abcd1234';
    state.confirmPasswordController.text = 'Abcd1234';
    state.usernameController.text = 'uniqueuser';
    state.firstNameController.text = 'John';
    state.lastNameController.text = 'Doe';
    // Invalid phone that is non-empty and not E.164-like
    state.phoneController.text = '12345';

    // Call through test hook
    await state.createUserForTest();
    await tester.pumpAndSettle();

    // Expect an error dialog for invalid phone and no navigation attempt
    expect(find.byType(AlertDialog), findsOneWidget);
    // Loading overlay should not be visible afterwards
    expect(find.byType(LoadingIndicator), findsNothing);
  });

  testWidgets('_buildUserDetailsPage renders on page 2 and back button navigates back', (tester) async {
    await tester.pumpWidget(_wrap(const SignUpPage()));
    await tester.pump();

    // Navigate: email -> password -> details
    // Enter a valid email to enable the next button
    await tester.enterText(find.byType(TextField).first, 'user@example.com');
    await tester.pump();
    await tester.tap(find.byKey(const Key('signupEmailNextButton')));
    await tester.pumpAndSettle();
    // Password inputs to satisfy conditions
    await tester.enterText(find.byKey(const Key('signupPasswordField')), 'Abcd1234');
    await tester.enterText(find.byKey(const Key('signupConfirmPasswordField')), 'Abcd1234');
    await tester.pump();
    await tester.tap(find.byKey(const Key('signupPasswordNextButton')));
    await tester.pumpAndSettle();

    // Fill mandatory fields so action button would be enabled (not strictly needed for back)
    final state = tester.state<SignUpPageState>(find.byType(SignUpPage));
    state.firstNameController.text = 'John';
    state.lastNameController.text = 'Doe';
    state.usernameController.text = 'jdoe';
    await tester.pump();

    // Now details page should be visible; back button exists
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);

    // Tap back should navigate to password page (field visible)
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('signupPasswordField')), findsOneWidget);
  });

  testWidgets('_buildUserDetailsPage onAction trims fields and triggers create without Firebase', (tester) async {
    await tester.pumpWidget(_wrap(const SignUpPage()));
    await tester.pump();

    final state = tester.state<SignUpPageState>(find.byType(SignUpPage));
    state.setSkipFirebaseForTest(true);

    // Navigate to details page
    await tester.enterText(find.byType(TextField).first, 'user@example.com');
    await tester.pump();
    await tester.tap(find.byKey(const Key('signupEmailNextButton')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('signupPasswordField')), 'Abcd1234');
    await tester.enterText(find.byKey(const Key('signupConfirmPasswordField')), 'Abcd1234');
    await tester.pump();
    await tester.tap(find.byKey(const Key('signupPasswordNextButton')));
    await tester.pumpAndSettle();

    // Set controllers directly with extra spaces to test trimming (avoid AppServicesScope)
    state.firstNameController.text = '  John  ';
    state.lastNameController.text = '  Doe ';
    state.usernameController.text = '  jdoe  ';
    await tester.pump();

    // Trigger UserDetailsPage validations by sending onChanged events
    await tester.enterText(find.byKey(const Key('nameField')), state.firstNameController.text);
    await tester.enterText(find.byKey(const Key('surnameField')), state.lastNameController.text);
    await tester.enterText(find.byKey(const Key('usernameField')), state.usernameController.text);
    await tester.pump();

    // Trigger onAction via test seam (trims + create without Firebase)
    state.onActionForTest();
    await tester.pumpAndSettle();

    // After onAction & createUser (skipped), no dialogs, and controllers are trimmed
    expect(state.firstNameController.text, 'John');
    expect(state.lastNameController.text, 'Doe');
    expect(state.usernameController.text, 'jdoe');
  });

  testWidgets('_buildUserDetailsPage profile image selection branches update state', (tester) async {
    await tester.pumpWidget(_wrap(const SignUpPage()));
    await tester.pump();

    final state = tester.state<SignUpPageState>(find.byType(SignUpPage));
    state.setSkipFirebaseForTest(true);

    // Navigate to details page quickly
    await tester.enterText(find.byType(TextField).first, 'user@example.com');
    await tester.pump();
    await tester.tap(find.byKey(const Key('signupEmailNextButton')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('signupPasswordField')), 'Abcd1234');
    await tester.enterText(find.byKey(const Key('signupConfirmPasswordField')), 'Abcd1234');
    await tester.pump();
    await tester.tap(find.byKey(const Key('signupPasswordNextButton')));
    await tester.pumpAndSettle();

    // Call onProfileImageSelected via the UserDetailsPage widget
    final udWidget = tester.widget<UserDetailsPage>(find.byType(UserDetailsPage));

    // 1) generated avatar URL
    udWidget.onProfileImageSelected!(const ProfileImageSelection(generatedAvatarUrl: 'http://example.com/a.png'));
    await tester.pump();
    expect(state.generatedAvatarUrlForTest, 'http://example.com/a.png');
    expect(state.profileImageForTest, isNull);

    // 2) picked XFile
    final xf = XFile('C:/tmp/pic.png');
    udWidget.onProfileImageSelected!(ProfileImageSelection(pickedFile: xf));
    await tester.pump();
    expect(state.profileImageForTest, isNotNull);
    expect(state.generatedAvatarUrlForTest, isNull);

    // 3) removal
    udWidget.onProfileImageSelected!(const ProfileImageSelection(removed: true));
    await tester.pump();
    expect(state.profileImageForTest, isNull);
    expect(state.generatedAvatarUrlForTest, isNull);
  });
}
