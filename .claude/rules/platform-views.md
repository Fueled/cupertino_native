---
description: How a cupertino_native component is wired from the Dart widget, through its method channel, to the iOS and macOS native views
---

# Platform View Architecture

Every component is a Flutter widget that embeds a native control through a
platform view, plus a **per-view method channel**. The plumbing is shared on
both sides; a component only describes its own state and controls.

| Layer | Where |
|-------|-------|
| Dart host (shared) | `lib/channel/native_view_state.dart` — `NativeViewState` |
| Dart component | `lib/components/<name>.dart` — `CN<Name>` + `_CN<Name>State extends NativeViewState` |
| Native host (shared) | `{ios,macos}/cupertino_native/Sources/cupertino_native/Support/NativeView.swift` — `NativeView`, `NativeViewFactory` |
| Native helpers (shared) | `Support/ChannelArgs.swift`, `Support/SymbolSpec.swift`, `Support/ButtonStyling.swift` |
| Native component | `ios/…/Views/Cupertino<Name>PlatformView.swift`, `macos/…/Views/Cupertino<Name>NSView.swift` |
| Registration | the `viewClasses` list in `{ios,macos}/…/CupertinoNativePlugin.swift` |
| Export | `lib/cupertino_native.dart` |
| Demo | `example/lib/demos/<name>.dart` + entry in `example/lib/main.dart` |

Native code is one Swift package per platform (`ios/cupertino_native/`,
`macos/cupertino_native/`; `…` above is `cupertino_native/Sources/cupertino_native`).
Each platform also has a podspec (`{ios,macos}/cupertino_native.podspec`) for
apps that use CocoaPods; it compiles the same sources. The packages build separately, so `Support/`
exists once per platform. When you change one copy, make the same change in the other.

## The state contract — CRITICAL

A component's native state is a map of **channel method → complete args**:

```dart
@override
NativeState describeNativeState(BuildContext context) => {
  'setValue': {'value': widget.value},
  'setEnabled': {'enabled': widget.enabled},
  'setStyle': {'tint': resolveColorToArgb(widget.color, context)},
};
```

- **Args are always complete.** Every key of a method is sent every time, and
  `null` means "native default". That is how a prop is cleared, so never drop
  a key because its value is null.
- **The same methods create and update.** The host sends the whole state as
  creation params (`{"updates": [[method, args], ...]}`, applied in order),
  then sends only the methods whose args changed. Native code implements each
  method once, as a setter that fully replaces that part of the state.
- **Order matters** where one setter depends on another (e.g. `setRange`
  before `setValue`). Map order is preserved.
- `setBrightness {isDark}` is added by the host. Don't add it yourself.
- Resolve colors with `resolveColorToArgb` and symbols with
  `CNSymbol.encode(context, ...)` (both in `lib/channel/params.dart`), inside
  `describeNativeState`. The host calls it again on theme changes, so dynamic
  colors stay correct.

## Naming — CRITICAL

These strings must match exactly between Dart and both Swift platforms. A
mismatch compiles fine and fails at runtime.

- Dart class: `CN<Name>`, optional controller `CN<Name>Controller`.
- View type: `CupertinoNative<Name>` — `viewType` in Dart and
  `override class var viewType` in both Swift views. The channel name
  (`<viewType>_<id>`) is derived from it on both sides.
- Methods and keys: reuse the existing vocabulary before inventing new names.
  - State: `setValue {value}`, `setRange {min, max}`, `setStep {step}`,
    `setEnabled {enabled}`, `setStyle {tint, ...}`, `setItems {...}`,
    `setSelectedIndex {index}`, `setContent {title, symbol}`, `setSymbol {symbol}`,
    `setLayout {...}`.
  - Commands (not state, sent with `sendNativeCommand`): `setPressed {pressed}`.
  - Queries: `getIntrinsicSize` → `{width, height}`.
  - Events (native → Dart): `valueChanged`, `pressed`, `itemSelected`.
- Symbols travel as the map from `CNSymbol.encode` and are decoded by
  `SymbolSpec` (`name, size, color, paletteColors, mode, gradient`). Lists of
  items are lists of maps, not parallel arrays.

## Dart component pattern

Extend `NativeViewState` and implement:

- `viewType` and `describeNativeState(context)` (above).
- `buildFallback` — a Flutter widget (prefer Cupertino ones, which need no
  `Material` ancestor) for platforms without native views.
- `layoutNativeView` — give the platform view **finite** bounds. Platform views
  expand to fill unbounded axes (e.g. inside a `Row`), so use a fixed size, a
  measured size (`measureNativeView()`), or an estimate until measured.
- `gestureRecognizers` — only the gestures the control needs.
- `handleNativeEvent` — for a user change, call
  `recordNativeState(method, args)` **before** the callback. If the parent
  doesn't accept the change, the host pushes the widget's value back next frame.
- Optional hooks: `didCreateNativeView` (attach controllers, first measure) and
  `didSendNativeUpdates` (re-measure when content changed).

Don't override `build`, `didUpdateWidget` sync logic, or `dispose` channel
handling. The host owns them. Overrides that add behavior must call `super`.

## Native component pattern

```swift
final class CupertinoSwitchPlatformView: NativeView {
  override class var viewType: String { "CupertinoNativeSwitch" }
  private let control = UISwitch()          // controls are stored properties

  override func setUp() { /* build hierarchy, add targets */ }

  override func apply(_ method: String, _ args: ChannelArgs) throws -> Any? {
    switch method {
    case "setValue": control.setOn(try args.required("value", args.bool), animated: false)
    case "setStyle": control.onTintColor = args.color("tint")   // nil resets
    default: return try super.apply(method, args)
    }
    return nil
  }
}
```

- No initializers and no factory. Declare controls as properties, build in
  `setUp()`, and add the class to `viewClasses` in `CupertinoNativePlugin.swift`.
- `apply` handles one method. Return a value only for queries. Throw via
  `args.required(...)` for arguments that must be present. Unknown methods go to
  `super`, which handles `setBrightness` and replies "not implemented".
- Views that rebuild from accumulated state (segments, menus, tab bars) store
  the state in `apply` and render once in `flush()`, which runs after the
  creation batch and after each channel call.
- Send events with `emit(...)`. Don't echo values set from Dart back as user
  changes: programmatic UIKit/AppKit changes don't fire actions, but SwiftUI's
  `onChange` does (see `SwitchModel`).
- Never capture `self` strongly in closures that outlive a call. The base class
  holds the channel handler weakly and clears it in `deinit`.

## Parity — CRITICAL

A change to a component's state methods or args is not done until it is
implemented on **both** iOS and macOS and visible in the demo page. If a
feature can't exist on one platform, accept the method there as a documented
no-op (see macOS `setLayout` in the tab bar) rather than leaving it unhandled.
