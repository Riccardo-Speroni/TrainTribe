import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/widgets/trains_widgets/train_card.dart';

Widget _host(ValueNotifier<double> width, Widget child, {double height = 720}) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: ValueListenableBuilder<double>(
            valueListenable: width,
            builder: (context, w, _) => SizedBox(width: w, height: height, child: child),
          ),
        ),
      ),
    );

List<Map<String, dynamic>> _legsWithManyStops(int count) {
  final stops = List.generate(count, (i) {
    return {
      'name': 'Stop $i',
      'arrivalTime': '0${(8 + i) % 10}:00',
      'departureTime': '0${(9 + i) % 10}:10',
      'platform': '',
      'track': '',
      'id': 'S$i',
    };
  });
  return [
    {
      'stops': stops,
      'trainNumber': 'T1',
      'operator': '',
      'isDirect': false,
      'userFrom': 'S0',
      'userTo': 'S${count - 1}',
      'originalFriends': <Map<String, dynamic>>[],
    },
  ];
}

void main() {
  testWidgets('Progress overlay swaps controllers across layout (didUpdateWidget path)', (tester) async {
    final card = TrainCard(
      title: 'Solution 0',
      isExpanded: true,
      onTap: () {},
      departureTime: '08:00',
      arrivalTime: '09:00',
      isDirect: false,
      userAvatars: const [],
      legs: _legsWithManyStops(28),
    );

    final width = ValueNotifier<double>(520);
    await tester.pumpWidget(_host(width, card));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('scrollProgress_v')), findsOneWidget);

    // Now widen to force horizontal timeline keeping the same subtree
    width.value = 900;
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('scrollProgress_h')), findsOneWidget);
  });
}
