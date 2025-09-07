import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/widgets/trains_widgets/train_card.dart' as tc;

Widget _wrap(Widget child, {Size size = const Size(1000, 420)}) => MaterialApp(
      home: Scaffold(body: Center(child: SizedBox(width: size.width, height: size.height, child: child))),
    );

void main() {
  testWidgets('Compact desktop avatars show +N counter when many users at a stop', (tester) async {
    final stops = [
      {'name': 'Start', 'id': 'S0', 'departureTime': '08:00', 'arrivalTime': ''},
      {'name': 'Mid', 'id': 'S1', 'arrivalTime': '08:20', 'departureTime': ''},
      {'name': 'End', 'id': 'S2', 'arrivalTime': '08:40', 'departureTime': ''},
    ];
    // Create 5 users: avatar row shows 4 + "+1"; names list remains compact enough to avoid overflow
    final friends = [
      for (int i = 0; i < 5; i++) {'username': 'U$i', 'picture': '', 'from': 'S0', 'to': 'S2', 'confirmed': false}
    ];
    final card = tc.TrainCard(
      title: 'Solution 0',
      isExpanded: true,
      onTap: () {},
      departureTime: '08:00',
      arrivalTime: '09:00',
      isDirect: false,
      userAvatars: const [],
      legs: [
        {
          'stops': stops,
          'isDirect': false,
          'userFrom': 'S0',
          'userTo': 'S2',
          'originalFriends': friends,
        }
      ],
    );

    // Wide enough to keep horizontal layout and trigger compact desktop path
    // Force desktop UI branch even in test environment
    tc.trainCardDebugForceDesktopUI = true;
    addTearDown(() => tc.trainCardDebugForceDesktopUI = null);
    await tester.pumpWidget(_wrap(card, size: const Size(1100, 520)));
    await tester.pumpAndSettle();

    // We don't have a direct key for '+N'; look for any +N label
    expect(
      find.byWidgetPredicate((w) => w is Text && w.data != null && w.data!.startsWith('+')),
      findsWidgets,
    );
  });
}
