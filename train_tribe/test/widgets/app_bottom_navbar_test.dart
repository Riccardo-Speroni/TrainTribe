import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/widgets/app_bottom_navbar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppBottomNavBar', () {
    testWidgets('renders all destinations and updates selected index on tap', (tester) async {
      final titles = ['Home', 'Friends', 'Trains', 'Calendar', 'Profile'];
      int selected = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) => Scaffold(
              bottomNavigationBar: AppBottomNavBar(
                titles: titles,
                currentIndex: selected,
                onDestinationSelected: (i) => setState(() => selected = i),
              ),
            ),
          ),
        ),
      );

      // All labels present
      for (final t in titles) {
        expect(find.text(t), findsOneWidget);
      }

      // Initial selection index 0
      NavigationBar navBar = tester.widget(find.byType(NavigationBar));
      expect(navBar.selectedIndex, 0);

      // Tap the third destination (index 2)
      await tester.tap(find.text('Trains'));
      await tester.pumpAndSettle();

      navBar = tester.widget(find.byType(NavigationBar));
      expect(navBar.selectedIndex, 2);
    });
  });
}
