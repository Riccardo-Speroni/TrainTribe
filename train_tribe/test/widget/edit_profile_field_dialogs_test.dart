import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/dialogs/edit_profile_field_dialogs.dart';
import 'package:train_tribe/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

AppLocalizations _loc(BuildContext ctx) => AppLocalizations.of(ctx);

Widget buildApp(Widget home) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('it')],
      home: home,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('edit_profile_field_dialogs', () {
    testWidgets('showEditSimpleFieldDialog saves valid change', (tester) async {
      final firestore = FakeFirebaseFirestore();
      final user = MockUser(uid: 'u1', email: 'a@b.c');
      await firestore.collection('users').doc('u1').set({'username': 'old'});

      await tester.pumpWidget(buildApp(Builder(builder: (ctx) {
        return ElevatedButton(
          key: const Key('open_simple_save'),
          onPressed: () => showEditSimpleFieldDialog(
            ctx,
            _loc(ctx),
            fieldKey: 'username',
            currentValue: 'old',
            buildTitle: () => 'Username',
            validator: (v) => v.trim().isEmpty ? 'invalid' : null,
            overrideUser: user,
            overrideFirestore: firestore,
          ),
          child: const Text('open'),
        );
      })));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('open_simple_save')));
      await tester.pumpAndSettle();
      final field = find.byType(TextField);
      expect(field, findsOneWidget);
      await tester.enterText(field, 'newname');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      final snap = await firestore.collection('users').doc('u1').get();
      expect(snap.data()!['username'], 'newname');
    });

    testWidgets('showEditSimpleFieldDialog shows validation error', (tester) async {
      final firestore = FakeFirebaseFirestore();
      final user = MockUser(uid: 'u2', email: 'b@b.c');
      await firestore.collection('users').doc('u2').set({'username': 'old'});
      await tester.pumpWidget(buildApp(Builder(builder: (ctx) {
        return ElevatedButton(
          key: const Key('open_simple_validation'),
          onPressed: () => showEditSimpleFieldDialog(
            ctx,
            _loc(ctx),
            fieldKey: 'username',
            currentValue: 'old',
            buildTitle: () => 'Username',
            validator: (v) => v.trim().length < 3 ? 'invalid' : null,
            overrideUser: user,
            overrideFirestore: firestore,
          ),
          child: const Text('open'),
        );
      })));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('open_simple_validation')));
      await tester.pumpAndSettle();
      final field = find.byType(TextField);
      await tester.enterText(field, 'a');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      // Error text should appear (translated 'invalid' => 'Invalid')
      expect(find.textContaining('Invalid', findRichText: true), findsOneWidget);
      // Ensure no update occurred
      final snap = await firestore.collection('users').doc('u2').get();
      expect(snap.data()!['username'], 'old');
    });

    testWidgets('showEditSimpleFieldDialog async validator prevents save', (tester) async {
      final firestore = FakeFirebaseFirestore();
      final user = MockUser(uid: 'u7', email: 'd@b.c');
      await firestore.collection('users').doc('u7').set({'username': 'old'});
      await tester.pumpWidget(buildApp(Builder(builder: (ctx) {
        return ElevatedButton(
          key: const Key('open_simple_async_validation'),
          onPressed: () => showEditSimpleFieldDialog(
            ctx,
            _loc(ctx),
            fieldKey: 'username',
            currentValue: 'old',
            buildTitle: () => 'Username',
            validator: (v) => v.trim().isEmpty ? 'invalid' : null,
            asyncValidator: (v) async => v == 'taken' ? 'error_username_taken' : null,
            overrideUser: user,
            overrideFirestore: firestore,
          ),
          child: const Text('open'),
        );
      })));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('open_simple_async_validation')));
      await tester.pumpAndSettle();
      final field = find.byType(TextField);
      await tester.enterText(field, 'taken');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      // Error message from translations
      expect(find.textContaining('username is already taken'), findsOneWidget);
      final snap = await firestore.collection('users').doc('u7').get();
      expect(snap.data()!['username'], 'old');
    });

    testWidgets('showEditSimpleFieldDialog cancel does not save', (tester) async {
      final firestore = FakeFirebaseFirestore();
      final user = MockUser(uid: 'u8', email: 'e@b.c');
      await firestore.collection('users').doc('u8').set({'username': 'old'});
      await tester.pumpWidget(buildApp(Builder(builder: (ctx) {
        return ElevatedButton(
          key: const Key('open_simple_cancel'),
          onPressed: () => showEditSimpleFieldDialog(
            ctx,
            _loc(ctx),
            fieldKey: 'username',
            currentValue: 'old',
            buildTitle: () => 'Username',
            overrideUser: user,
            overrideFirestore: firestore,
          ),
          child: const Text('open'),
        );
      })));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('open_simple_cancel')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'newvalue');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      final snap = await firestore.collection('users').doc('u8').get();
      expect(snap.data()!['username'], 'old');
    });

    testWidgets('showEditPhoneDialog saves valid phone', (tester) async {
      final firestore = FakeFirebaseFirestore();
      final user = MockUser(uid: 'u3', email: 'c@b.c');
      await firestore.collection('users').doc('u3').set({'phone': ''});
      await tester.pumpWidget(buildApp(Builder(builder: (ctx) {
        return ElevatedButton(
          key: const Key('open_phone_valid'),
          onPressed: () => showEditPhoneDialog(
            ctx,
            _loc(ctx),
            '',
            overrideUser: user,
            overrideFirestore: firestore,
          ),
          child: const Text('open'),
        );
      })));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('open_phone_valid')));
      await tester.pumpAndSettle();
      final fields = find.byType(TextField);
      expect(fields, findsNWidgets(2));
      await tester.enterText(fields.at(0), '+39');
      await tester.enterText(fields.at(1), '3451234567');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      final snap = await firestore.collection('users').doc('u3').get();
      expect(snap.data()!['phone'], '+393451234567');
    });

    testWidgets('showEditPhoneDialog invalid phone shows error', (tester) async {
      final firestore = FakeFirebaseFirestore();
      final user = MockUser(uid: 'u9', email: 'f@b.c');
      await firestore.collection('users').doc('u9').set({'phone': ''});
      await tester.pumpWidget(buildApp(Builder(builder: (ctx) {
        return ElevatedButton(
          key: const Key('open_phone_invalid'),
          onPressed: () => showEditPhoneDialog(
            ctx,
            _loc(ctx),
            '',
            overrideUser: user,
            overrideFirestore: firestore,
          ),
          child: const Text('open'),
        );
      })));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('open_phone_invalid')));
      await tester.pumpAndSettle();
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '+39');
      await tester.enterText(fields.at(1), '12'); // too short
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      // Error text 'Invalid phone...' appears
      expect(find.textContaining('Invalid phone'), findsOneWidget);
      final snap = await firestore.collection('users').doc('u9').get();
      expect(snap.data()!['phone'], '');
    });
  });
}
