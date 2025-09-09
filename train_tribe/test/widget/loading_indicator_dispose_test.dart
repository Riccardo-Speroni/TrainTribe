import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/utils/loading_indicator.dart';

void main() {
  testWidgets('LoadingIndicator disposed before delay does not throw', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoadingIndicator(delay: Duration(milliseconds: 300))));
    await tester.pump(const Duration(milliseconds: 100));
    // Replace entire subtree before delayed future fires.
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pump(const Duration(milliseconds: 400));
  });
}
