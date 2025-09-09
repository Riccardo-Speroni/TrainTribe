import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/utils/profile_picture_widget.dart';

void main() {
  group('ProfilePicture', () {
    testWidgets('renders initials from first and last name', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: ProfilePicture(picture: null, firstName: 'Alice', lastName: 'Brown'),
        ),
      ));
      expect(find.text('AB'), findsOneWidget);
    });

    testWidgets('falls back to username single letter and then ? for none', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: ProfilePicture(picture: null, username: 'charlie'))));
      expect(find.text('C'), findsOneWidget);
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: ProfilePicture(picture: null))));
      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('uses custom non-url picture value as initials trimmed to 2 chars', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: ProfilePicture(picture: ' xyZ  '))));
      expect(find.text('XY'), findsOneWidget);
    });

    testWidgets('shows edit icon when showEditIcon true and triggers onTap', (tester) async {
      int taps = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ProfilePicture(picture: null, firstName: 'Dan', lastName: 'Echo', showEditIcon: true, onTap: () => taps++),
        ),
      ));
      expect(find.byIcon(Icons.edit), findsOneWidget);
      await tester.tap(find.byType(ProfilePicture));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('draws ring when ringWidth > 0', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: ProfilePicture(picture: null, firstName: 'A', lastName: 'B', ringWidth: 3))));
      // Just ensure widget builds; ring adds a Container ancestor
      expect(find.byType(ProfilePicture), findsOneWidget);
    });
  });
}
