import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/main.dart';
import 'package:train_tribe/services/app_services.dart';
import 'package:train_tribe/repositories/user_repository.dart';
import 'package:train_tribe/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Widget _wrapRoot({required double width}) {
  final firestore = FakeFirebaseFirestore();
  final auth = MockFirebaseAuth(mockUser: MockUser(uid: 'u1', email: 'a@b.com'), signedIn: true);
  final services = AppServices(
    firestore: firestore,
    auth: auth,
    userRepository: FirestoreUserRepository(firestore),
  );
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
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, 800)),
        child: const RootPage(),
      ),
    ),
  );
}

void main() {
  testWidgets('RootPage shows bottom NavigationBar on narrow width and switches tabs', (tester) async {
    await tester.pumpWidget(_wrapRoot(width: 500));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    // Tap Friends tab by label
    await tester.tap(find.text('Friends'));
    await tester.pumpAndSettle();
    // Verify NavigationBar index updated by checking selection style
    final nav = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(nav.selectedIndex, 1);
  });

  testWidgets('RootPage shows AppRail on wide width, toggles expansion, and selects Friends tab', (tester) async {
    await tester.pumpWidget(_wrapRoot(width: 900));
    await tester.pumpAndSettle();
    // Collapsed toggle chevron_right present
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.chevron_left), findsOneWidget);
    // Select Friends via icon to switch tab (safe, uses FakeFirestore via AppServicesScope)
    await tester.tap(find.byIcon(Icons.people));
    await tester.pumpAndSettle();
    // Verify Friends page rendered (AppBar title)
    expect(find.text('Friends'), findsWidgets);
  });
}
