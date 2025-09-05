import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:train_tribe/l10n/app_localizations.dart';
import 'package:train_tribe/widgets/friends_widget/suggestions_section.dart';

Widget _wrap(Widget child) => MaterialApp(
  localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
  supportedLocales: const [Locale('en'), Locale('it')],
  home: Scaffold(body: child),
);

void main() {
  testWidgets('shows loading skeletons then suggestions and triggers add', (tester) async {
    final added = <String>[];
    var loading = true;
    List<Map<String, dynamic>> suggestions = [];

    await tester.pumpWidget(StatefulBuilder(builder: (context, setState) {
      return _wrap(SuggestionsSection(
        title: 'Contacts',
        subtitle: 'From your phone book',
        loading: loading,
        contactsRequested: true,
        suggestions: suggestions,
        sentRequests: const [],
        onRefresh: () {
          setState(() { loading = true; });
        },
        onAdd: (uid) => added.add(uid),
      ));
    }));
  await tester.pump();

    // Loading skeleton visible
    expect(find.byKey(const Key('suggestions_section_root')), findsOneWidget);
  expect(find.text('Scanning'), findsOneWidget);

    // Switch to loaded state with data
    await tester.pumpWidget(StatefulBuilder(builder: (context, setState) {
      return _wrap(SuggestionsSection(
        title: 'Contacts',
        subtitle: 'From your phone book',
        loading: false,
        contactsRequested: true,
        suggestions: [
          {'uid': 'u1', 'username': 'alice', 'contactName': 'Alice A'},
          {'uid': 'u2', 'username': 'bob'},
        ],
        sentRequests: const ['u2'],
        onRefresh: () {},
        onAdd: (uid) => added.add(uid),
      ));
    }));
    await tester.pump();

    expect(find.byKey(const Key('suggestion_card_0')), findsOneWidget);
    expect(find.byKey(const Key('suggestion_card_1')), findsOneWidget);

    // Add first
    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pump();
    expect(added, ['u1']);

    // Second is marked sent (check icon)
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('shows empty state when no suggestions', (tester) async {
    await tester.pumpWidget(_wrap(SuggestionsSection(
      title: 'Contacts',
      subtitle: 'From your phone book',
      loading: false,
      contactsRequested: true,
      suggestions: const [],
      sentRequests: const [],
      onRefresh: () {},
      onAdd: (_) {},
    )));
    await tester.pump();

    expect(find.textContaining('No'), findsOneWidget);
  });
}
