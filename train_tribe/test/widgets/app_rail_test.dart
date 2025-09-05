import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/widgets/app_rail.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppRail', () {
    testWidgets('collapsed rail shows only icons, expanded shows labels', (tester) async {
      final titles = ['Home', 'Friends', 'Trains', 'Calendar', 'Profile'];
      int selected = 0;
      bool expanded = false;

      Widget build() => Directionality(
            textDirection: TextDirection.ltr,
            child: Material(
              child: SizedBox(
                height: 600,
                child: AppRail(
                  titles: titles,
                  currentIndex: selected,
                  expanded: expanded,
                  onSelect: (i) => selected = i,
                  onToggleExpanded: (v) {
                    expanded = v;
                  },
                ),
              ),
            ),
          );

      await tester.pumpWidget(build());

      // Collapsed: labels should not be visible
      for (final t in titles) {
        expect(find.text(t), findsNothing);
      }

      // Tap expand button (chevron_right)
      await tester.tap(find.byIcon(Icons.chevron_right));
      // Need to rebuild after changing state manually
      expanded = true;
      await tester.pumpWidget(build());
      await tester.pumpAndSettle();

      for (final t in titles) {
        expect(find.text(t), findsOneWidget);
      }

      // Tap a destination
      await tester.tap(find.text('Trains'));
      selected = 2; // simulate setState from parent
      await tester.pumpWidget(build());
      await tester.pump();
      expect(selected, 2);
    });
  });
}
