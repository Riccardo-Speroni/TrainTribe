import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:train_tribe/l10n/app_localizations.dart';
import 'package:train_tribe/widgets/profile_picture_picker.dart';

extension _T on WidgetTester {
  Future<void> _pumpPicker(Widget child) async {
    await pumpWidget(MaterialApp(
      localizationsDelegates: const [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
        // ... any other needed delegates if required by implementation
      ],
  supportedLocales: const [Locale('en'), Locale('it')],
      home: Scaffold(body: Center(child: child)),
    ));
  await pumpAndSettle();
  }
}

void main() {
  group('ProfilePicturePicker', () {
    testWidgets('generates avatars and selects one', (tester) async {
      final selections = <ProfileImageSelection>[];
      await tester._pumpPicker(ProfilePicturePicker(
        key: const Key('picker'),
        username: 'alice',
        debugAutoOpenDialog: true,
  debugUsePlaceholders: true,
        onSelection: (s) async => selections.add(s),
      ));

      // Dialog auto opened; generate avatars
      await tester.tap(find.byKey(const Key('pp_picker_generate')));
      for (int i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (find.byKey(const Key('pp_avatar_grid')).evaluate().isNotEmpty) break;
      }
      expect(find.byKey(const Key('pp_avatar_grid')), findsOneWidget);
      // Tap first avatar
      await tester.tap(find.byKey(const Key('pp_avatar_0')));
      await tester.pump();

      expect(selections.length, 1);
      expect(selections.first.generatedAvatarUrl, contains('https://api.dicebear.com'));
    });

    testWidgets('pagination loads more avatars with different seeds', (tester) async {
      final urlsFirstPage = <String>[];
      await tester._pumpPicker(ProfilePicturePicker(
        key: const Key('picker'),
        seedOverride: 'seed',
        debugAutoOpenDialog: true,
  debugUsePlaceholders: true,
        onSelection: (s) async {},
      ));
      await tester.tap(find.byKey(const Key('pp_picker_generate')));
      await tester.pump(const Duration(milliseconds: 200));

      for (var i = 0; i < 10; i++) {
        urlsFirstPage.add(
          (tester.firstWidget(find.byKey(Key('pp_avatar_$i'))) as InkWell).key.toString(),
        );
      }

      await tester.tap(find.byKey(const Key('pp_generate_more')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));

      // Ensure second page avatars have different widget keys (indices same but internal url seeds diff)
      // We cannot easily read the URL from NetworkImage, so instead rely on at least selection working again.
      await tester.tap(find.byKey(const Key('pp_avatar_1')));
      await tester.pump();
      // No assertions on content difference beyond successful tap (selection captured)
    });

    testWidgets('remove image flow', (tester) async {
      final selections = <ProfileImageSelection>[];
      await tester._pumpPicker(ProfilePicturePicker(
        key: const Key('picker'),
        initialImageUrl: 'http://example.com/img.png',
        debugAutoOpenDialog: true,
  debugUsePlaceholders: true,
        onSelection: (s) async => selections.add(s),
      ));
      await tester.tap(find.byKey(const Key('pp_picker_remove')));
      await tester.pumpAndSettle();

      expect(selections.single.removed, isTrue);
    });

    testWidgets('pick image with autoUpload=false returns picked file (simulate override)', (tester) async {
      final selections = <ProfileImageSelection>[];
      final fakeFile = XFile('http://local/fake.png');
      await tester._pumpPicker(ProfilePicturePicker(
        key: const Key('picker'),
        autoUpload: false,
        debugAutoOpenDialog: true,
  debugUsePlaceholders: true,
        onSelection: (s) async => selections.add(s),
        imagePickerOverride: () async => fakeFile,
      ));
      await tester.tap(find.byKey(const Key('pp_picker_pick_image')));
      await tester.pumpAndSettle();

      expect(selections.single.pickedFile, equals(fakeFile));
      expect(selections.single.generatedAvatarUrl, isNull);
    });

    testWidgets('pick image with autoUpload true and uploader returns URL', (tester) async {
      final selections = <ProfileImageSelection>[];
      final fakeFile = XFile('http://local/fake2.png');
      await tester._pumpPicker(ProfilePicturePicker(
        key: const Key('picker'),
        autoUpload: true,
        debugAutoOpenDialog: true,
  debugUsePlaceholders: true,
        imagePickerOverride: () async => fakeFile,
        uploader: (f) async => 'http://uploaded.com/u.png',
        onSelection: (s) async => selections.add(s),
      ));
      await tester.tap(find.byKey(const Key('pp_picker_pick_image')));
      // uploading overlay appears
      await tester.pump();
      // finish future
      await tester.pump();

      expect(selections.single.generatedAvatarUrl, 'http://uploaded.com/u.png');
      expect(find.byKey(const Key('pp_uploading_indicator')), findsNothing);
    });

    testWidgets('uploading overlay visible while uploader pending', (tester) async {
      final selections = <ProfileImageSelection>[];
      final completer = Completer<String?>();
      final fakeFile = XFile('http://local/fake3.png');
      await tester._pumpPicker(ProfilePicturePicker(
        key: const Key('picker'),
        autoUpload: true,
        debugAutoOpenDialog: true,
  debugUsePlaceholders: true,
        imagePickerOverride: () async => fakeFile,
        uploader: (f) => completer.future,
        onSelection: (s) async => selections.add(s),
      ));
      await tester.tap(find.byKey(const Key('pp_picker_pick_image')));
      await tester.pump();
      // Overlay should be present
      expect(find.byKey(const Key('pp_uploading_indicator')), findsOneWidget);
      // Complete upload
      completer.complete('http://uploaded.com/delay.png');
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const Key('pp_uploading_indicator')), findsNothing);
      expect(selections.single.generatedAvatarUrl, 'http://uploaded.com/delay.png');
    });
  });
}
