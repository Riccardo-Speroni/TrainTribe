import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/widgets/profile_info_box.dart';
import 'package:train_tribe/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class _FakeL extends AppLocalizations {
  _FakeL(): super(const Locale('en'));
  @override
  String translate(String key) => key; // echo keys
  @override
  String languageCode() => 'en';
}

class _FakeLDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _FakeLDelegate();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<AppLocalizations> load(Locale locale) async => _FakeL();
  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: const [
        _FakeLDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      home: Scaffold(body: child),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ProfileInfoBox', () {
    setUp(() {
      ProfileInfoBox.debugHidePicturePicker = true;
    });
  ProfileInfoBox _build({bool stacked = false, String username = 'user1', String name='John', String surname='Doe', String email='john@doe.com', String? phone='123'}) {
      return ProfileInfoBox(
        username: username,
        name: name,
        surname: surname,
        email: email,
        phone: phone,
        picture: null,
    l: _FakeL(),
        stacked: stacked,
      );
    }

    testWidgets('renders basic fields (table layout)', (tester) async {
  await tester.pumpWidget(_wrap(_build()));
  await tester.pump();
      // Row keys available in table layout via embedded Row
      expect(find.byKey(const Key('profile_row_username')), findsOneWidget);
      expect(find.byKey(const Key('profile_row_name')), findsOneWidget);
      expect(find.byKey(const Key('profile_row_surname')), findsOneWidget);
      expect(find.byKey(const Key('profile_row_email')), findsOneWidget);
      expect(find.byKey(const Key('profile_row_phone_number')), findsOneWidget);
  expect(find.text('user1'), findsNWidgets(2)); // header + table row value
      expect(find.text('John'), findsOneWidget);
    });

    testWidgets('renders stacked layout rows with keys', (tester) async {
  await tester.pumpWidget(_wrap(_build(stacked: true)));
  await tester.pump();
      // Each label row uses key 'profile_row_<label>' in lowercase
      expect(find.byKey(const Key('profile_row_username')), findsOneWidget);
      expect(find.byKey(const Key('profile_row_name')), findsOneWidget);
      expect(find.byKey(const Key('profile_row_surname')), findsOneWidget);
      expect(find.byKey(const Key('profile_row_email')), findsOneWidget);
      expect(find.byKey(const Key('profile_row_phone_number')), findsOneWidget);
    });

    testWidgets('shows placeholders when values empty (stacked)', (tester) async {
  await tester.pumpWidget(_wrap(_build(username: '', name: '', surname: '', email: '', phone: '', stacked: true)));
  await tester.pump();
      // dash placeholders for 5 fields
      expect(find.text('-'), findsNWidgets(5));
    });

    testWidgets('copy username button copies only when username present', (tester) async {
  await tester.pumpWidget(_wrap(_build()));
  await tester.pump();
      final copyBtn = find.byKey(const Key('profile_username_copy_button'));
      expect(copyBtn, findsOneWidget);
      await tester.tap(copyBtn);
      await tester.pump();
      // SnackBar appears with 'copied'
      expect(find.text('copied'), findsOneWidget);
    });

    testWidgets('copy username does nothing when empty', (tester) async {
  await tester.pumpWidget(_wrap(_build(username: '')));
  await tester.pump();
      final copyBtn = find.byKey(const Key('profile_username_copy_button'));
      await tester.tap(copyBtn);
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('copied'), findsNothing);
    });
  });
}
