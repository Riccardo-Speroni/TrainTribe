import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/widgets/calendar_widgets/calendar_cells.dart';

void main() {
  group('CalendarEmptyCell', () {
    testWidgets('highlighted during drag selection', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CalendarEmptyCell(
            cellIndex: 3,
            day: DateTime.now(),
            cellHeight: 20,
            dragStartIndex: 2,
            dragEndIndex: 5,
            dragStartDay: DateTime.now(),
            draggedEvent: null,
            onAddEvent: (_, __) {},
            onLongPressStart: (_, __) {},
            onLongPressMoveUpdate: (_, __, ___, ____) {},
            onLongPressEnd: (_) {},
            scrollController: ScrollController(),
            pageIndex: 0,
          ),
        ),
      ));

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, isNotNull);
    });

    testWidgets('past day returns non-interactive container', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CalendarEmptyCell(
            cellIndex: 0,
            day: DateTime.now().subtract(const Duration(days: 3)),
            cellHeight: 20,
            dragStartIndex: null,
            dragEndIndex: null,
            dragStartDay: null,
            draggedEvent: null,
            onAddEvent: (_, __) {},
            onLongPressStart: (_, __) {},
            onLongPressMoveUpdate: (_, __, ___, ____) {},
            onLongPressEnd: (_) {},
            scrollController: ScrollController(),
            pageIndex: 0,
          ),
        ),
      ));

      // Ensure GestureDetector is not present (only raw Container)
      expect(find.byType(GestureDetector), findsNothing);
    });
  });
}
