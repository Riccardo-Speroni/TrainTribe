import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/widgets/train_card.dart';
import 'package:flutter/gestures.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: Center(child: SizedBox(width: 600, child: child))));

void main() {
  testWidgets('TrainCard hover toggles internal hover state (desktop/web path)', (tester) async {
    final card = TrainCard(
      title: 'Solution 0',
      isExpanded: false,
      onTap: () {},
      departureTime: '08:00',
      arrivalTime: '09:00',
      isDirect: true,
      userAvatars: const [],
      legs: const [
        {
          'stops': [
            {'name': 'A', 'id': 'A', 'departureTime': '08:00'},
            {'name': 'B', 'id': 'B', 'arrivalTime': '09:00'},
          ],
          'userFrom': 'A',
          'userTo': 'B',
          'isDirect': true,
          'originalFriends': [],
        }
      ],
    );
    await tester.pumpWidget(_wrap(card));
    await tester.pumpAndSettle();

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse, pointer: 1);
    await gesture.addPointer(location: const Offset(1, 1));
    addTearDown(gesture.removePointer);

    final center = tester.getCenter(find.byType(TrainCard));
    await gesture.moveTo(center);
    await tester.pumpAndSettle();
    // No explicit visual assertion; just ensure no exceptions and widget responds to MouseRegion events.

    // Move away to trigger onExit
    await gesture.moveTo(Offset.zero);
    await tester.pumpAndSettle();
  });
}
