---
paths:
  - "ios/**/*.swift"
  - "macos/**/*.swift"
---

# Swift Code Style

See `.claude/rules/platform-views.md` for how native views connect to Dart.

## Formatting
- 2-space indentation, matching the existing files.
- One type per file, named after the file (`CupertinoSliderPlatformView.swift`
  → `class CupertinoSliderPlatformView`).
- iOS imports: `Flutter`, `UIKit`, `SwiftUI` as needed.
  macOS imports: `FlutterMacOS`, `Cocoa`, `SwiftUI` as needed.

## Deployment Targets
- iOS pod targets **iOS 14.0**; macOS pod targets **macOS 11.0**
  (`*/cupertino_native.podspec`).
- Anything newer must be guarded: `if #available(iOS 15.0, *)` /
  `if #available(macOS 12.0, *)`, with a fallback for older systems.
- New-design APIs (e.g. Liquid Glass button styles) need an availability check
  and a graceful fallback to the closest older style.

## UIKit/AppKit vs SwiftUI
- Use the native UIKit/AppKit control when it exists and supports what's needed
  (e.g. `UIButton`, `UISegmentedControl`, `NSPopUpButton`).
- Use SwiftUI via `UIHostingController` / `NSHostingController` only when the
  SwiftUI control is the better match. Put the SwiftUI `View` + `ObservableObject`
  model in `Classes/Shared/<Name>Shared.swift`, and keep hosting backgrounds clear.

## Channel Handling
- Read args with `as? [String: Any]` and `as? NSNumber` / `as? String`; never
  force-cast (`as!`) or force-unwrap channel data.
- `result(...)` must be called exactly once on every path.
- Error code for bad input: `"bad_args"` with a `"Missing <key>"` message.
- End the switch with `default: result(FlutterMethodNotImplemented)`.
- On macOS, capture the channel through a local reference (see
  `CupertinoSwitchNSView`'s `channelRef`) when a closure must be created before
  `super.init`.

## Colors
Colors arrive as ARGB `Int`s. Convert them with the view's
`private static func colorFromARGB(_:)` — copy the existing helper rather than
writing a new conversion.

## Parity
When you change an iOS file, open its macOS counterpart (and vice versa) and
make the equivalent change, or note why it doesn't apply.
