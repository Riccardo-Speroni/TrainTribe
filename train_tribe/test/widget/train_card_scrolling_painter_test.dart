import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/widgets/trains_widgets/train_card.dart';

Widget _wrapWithWidth({required double width, double height = 400, required Widget child}) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(width: width, height: height, child: child),
        ),
      ),
    );

List<Map<String, dynamic>> _buildLegs({required int stopsCount, required bool vertical}) {
  final stops = List.generate(stopsCount, (i) {
    return {
      'name': 'Stop $i',
      'arrivalTime': '0${(i + 8) % 10}:00',
      'departureTime': '0${(i + 9) % 10}:10',
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
      'isDirect': true,
      'userFrom': 'S0',
      'userTo': 'S${stopsCount - 1}',
      'originalFriends': <Map<String, dynamic>>[],
    }
  ];
}

void main() {
  testWidgets('Vertical scroll overlay (scrollProgress_v) appears when expanded on narrow width', (tester) async {
    final legs = _buildLegs(stopsCount: 20, vertical: true); // enough items for vertical content
    final card = TrainCard(
      title: 'solution 0',
      isExpanded: true,
      onTap: () {},
      departureTime: '08:00',
      arrivalTime: '09:00',
      isDirect: true,
      userAvatars: const [],
      legs: legs,
    );
    await tester.pumpWidget(_wrapWithWidth(width: 400, height: 700, child: card));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('scrollProgress_v')), findsOneWidget);
  });

  testWidgets('Horizontal scroll overlay (scrollProgress_h) appears when content overflows on wide width', (tester) async {
    // Create many stops so displayedWidth > constraints -> horizontal scroll + overlay
    final legs = _buildLegs(stopsCount: 30, vertical: false);
    final card = TrainCard(
      title: 'solution 0',
      isExpanded: true,
      onTap: () {},
      departureTime: '08:00',
      arrivalTime: '09:00',
      isDirect: true,
      userAvatars: const [],
      legs: legs,
    );
    await tester.pumpWidget(_wrapWithWidth(width: 700, height: 400, child: card));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('scrollProgress_h')), findsOneWidget);
  });
}
