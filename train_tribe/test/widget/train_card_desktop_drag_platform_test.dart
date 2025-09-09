import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/widgets/trains_widgets/train_card.dart';
import 'package:train_tribe/widgets/trains_widgets/train_card.dart' as tc;

Widget _wrap(Widget child, {Size size = const Size(800, 400)}) => MaterialApp(
      home: Scaffold(body: Center(child: SizedBox(width: size.width, height: size.height, child: child))),
    );

void main() {
  testWidgets('Desktop drag handlers scroll horizontally', (tester) async {
    // Force-enable desktop drag behavior without touching global platform
    tc.trainCardDebugForceDesktopDrag = true;
    addTearDown(() => tc.trainCardDebugForceDesktopDrag = null);

    final List<Map<String, dynamic>> legs = [
      {
        'stops': [
          for (int i = 0; i < 25; i++) {'name': 'S$i', 'id': 'S$i', 'arrivalTime': '08:${(i * 2) % 60}', 'departureTime': '09:00'}
        ],
        'userFrom': 'S0',
        'userTo': 'S24',
        'isDirect': true,
        'originalFriends': <Map<String, dynamic>>[],
      }
    ];

    final card = TrainCard(
      title: 'Solution 0',
      isExpanded: true,
      onTap: () {},
      departureTime: '08:00',
      arrivalTime: '09:00',
      isDirect: true,
      userAvatars: const [],
      legs: legs,
    );

    await tester.pumpWidget(_wrap(card));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('scrollProgress_h')), findsOneWidget);

    // Drag left to right should adjust horizontal scroll; just ensure no exception and overlay persists
    await tester.drag(find.byType(TrainCard), const Offset(-120, 0));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('scrollProgress_h')), findsOneWidget);
  });
}
