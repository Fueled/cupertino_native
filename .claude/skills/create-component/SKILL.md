---
name: create-component
description: Add a new native component to the plugin end to end — Dart widget, iOS and macOS Swift views, factory registration, export, demo page, and README. Use when asked to add/wrap a new native iOS/macOS control (e.g. date picker, stepper, toolbar).
---

# Create a New Component

A component is only done when it exists in **all** of the places listed in
`.claude/rules/platform-views.md` and works on both iOS and macOS. Read that rule
first, then pick the closest existing component as a template:

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
- The native controls used: UIKit/SwiftUI on iOS, AppKit/SwiftUI on macOS, and the
  minimum OS for any APIs above iOS 14 / macOS 11.
- The Dart API: constructor params, callbacks, controller methods.
- The channel contract: creation params, Dart → native methods, native → Dart events
  (reuse existing method names — see the rule).
- The Flutter fallback for other platforms.

Ask the user to confirm if any of these are non-obvious.

### 1. Dart widget — `lib/components/<name>.dart`
- `CN<Name>` (`StatefulWidget`), optional `CN<Name>Controller`, private `_CN<Name>State`.
- Follow the Dart pattern in `platform-views.md`: fallback, creation params with
  `isDark` + `encodeStyle`, `UiKitView`/`AppKitView`, finite size, `_last*`
  diffed sync, brightness sync, dispose.
- `///` docs on every public member (`public_member_api_docs` is enforced).

### 2. Export — `lib/cupertino_native.dart`
Add `export 'components/<name>.dart';` (and any new `style/` file).

### 3. iOS — `ios/Classes/`
- `Factories/Cupertino<Name>Factory.swift` — copy an existing factory; only the
  class names change.
- `Views/Cupertino<Name>PlatformView.swift` — `FlutterPlatformView`; channel
  `"CupertinoNative<Name>_\(viewId)"`; parse args; handle methods; emit events.
- `Shared/<Name>Shared.swift` — only if the control is SwiftUI-hosted.
- Register in `CupertinoNativePlugin.swift`:
  ```swift
  let <name>Factory = Cupertino<Name>ViewFactory(messenger: registrar.messenger())
  registrar.register(<name>Factory, withId: "CupertinoNative<Name>")
  ```

### 4. macOS — `macos/Classes/`
Same files as iOS, with `Views/Cupertino<Name>NSView.swift` (an `NSView`) and
`registrar.messenger` (property, not method) in `CupertinoNativePlugin.swift`.
Copy any `Shared/` file and adjust availability checks and styling for macOS.

### 5. Demo — `example/lib/demos/<name>.dart`
- `<Name>DemoPage` in a `CupertinoPageScaffold` with a `CupertinoNavigationBar`
  titled after the component, `SafeArea` + `ListView` with
  `EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0)`.
- Show: default, colored/tinted, disabled, and each meaningful variant; display
  the current value so callbacks are visibly working.
- Add a `CupertinoListTile` in `example/lib/main.dart` under **Components** (or
  **Navigation**) with a fitting SF Symbol and a `CupertinoPageRoute` to the page,
  and import the demo file.

### 6. Tests — `test/<name>_test.dart`
Cover fallback rendering, creation params, and channel calls as described in
`.claude/rules/testing.md`.

### 7. README
Add a section with a usage snippet matching the other components. Ask the user
for a screenshot (`misc/screenshots/<name-with-dashes>.png`) — don't invent one.

### 8. Verify
```bash
dart format .
flutter analyze
flutter test
cd example && flutter build macos --debug
cd example && flutter build ios --simulator --debug
```
Then ask the user to run the demo on an iOS simulator and macOS, in light and
dark mode and with a non-default accent color, since native rendering can't be
checked automatically.

## Checklist

- [ ] `lib/components/<name>.dart` with docs on all public members
- [ ] Exported from `lib/cupertino_native.dart`
- [ ] iOS factory + view (+ shared) + registration
- [ ] macOS factory + view (+ shared) + registration
- [ ] View type and channel names identical across Dart / iOS / macOS
- [ ] Every Dart → native method handled on both platforms
- [ ] Non-Apple fallback
- [ ] Demo page + home list entry
- [ ] Tests
- [ ] README section
- [ ] `flutter analyze` clean, `flutter test` green, both example builds compile
