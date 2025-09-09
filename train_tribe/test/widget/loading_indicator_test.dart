import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/utils/loading_indicator.dart';

void main() {
  testWidgets('loading indicator appears after delay', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoadingIndicator(delay: Duration(milliseconds: 100))));
    // Before delay
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
