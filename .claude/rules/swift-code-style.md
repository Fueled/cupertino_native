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
  → `class CupertinoSliderPlatformView`); shared helpers live in `Classes/Support/`.
- iOS imports: `Flutter`, `UIKit`, `SwiftUI` as needed.
  macOS imports: `Cocoa`, `FlutterMacOS`, `SwiftUI` as needed.
- Mark view classes `final`.

## Deployment Targets
- iOS pod targets **iOS 18.0**; macOS pod targets **macOS 12.0**
  (`*/cupertino_native.podspec`). Don't add `#available` checks for versions at
  or below these.
- Anything newer must be guarded, with a fallback for older systems.
- iOS/macOS 26 APIs (Liquid Glass, symbol gradients) also need a compile-time
  guard so the plugin still builds with older Xcode:
  ```swift
  #if compiler(>=6.2)
  if #available(iOS 26.0, *) { return .glass() }
  #endif
  return .tinted()
  ```

## UIKit/AppKit vs SwiftUI
- Prefer the UIKit/AppKit control (`UISwitch`, `NSSlider`, `UISegmentedControl`):
  programmatic changes don't fire actions, so nothing is echoed to Dart.
- Use SwiftUI only when AppKit/UIKit can't do the job (e.g. tinting a macOS
  switch). Put the view + `ObservableObject` model in `Classes/Shared/`, host it
  with `NSHostingView`/`UIHostingController`, and suppress echoes of
  Dart-set values (see `SwitchModel`).

## Channel Handling
- Read arguments only through `ChannelArgs` (`args.bool`, `args.color`,
  `args.args`, `args.argsList`, ...). Never force-cast or force-unwrap channel data.
- Required arguments: `try args.required("key", args.bool)`. This replies
  `bad_args` / `Missing key`.
- Optional arguments read as nil mean "native default". Assign them directly
  (`control.onTintColor = args.color("tint")`) so null resets the property.
- Don't call `result` yourself; `apply` returns the reply.

## Shared Helpers — reuse, don't copy
- Colors: `UIColor(argb:)` / `NSColor(argb:)` and `args.color(...)`.
- SF Symbols: `SymbolSpec(args.args("symbol"))?.image()`.
- Button styles: `ButtonStyling`.
- Embedding: `embed(_:)`; sizes for `getIntrinsicSize`: `sizeReply(_:)`.
If a helper is missing, add it to `Support/` on **both** platforms.

## Parity
When you change an iOS file, open its macOS counterpart (and vice versa) and
make the equivalent change, or document why it doesn't apply.
