import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/widgets/calendar_widgets/calendar_columns.dart';

void main() {
  testWidgets('CalendarTimeColumn shows 19 hourly labels including 00:00', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: CalendarTimeColumn(cellHeight: 5))));
  // Should include midnight label
  expect(find.text('00:00'), findsOneWidget);
  // Count total ':00' labels
  final texts = tester.widgetList<Text>(find.byType(Text));
  final hourLabels = texts.where((t) => RegExp(r'^\d{1,2}:00$').hasMatch(t.data ?? '')).toList();
  expect(hourLabels.length, 19);
  });
}
