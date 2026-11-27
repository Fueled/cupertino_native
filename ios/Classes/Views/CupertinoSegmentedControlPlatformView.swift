import Flutter
import UIKit

final class CupertinoSegmentedControlPlatformView: NativeView {
  override class var viewType: String { "CupertinoNativeSegmentedControl" }

  private let control = UISegmentedControl(items: [])
  private var labels: [String] = []
  private var symbols: [SymbolSpec?] = []
  private var selectedIndex = UISegmentedControl.noSegment
  private var needsSegments = false

  override func setUp() {
    embed(control)
    control.addTarget(self, action: #selector(onChanged), for: .valueChanged)
  }

  override func apply(_ method: String, _ args: ChannelArgs) throws -> Any? {
    switch method {
    case "setItems":
      labels = args.strings("labels")
      symbols = args.argsList("symbols").map { SymbolSpec($0) }
      needsSegments = true
    case "setSelectedIndex":
      selectedIndex = try args.required("index", args.int)
    case "setEnabled":
      control.isEnabled = try args.required("enabled", args.bool)
    case "setStyle":
      control.selectedSegmentTintColor = args.color("tint")
    case "getIntrinsicSize":
      return sizeReply(control.intrinsicContentSize)
    default:
      return try super.apply(method, args)
    }
    return nil
  }

  override func flush() {
    if needsSegments {
      needsSegments = false
      rebuildSegments()
    }
    // Rebuilding clears the selection, so always re-apply it.
    let valid = (0..<control.numberOfSegments).contains(selectedIndex)
    control.selectedSegmentIndex = valid ? selectedIndex : UISegmentedControl.noSegment
  }

  private func rebuildSegments() {
    control.removeAllSegments()
    for index in 0..<max(labels.count, symbols.count) {
      if index < symbols.count, let image = symbols[index]?.image() {
        control.insertSegment(with: image, at: index, animated: false)
      } else {
        control.insertSegment(withTitle: index < labels.count ? labels[index] : "", at: index, animated: false)
      }
    }
  }

  @objc private func onChanged() {
    selectedIndex = control.selectedSegmentIndex
    emit("valueChanged", ["index": selectedIndex])
  }
}
