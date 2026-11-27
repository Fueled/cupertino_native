---
description: How a cupertino_native component is wired from the Dart widget, through its method channel, to the iOS and macOS native views
---

# Platform View Architecture

Every component is a Flutter widget that embeds a native control through a
platform view, plus a **per-view method channel** for two-way updates. Each
component exists in three places that must stay in sync:

| Layer | iOS | macOS |
|-------|-----|-------|
| Dart widget | `lib/components/<name>.dart` | (same file) |
| Factory | `ios/Classes/Factories/Cupertino<Name>Factory.swift` | `macos/Classes/Factories/Cupertino<Name>Factory.swift` |
| Native view | `ios/Classes/Views/Cupertino<Name>PlatformView.swift` (`FlutterPlatformView`) | `macos/Classes/Views/Cupertino<Name>NSView.swift` (`NSView`) |
| Shared SwiftUI (optional) | `ios/Classes/Shared/<Name>Shared.swift` | `macos/Classes/Shared/<Name>Shared.swift` |
| Registration | `ios/Classes/CupertinoNativePlugin.swift` | `macos/Classes/CupertinoNativePlugin.swift` |
| Export | `lib/cupertino_native.dart` | |
| Demo | `example/lib/demos/<name>.dart` + entry in `example/lib/main.dart` | |

`Shared/` files are **copies**, not a shared target — the iOS and macOS pods are
built separately. Platform-specific differences (`#available(iOS …)` vs
`#available(macOS …)`, `.toggleStyle(.switch)` on macOS, etc.) are expected, so
when editing one copy, check whether the other needs the same change.

## Naming — CRITICAL

These strings must match exactly between Dart and both Swift platforms. A typo
compiles fine and fails silently at runtime.

- Dart class: `CN<Name>` (e.g. `CNSwitch`), optional controller `CN<Name>Controller`.
- View type: `'CupertinoNative<Name>'` — the `viewType` in Dart and the
  `withId:` in both `CupertinoNativePlugin.swift` files.
- Channel: `'CupertinoNative<Name>_$id'` in Dart ↔ `"CupertinoNative<Name>_\(viewId)"` in Swift.
- Method names are camelCase verbs and shared with other components — reuse
  existing names before inventing new ones:
  - Dart → native: `setValue`, `setEnabled`, `setStyle`, `setBrightness`,
    `setSelectedIndex`, `setItems`, `setRange`, `setStep`, `setSymbol`,
    `setPressed`, `getIntrinsicSize`, …
  - Native → Dart: `valueChanged`, `pressed`, `itemSelected`.
- Argument maps use the same keys in Dart and Swift (`'value'`, `'enabled'`,
  `'isDark'`, `'style'`, `'tint'`, …).

## Dart Widget Pattern

Follow `lib/components/switch.dart` / `slider.dart` as the reference:

1. **Fallback first** — on anything other than iOS/macOS, return a Flutter
   equivalent (Material/Cupertino widget) so the widget never crashes elsewhere.
2. **Creation params** — pass the full initial state (including `isDark` and
   `style: encodeStyle(context, tint: …)`) via `StandardMessageCodec`.
3. **`UiKitView` on iOS, `AppKitView` on macOS**, with explicit
   `gestureRecognizers` for the interactions the control needs.
4. **Finite size** — platform views expand to fill unconstrained axes. Always
   wrap in a `SizedBox` with a height and, where it can be unconstrained (e.g.
   inside a `Row`), a width estimate or a size queried via `getIntrinsicSize`.
5. **`_onPlatformViewCreated`** — create the channel, attach the controller,
   set the method-call handler, cache current props, sync brightness.
6. **Diffed sync** — keep `_last*` fields for every prop pushed to native and only
   `invokeMethod` when the value changed (`didUpdateWidget` for props,
   `didChangeDependencies` for theme/brightness).
7. **Resolve theme-dependent values before `await`** (e.g. `resolveColorToArgb`)
   so `context` is not used across an async gap.
8. **`dispose`** — clear the method-call handler and detach the controller.
9. **Controlled widgets** — when native reports a change, call the callback, then
   in a post-frame callback push `widget.value` back to native if the parent did
   not accept the change (see `CNSwitch._onMethodCall`).

Colors always cross the channel as ARGB ints via `lib/channel/params.dart`
(`resolveColorToArgb`, `encodeStyle`) — never encode colors ad hoc.

## Native View Pattern

- Parse creation args defensively from `[String: Any]` with `as? NSNumber` /
  `as? String`, with sensible defaults for missing keys.
- Handle every Dart → native method in a single `switch call.method` and finish
  with `default: result(FlutterMethodNotImplemented)`.
- Every handled method calls `result(...)` exactly once. Bad input returns
  `FlutterError(code: "bad_args", message: "Missing <key>", details: nil)`.
- When Dart sets a value, don't echo it back as a user change (see
  `SwitchModel.setValueFromDart` / `suppressChangeCallback`).
- Apply brightness via `overrideUserInterfaceStyle` (iOS) or
  `NSAppearance(named: .darkAqua / .aqua)` (macOS), and keep backgrounds clear.

## Parity — CRITICAL

A change to a component's API, channel methods, or arguments is not done until
it is implemented on **both** iOS and macOS and visible in the demo page. If a
feature genuinely can't exist on one platform, make it a documented no-op there
rather than leaving the method unhandled.
