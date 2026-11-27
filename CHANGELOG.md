## Unreleased

* CocoaPods is supported again alongside Swift Package Manager, for apps that have Swift Package Manager turned off.
* Lowers the minimum iOS version to 17.0. The plugin uses no iOS 18 APIs.

## 0.2.0

**Breaking**

* Requires iOS 18.0+ and macOS 12.0+ (Xcode 27 can no longer build for the old minimums).
* Requires Flutter 3.44+.
* Distributed as a Swift package only; CocoaPods is no longer supported. Apps must use Swift Package Manager, which Flutter enables by default since 3.44.
* Removes the unused `CupertinoNative`, `CupertinoNativePlatform` and `MethodChannelCupertinoNative` template classes and the `plugin_platform_interface` dependency.
* `CNSegmentedControl` icon overrides (`iconSize`, `iconColor`, ...) now take precedence over per-symbol values, as documented.

**Fixes**

* macOS `CNTabBar` no longer throws on every update (`setItems`/`setLayout` were not implemented).
* Native views are released when their widget is disposed; the switch and slider views previously leaked.
* Props set back to `null` (tint, colors, step) now reset the native control instead of keeping the old value.
* When the parent ignores a change, `CNSlider`, `CNSegmentedControl` and `CNTabBar` now snap back to the widget's value, like `CNSwitch` already did.
* Brightness follows the system when the theme sets none, and theme-dependent colors update on light/dark changes.
* `CNIcon` follows light/dark appearance by default (was always black) and has a fallback on non-Apple platforms.
* `CNSwitch` and `CNSlider` fallbacks no longer crash outside a Material app.
* `CNSegmentedControl` keeps its selection when restyled, updates when its labels or symbols change, and no longer gets infinite width in a `Row`.
* iOS `CNTabBar` no longer crashes on a negative index, keeps its colors after a layout change, and applies `backgroundColor`.
* macOS `CNSegmentedControl` applies its tint; macOS `CNTabBar` moves the tint with the selection.
* macOS buttons keep their round shape and correct tint after a style change.
* `gradient` on symbols is now implemented (iOS/macOS 26+); it was previously ignored.
* Liquid Glass button styles compile with Xcode versions before 26 and use `NSButton`'s glass bezel on macOS 26.
* An inverted slider range no longer crashes macOS.

**Internals**

* Components share one native-view host on each side (Dart and Swift); creation and updates use the same channel methods.
* Adds widget tests for every component.

## 0.1.1

* Adds link to blog post in readme.

## 0.1.0

* Cleaned up API.
* Added polished (somewhat) examples.
* Compiles and runs on MacOS.
* Much improved readme file.
* Dart doc and analyzer requirement.

## 0.0.1

* Initial release (to reserve pub name).
