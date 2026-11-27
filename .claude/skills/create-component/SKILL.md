---
name: create-component
description: Add a new native component to the plugin end to end — Dart widget, iOS and macOS Swift views, registration, export, demo page, tests, and README. Use when asked to add/wrap a new native iOS/macOS control (e.g. date picker, stepper, toolbar).
---

# Create a New Component

A component is only done when it exists in **all** of the places listed in
`.claude/rules/platform-views.md` and works on both iOS and macOS. Read that rule
first; it defines the state contract every step below relies on. Then pick the
closest existing component as a template:

| New control looks like… | Copy from |
|-------------------------|-----------|
| Value control with `onChanged` (toggle, slider, stepper) | `switch` / `slider` |
| Selection among items | `segmented_control` / `tab_bar` |
| Tappable with title/icon and styles | `button` |
| Menu of items | `popup_menu_button` |
| Display only | `icon` |

Throughout, `<Name>` is PascalCase (`DatePicker`) and `<name>` is snake_case
(`date_picker`).

## Steps

### 0. Plan and confirm
Before writing code, state:
- The native controls: UIKit (iOS) and AppKit (macOS), with SwiftUI only if
  AppKit/UIKit can't do it, plus any APIs above iOS 17 / macOS 12 that need
  `#available` guards.
- The Dart API: constructor params, callbacks, controller methods.
- The state contract: each `set…` method and its complete args, in order;
  events (native → Dart); queries (`getIntrinsicSize`). Reuse existing method
  names (see the rule).
- The Flutter fallback for other platforms.

Ask the user to confirm if any of these are non-obvious.

### 1. Dart widget — `lib/components/<name>.dart`
- `CN<Name>` (`StatefulWidget`), optional `CN<Name>Controller`, and
  `_CN<Name>State extends NativeViewState<CN<Name>>`.
- Implement `viewType`, `describeNativeState`, `buildFallback`,
  `layoutNativeView` (finite size!), and, as needed, `gestureRecognizers`,
  `handleNativeEvent` (with `recordNativeState` for user changes),
  `didCreateNativeView`, `didSendNativeUpdates`.
- `///` docs on every public member (`public_member_api_docs` is enforced).

### 2. Export — `lib/cupertino_native.dart`
Add `export 'components/<name>.dart';` (and any new `style/` file).

### 3. iOS — `ios/cupertino_native/Sources/cupertino_native/Views/Cupertino<Name>PlatformView.swift`
- `final class Cupertino<Name>PlatformView: NativeView` with
  `override class var viewType: String { "CupertinoNative<Name>" }`.
- Controls as stored properties; `setUp()` builds the hierarchy;
  `apply(_:_:)` implements every state method; `flush()` if it renders from
  accumulated state.
- Add `Cupertino<Name>PlatformView.self` to `viewClasses` in
  `ios/cupertino_native/Sources/cupertino_native/CupertinoNativePlugin.swift`.

### 4. macOS — `macos/cupertino_native/Sources/cupertino_native/Views/Cupertino<Name>NSView.swift`
Same as iOS with AppKit, registered in `macos/cupertino_native/Sources/cupertino_native/CupertinoNativePlugin.swift`.
Handle **every** method iOS handles; if one can't apply on macOS, accept it as
a documented no-op.

### 5. Demo — `example/lib/demos/<name>.dart`
- `<Name>DemoPage` in a `CupertinoPageScaffold` with a `CupertinoNavigationBar`
  titled after the component, `SafeArea` + `ListView` with
  `EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0)`.
- Show: default, colored/tinted, disabled, and each meaningful variant; display
  the current value so callbacks are visibly working.
- Add a `CupertinoListTile` in `example/lib/main.dart` under **Components** (or
  **Navigation**) with a fitting SF Symbol and a `CupertinoPageRoute` to the page.
- Add the page to the lists in `example/test/widget_test.dart` and
  `example/integration_test/plugin_integration_test.dart`.

### 6. Tests
Add a `test/components_test.dart` group (creation args, updates, events) and a
`test/fallback_test.dart` case. See `.claude/rules/testing.md`.

### 7. README and CHANGELOG
Add a README section with a usage snippet matching the other components. Ask
the user for a screenshot (`misc/screenshots/<name-with-dashes>.png`) — don't
invent one. Add a CHANGELOG entry.

### 8. Verify
```bash
dart format .
flutter analyze && flutter test
cd example && flutter analyze && flutter test
cd example && flutter build macos --debug && flutter build ios --debug --no-codesign
cd example && flutter test integration_test -d <ios-simulator-id>
cd example && flutter test integration_test -d macos
```
Then check the demo visually on iOS and macOS, in light and dark mode and with
a non-default accent color. Native rendering can't be checked automatically.

## Checklist

- [ ] `lib/components/<name>.dart` extends `NativeViewState`, with docs on all public members
- [ ] Exported from `lib/cupertino_native.dart`
- [ ] iOS view + `viewClasses` entry
- [ ] macOS view + `viewClasses` entry
- [ ] View type and method/arg names identical across Dart / iOS / macOS
- [ ] Every state method handled on both platforms
- [ ] Non-Apple fallback
- [ ] Demo page + home list entry + example test lists
- [ ] Component and fallback tests
- [ ] README section + CHANGELOG entry
- [ ] Analyze clean, tests green, integration test passes on iOS and macOS
