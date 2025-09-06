import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/widgets/trains_widgets/train_card.dart';

// Build a TrainCard with enough stops to show a timeline and allow expansion.
List<Map<String, dynamic>> _legs() {
  final stops = List.generate(
      8,
      (i) => {
            'id': 'S$i',
            'name': 'Stop $i',
            'arrivalTime': '0${(i + 8) % 10}:00',
            'departureTime': '0${(i + 9) % 10}:10',
            'platform': '',
            'track': '',
          });
  return [
    {
      'stops': stops,
      'trainNumber': 'T1',
      'operator': '',
      'isDirect': true,
      'userFrom': 'S2',
      'userTo': 'S5',
      'originalFriends': <Map<String, dynamic>>[],
    }
  ];
}

Widget _wrap(Widget child, {double width = 600, double height = 500}) => MaterialApp(
      home: Scaffold(body: Center(child: SizedBox(width: width, height: height, child: child))),
    );

void main() {
  testWidgets('Tapping timeline wrapper toggles collapsed/expanded', (tester) async {
    final card = TrainCard(
      title: 'solution 0',
      isExpanded: true,
      onTap: () {},
      departureTime: '08:00',
      arrivalTime: '09:00',
      isDirect: true,
      userAvatars: const [],
      legs: _legs(),
    );
    await tester.pumpWidget(_wrap(card));
    await tester.pumpAndSettle();

    // Starts collapsed
    expect(find.byKey(const ValueKey('timelineWrapper_collapsed')), findsOneWidget);

    // Tap to expand
    await tester.tap(find.byKey(const ValueKey('timelineWrapper_collapsed')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('timelineWrapper_expanded')), findsOneWidget);

    // Tap again to collapse
    await tester.tap(find.byKey(const ValueKey('timelineWrapper_expanded')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('timelineWrapper_collapsed')), findsOneWidget);
  });
}
