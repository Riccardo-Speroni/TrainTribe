import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:train_tribe/l10n/app_localizations.dart';
import 'package:train_tribe/widgets/friends_widget/friend_popup_dialog.dart';

Widget _wrap(Widget child) => MaterialApp(
  localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
  supportedLocales: const [Locale('en'), Locale('it')],
  home: Scaffold(body: Builder(builder: (context) => Center(child: child))),
);

void main() {
  testWidgets('friend popup shows buttons and triggers actions', (tester) async {
    bool toggled = false;
    bool deleted = false;

  await tester.pumpWidget(_wrap(TextButton(
      onPressed: () => showDialog(
        context: tester.element(find.byType(TextButton)),
        builder: (_) => FriendPopupDialog(
          friend: 'alice',
          isGhosted: false,
          onDelete: () { deleted = true; Navigator.pop(_); },
          onToggleGhost: () { toggled = true; Navigator.pop(_); },
          hasPhone: true,
          phone: '+123',
        ),
      ),
      child: const Text('Open'),
    )));
  await tester.pump();
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  expect(find.textContaining('alice'), findsOneWidget);
  await tester.tap(find.byKey(const Key('friend_popup_toggle')));
    await tester.pumpAndSettle();
    expect(toggled, isTrue);

    // Reopen to test delete
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('friend_popup_delete')));
    await tester.pumpAndSettle();
    expect(deleted, isTrue);
  });
}
