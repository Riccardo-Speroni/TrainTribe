import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/widgets/logo_title.dart';

Widget _wrapWithTheme(Widget child, {Brightness brightness = Brightness.light}) {
  return MaterialApp(
    theme: ThemeData(brightness: brightness),
    home: Scaffold(appBar: AppBar(title: child)),
  );
}

void main() {
  group('LogoTitle', () {
    testWidgets('shows light asset in light theme', (tester) async {
      await tester.pumpWidget(_wrapWithTheme(const LogoTitle(), brightness: Brightness.light));
      final imageWidget = tester.widget<Image>(find.byType(Image));
      final provider = imageWidget.image as AssetImage;
      expect(provider.assetName, equals('images/logo_text_black.png'));
      // default height
      expect(imageWidget.height, 24);
    });

    testWidgets('shows dark asset in dark theme', (tester) async {
      await tester.pumpWidget(_wrapWithTheme(const LogoTitle(), brightness: Brightness.dark));
      final imageWidget = tester.widget<Image>(find.byType(Image));
      final provider = imageWidget.image as AssetImage;
      expect(provider.assetName, equals('images/logo_text.png'));
    });

    testWidgets('applies custom height and padding', (tester) async {
      await tester.pumpWidget(_wrapWithTheme(const LogoTitle(height: 32, padding: EdgeInsets.all(8))));
  // Ensure our custom padding exists (not AppBar's internal padding)
  final paddingFinder = find.byWidgetPredicate((w) => w is Padding && w.padding == const EdgeInsets.all(8));
  expect(paddingFinder, findsOneWidget);
  final padding = tester.widget<Padding>(paddingFinder);
      expect(padding.padding, const EdgeInsets.all(8));
      // Image height overridden
      final imageWidget = tester.widget<Image>(find.byType(Image));
      expect(imageWidget.height, 32);
    });

    testWidgets('has accessible semantics label', (tester) async {
      await tester.pumpWidget(_wrapWithTheme(const LogoTitle()));
      expect(find.bySemanticsLabel('TrainTribe'), findsOneWidget);
    });
  });
}
