import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/widgets/train_card.dart';

Widget _wrap(Widget child, {Size size = const Size(500, 320)}) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(width: size.width, height: size.height, child: child),
        ),
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('dragging on vertical timeline scrolls without exceptions', (tester) async {
    // Many stops to ensure vertical mode
    final List<Map<String, String>> stops = [
      for (int i = 0; i < 20; i++)
        {'name': 'S$i', 'id': 'S$i', if (i == 0) 'departureTime': '08:00' else 'arrivalTime': '08:${(i * 3) % 60}'.padLeft(2, '0')}
    ];
    final card = TrainCard(
      title: 'Solution 0',
      isExpanded: true, // forceShowThumb true
      onTap: () {},
      departureTime: '08:00',
      arrivalTime: '09:00',
      isDirect: false,
      userAvatars: const [],
      legs: [
        {
          'stops': stops,
          'userFrom': 'S2',
          'userTo': 'S15',
          'isDirect': false,
          'originalFriends': [],
        }
      ],
    );
    await tester.pumpWidget(_wrap(card, size: const Size(360, 600)));
    await tester.pumpAndSettle();

    // Ensure vertical progress overlay present
    expect(find.byKey(const ValueKey('scrollProgress_v')), findsOneWidget);

    // Drag vertically on the card area; on mobile this scrolls the inner Scrollable,
    // on desktop it triggers _DesktopDragScroll handlers. Either way should not throw.
    await tester.drag(find.byType(TrainCard), const Offset(0, -80));
    await tester.pumpAndSettle();

    // No explicit assertion besides no exceptions; overlay still present
    expect(find.byKey(const ValueKey('scrollProgress_v')), findsOneWidget);
  });
}
