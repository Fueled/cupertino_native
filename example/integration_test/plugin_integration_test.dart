// Runs the demo app on a real iOS simulator/device or macOS, where the
// components are native platform views:
//
//   cd example && flutter test integration_test -d <device>

import 'package:cupertino_native/cupertino_native.dart';
import 'package:cupertino_native_example/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('every demo page creates its native views', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    for (final (title, component) in [
      ('Slider', CNSlider),
      ('Switch', CNSwitch),
      ('Segmented Control', CNSegmentedControl),
      ('Icon', CNIcon),
      ('Popup Menu Button', CNPopupMenuButton),
      ('Button', CNButton),
      ('Tab Bar', CNTabBar),
    ]) {
      await tester.tap(find.text(title));
      await tester.pumpAndSettle();

      expect(find.byType(component), findsWidgets, reason: title);
      expect(tester.takeException(), isNull, reason: title);

      await tester.tap(find.byType(CupertinoNavigationBarBackButton));
      await tester.pumpAndSettle();
    }
  });
}
