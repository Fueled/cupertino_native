---
paths:
  - "test/**/*.dart"
  - "example/test/**/*.dart"
  - "example/integration_test/**/*.dart"
---

# Testing

## What to Test

Platform views don't render in `flutter test`, so unit/widget tests focus on the
Dart side of the contract:

- **Fallback rendering** — with `debugDefaultTargetPlatformOverride` set to a
  non-Apple platform, the component renders its Flutter fallback and forwards
  callbacks (`onChanged`, `onPressed`, …).
- **Creation params** — on iOS/macOS overrides, find the `UiKitView` /
  `AppKitView` and assert its `viewType` and `creationParams` (including style
  encoding and `isDark`).
- **Channel traffic** — mock the per-view channel (`CupertinoNative<Name>_<id>`)
  and assert that prop changes send the right method + args, and that unchanged
  props send nothing.
- **Native → Dart events** — simulate `valueChanged` / `pressed` /
  `itemSelected` and assert the callback fires (and, for controlled widgets, that
  a rejected change is pushed back to native).
- **Helpers** — pure functions such as `resolveColorToArgb` / `encodeStyle`.

Always reset `debugDefaultTargetPlatformOverride = null` at the end of a test.

## Mocking a Channel

```dart
TestWidgetsFlutterBinding.ensureInitialized();

final calls = <MethodCall>[];
const channel = MethodChannel('CupertinoNativeSwitch_0');

setUp(() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
    calls.add(call);
    return null;
  });
});

tearDown(() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, null);
  calls.clear();
});
```

## Native Behaviour

Native rendering and interaction can't be covered by `flutter test`. Verify them
in the example app on **both** an iOS simulator and macOS, in light and dark
mode, and with a non-default accent color (the example's palette menu). Put
anything worth automating in `example/integration_test/`.

## Async and Time
Never use real delays in tests. Use `tester.pump()` / `pump(duration)` for frames
and `fake_async` for timers.

## Running Tests
```bash
flutter test                                  # plugin tests
flutter test test/<file>_test.dart            # single file
cd example && flutter test                    # example widget tests
cd example && flutter test integration_test   # on a connected device/simulator
```
