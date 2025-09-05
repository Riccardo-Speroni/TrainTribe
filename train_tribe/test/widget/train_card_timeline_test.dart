import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/widgets/train_card.dart';

void main() {
  group('TrainCard timeline', () {
    TrainCard buildCard({required bool expanded, required int stopCount, required int fromIdx, required int toIdx}) {
      final stops = List.generate(
          stopCount,
          (i) => {
                'name': 'Stop $i',
                'arrivalTime': '0${i}:00',
                'departureTime': '0${i}:05',
                'id': 'S$i',
              });
      final leg = {
        'stops': stops,
        'userFrom': 'S$fromIdx',
        'userTo': 'S$toIdx',
        'originalFriends': [
          {'picture': '', 'username': 'Alice', 'from': 'S$fromIdx', 'to': 'S$toIdx', 'confirmed': true, 'user_id': 'u1'}
        ]
      };
      return TrainCard(
        title: 'Solution 0',
        isExpanded: expanded,
        onTap: () {},
        departureTime: '08:00',
        arrivalTime: '09:00',
        isDirect: false,
        userAvatars: const [],
        legs: [leg],
        highlightConfirmed: true,
        currentUserId: 'u1',
      );
    }

    testWidgets('Ellipsis indicators appear in collapsed timeline (initial) with distant user segment', (tester) async {
      // Expanded TrainCard (so timeline shown) but internal timeline is initially collapsed.
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: buildCard(expanded: true, stopCount: 12, fromIdx: 3, toIdx: 8)),
      ));
      await tester.pump();
      // Two ellipsis (+2 hidden at start and +2 hidden at end)
      final ellipsis = find.byKey(const ValueKey('ellipsis_h_2'));
      expect(ellipsis, findsNWidgets(2));
      expect(find.byKey(const ValueKey('timelineWrapper_collapsed')), findsOneWidget);
    });

    testWidgets('Tapping wrapper expands timeline and removes ellipsis', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: buildCard(expanded: true, stopCount: 12, fromIdx: 3, toIdx: 8)),
      ));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('timelineWrapper_collapsed')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('timelineWrapper_expanded')), findsOneWidget);
      // Ellipsis removed after expansion
      expect(find.byKey(const ValueKey('ellipsis_h_2')), findsNothing);
    });

    testWidgets('Scroll progress painter present for many stops (expanded)', (tester) async {
      // Use wide width so timeline stays horizontal (threshold 520 in widget code)
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 800, child: buildCard(expanded: true, stopCount: 30, fromIdx: 5, toIdx: 20)),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('scrollProgress_h')), findsOneWidget);
    });

    testWidgets('Vertical collapsed shows ellipsis and expands; vertical scroll progress visible', (tester) async {
      // Force vertical by using narrow width (<520). Choose from/to to hide 5 on both sides.
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 900,
            child: buildCard(expanded: true, stopCount: 18, fromIdx: 6, toIdx: 11),
          ),
        ),
      ));
      await tester.pump();
      // Two vertical ellipsis with count 5 each when collapsed initially
      expect(find.byKey(const ValueKey('ellipsis_v_5')), findsNWidgets(2));
      expect(find.byKey(const ValueKey('timelineWrapper_collapsed')), findsOneWidget);

      // Expand
      await tester.tap(find.byKey(const ValueKey('timelineWrapper_collapsed')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('timelineWrapper_expanded')), findsOneWidget);
      expect(find.byKey(const ValueKey('ellipsis_v_5')), findsNothing);
      // Vertical scroll progress should be visible when expanded
      expect(find.byKey(const ValueKey('scrollProgress_v')), findsOneWidget);
    });
  });
}
