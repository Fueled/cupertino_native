---
paths:
  - "test/**/*.dart"
  - "example/test/**/*.dart"
  - "example/integration_test/**/*.dart"
---

# Testing

## Layout

| File | Covers |
|------|--------|
| `test/native_view_state_test.dart` | Host behavior shared by every component: creation params, diffing, null-clearing, pushback of rejected changes, brightness, errors, disposal, controllers |
| `test/components_test.dart` | Each component's channel contract: what it sends, how it reacts to native events |
| `test/fallback_test.dart` | Flutter fallbacks on non-Apple platforms |
| `test/params_test.dart` | Color resolution and `CNSymbol.encode` |
| `example/test/widget_test.dart` | Every demo page opens (fallbacks) |
| `example/integration_test/` | Every demo page creates its native views on a real simulator / macOS |

A new component needs a `components_test.dart` group and a
`fallback_test.dart` case. A new host behavior needs a
`native_view_state_test.dart` case.

## Faking the native side

Platform views don't render in `flutter test`. `test/support/fake_native_views.dart`
stands in for the native side: it intercepts view creation and decodes the
creation params, records every channel call, and can emit native events.

```dart
final views = FakeNativeViews();
setUp(views.install);
tearDown(views.uninstall);

testWidgets('reports native selection', (tester) async {
  await tester.pumpWidget(app(CNSegmentedControl(/* ... */)));
  await tester.pump(); await tester.pump();     // creation + channel messages

  final view = views.single('CupertinoNativeSegmentedControl');
  expect(view.creationArgs('setItems')['labels'], ['A', 'B']);
  await view.emit('valueChanged', {'index': 1});
  // ... and after a prop change: view.methods, view.lastArgs('setItems')
}, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
```

- Select the platform with `variant: TargetPlatformVariant.only(...)`, never by
  setting `debugDefaultTargetPlatformOverride` by hand.
- Assert on channel traffic (`creationArgs`, `methods`, `lastArgs`), not on
  private state.
- Set `view.onCall` to reply to queries (e.g. `getIntrinsicSize`) or to throw.

## Native behaviour

Rendering and real interaction can't be covered by `flutter test`:

```bash
cd example && flutter test integration_test -d <ios-simulator-id>
cd example && flutter test integration_test -d macos
```

Then check the demo pages visually on **both** platforms, in light and dark
mode, and with a non-default accent color (the example's palette menu).

## Async and Time
Never use real delays in tests. Use `tester.pump()` / `pump(duration)` for
frames and `fake_async` for timers.

## Running Tests
```bash
flutter test                                  # plugin tests
flutter test test/components_test.dart        # single file
cd example && flutter test                    # example widget tests
```
