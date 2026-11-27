import 'package:cupertino_native/cupertino_native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_native_views.dart';

/// Behaviour shared by every component, exercised through [CNSwitch] and
/// [CNSlider] (the simplest hosts).
void main() {
  final ios = TargetPlatformVariant.only(TargetPlatform.iOS);
  final views = FakeNativeViews();

  setUp(views.install);
  tearDown(views.uninstall);

  Widget app(Widget child, {Brightness brightness = Brightness.light}) {
    return CupertinoApp(
      theme: CupertinoThemeData(
        brightness: brightness,
        primaryColor: const Color(0xFF0000FF),
      ),
      home: Center(child: child),
    );
  }

  /// Lets platform view creation and channel messages complete.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump();
  }

  testWidgets('sends full state as ordered creation params', (tester) async {
    await tester.pumpWidget(app(CNSwitch(value: true, onChanged: (_) {})));
    await settle(tester);

    final view = views.single('CupertinoNativeSwitch');
    expect(view.creationMethods, [
      'setBrightness',
      'setValue',
      'setEnabled',
      'setStyle',
    ]);
    expect(view.creationArgs('setValue'), {'value': true});
    expect(view.creationArgs('setStyle'), {'tint': 0xFF0000FF});
    // Nothing changed since creation, so nothing is re-sent.
    expect(view.calls, isEmpty);
  }, variant: ios);

  testWidgets('sends only the methods whose state changed', (tester) async {
    await tester.pumpWidget(app(CNSwitch(value: false, onChanged: (_) {})));
    await settle(tester);
    final view = views.single('CupertinoNativeSwitch');

    await tester.pumpWidget(app(CNSwitch(value: true, onChanged: (_) {})));
    await settle(tester);
    expect(view.methods, ['setValue']);
    expect(view.lastArgs('setValue'), {'value': true});

    view.calls.clear();
    await tester.pumpWidget(app(CNSwitch(value: true, onChanged: (_) {})));
    await settle(tester);
    expect(view.calls, isEmpty);
  }, variant: ios);

  testWidgets('clearing a color sends null instead of keeping the old one', (
    tester,
  ) async {
    Widget slider(Color? thumb) =>
        app(CNSlider(value: 0.5, thumbColor: thumb, onChanged: (_) {}));
    await tester.pumpWidget(slider(const Color(0xFFFF0000)));
    await settle(tester);
    final view = views.single('CupertinoNativeSlider');
    expect(view.creationArgs('setStyle')['thumbTint'], 0xFFFF0000);

    await tester.pumpWidget(slider(null));
    await settle(tester);
    expect(view.lastArgs('setStyle')['thumbTint'], isNull);
  }, variant: ios);

  testWidgets('pushes the value back when the parent rejects a change', (
    tester,
  ) async {
    final reported = <bool>[];
    // The parent never updates `value`, so the toggle must snap back.
    await tester.pumpWidget(
      app(CNSwitch(value: false, onChanged: reported.add)),
    );
    await settle(tester);
    final view = views.single('CupertinoNativeSwitch');

    await view.emit('valueChanged', {'value': true});
    await settle(tester);

    expect(reported, [true]);
    expect(view.methods, ['setValue']);
    expect(view.lastArgs('setValue'), {'value': false});
  }, variant: ios);

  testWidgets('does not echo a change the parent accepted', (tester) async {
    var value = false;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) => app(
          CNSwitch(value: value, onChanged: (v) => setState(() => value = v)),
        ),
      ),
    );
    await settle(tester);
    final view = views.single('CupertinoNativeSwitch');

    await view.emit('valueChanged', {'value': true});
    await settle(tester);

    expect(value, isTrue);
    expect(view.calls, isEmpty);
  }, variant: ios);

  testWidgets('follows brightness and re-resolves dynamic colors', (
    tester,
  ) async {
    Widget control(Brightness brightness) => app(
      CNSwitch(
        value: false,
        color: CupertinoColors.systemRed,
        onChanged: (_) {},
      ),
      brightness: brightness,
    );
    await tester.pumpWidget(control(Brightness.light));
    await settle(tester);
    final view = views.single('CupertinoNativeSwitch');
    final lightTint = view.creationArgs('setStyle')['tint'];

    await tester.pumpWidget(control(Brightness.dark));
    await settle(tester);

    expect(view.lastArgs('setBrightness'), {'isDark': true});
    expect(view.lastArgs('setStyle')['tint'], isNot(lightTint));
  }, variant: ios);

  testWidgets('takes brightness from the platform when the theme has none', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpWidget(
      CupertinoApp(home: CNSwitch(value: false, onChanged: (_) {})),
    );
    await settle(tester);

    final view = views.single('CupertinoNativeSwitch');
    expect(view.creationArgs('setBrightness'), {'isDark': true});
  }, variant: ios);

  testWidgets('reports a failed update and retries it on the next sync', (
    tester,
  ) async {
    Widget control(bool enabled) =>
        app(CNSwitch(value: false, enabled: enabled, onChanged: (_) {}));
    await tester.pumpWidget(control(true));
    await settle(tester);
    final view = views.single('CupertinoNativeSwitch');
    view.onCall = (call) =>
        throw PlatformException(code: 'bad_args', message: 'Missing enabled');

    await tester.pumpWidget(control(false));
    await settle(tester);
    expect(tester.takeException(), isA<PlatformException>());

    view
      ..onCall = null
      ..calls.clear();
    await tester.pumpWidget(control(false));
    await settle(tester);
    expect(view.methods, ['setEnabled']);
  }, variant: ios);

  testWidgets('stops talking to the view once disposed', (tester) async {
    await tester.pumpWidget(app(CNSwitch(value: false, onChanged: (_) {})));
    await settle(tester);
    final view = views.single('CupertinoNativeSwitch');

    await tester.pumpWidget(app(const SizedBox()));
    await view.emit('valueChanged', {'value': true});
    await settle(tester);

    expect(view.calls, isEmpty);
    expect(tester.takeException(), isNull);
  }, variant: ios);

  testWidgets('controller drives the live view and detaches on dispose', (
    tester,
  ) async {
    final controller = CNSliderController();
    await tester.pumpWidget(
      app(CNSlider(value: 0.2, controller: controller, onChanged: (_) {})),
    );
    await settle(tester);
    final view = views.single('CupertinoNativeSlider');

    await controller.setValue(0.9, animated: true);
    expect(view.lastArgs('setValue'), {'value': 0.9, 'animated': true});

    await tester.pumpWidget(app(const SizedBox()));
    view.calls.clear();
    await controller.setValue(0.1);
    expect(view.calls, isEmpty);
  }, variant: ios);

  testWidgets(
    'creates an AppKit view on macOS',
    (tester) async {
      await tester.pumpWidget(app(CNSwitch(value: true, onChanged: (_) {})));
      await settle(tester);

      expect(find.byType(AppKitView), findsOneWidget);
      expect(views.single('CupertinoNativeSwitch').creationArgs('setValue'), {
        'value': true,
      });
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );
}
