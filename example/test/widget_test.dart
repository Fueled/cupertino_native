import 'package:cupertino_native_example/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

/// Runs the demo app on the test platform (no native views), where every
/// component renders its Flutter fallback.
void main() {
  const demos = [
    'Slider',
    'Switch',
    'Segmented Control',
    'Icon',
    'Popup Menu Button',
    'Button',
    'Tab Bar',
  ];

  testWidgets('home page lists every demo', (tester) async {
    await tester.pumpWidget(const MyApp());

    for (final demo in demos) {
      expect(find.text(demo), findsOneWidget);
    }
  });

  for (final demo in demos) {
    testWidgets('$demo demo opens without errors', (tester) async {
      await tester.pumpWidget(const MyApp());

      await tester.tap(find.text(demo));
      await tester.pumpAndSettle();

      expect(find.byType(CupertinoNavigationBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
