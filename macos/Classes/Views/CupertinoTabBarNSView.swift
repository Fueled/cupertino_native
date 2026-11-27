import Cocoa
import FlutterMacOS

/// A tab bar drawn as an `NSSegmentedControl`.
///
/// AppKit has no split tab bar, so `setLayout` is accepted but all items
/// render in one group on macOS.
final class CupertinoTabBarNSView: NativeView {
  override class var viewType: String { "CupertinoNativeTabBar" }

  private struct Item {
    let label: String?
    let symbol: SymbolSpec?
  }

  private let control = NSSegmentedControl(labels: [], trackingMode: .selectOne, target: nil, action: nil)
  private var items: [Item] = []
  private var selectedIndex = 0
  private var tint: NSColor?
  private var needsSegments = false

  override func setUp() {
    control.target = self
    control.action = #selector(onChanged)
    embed(control)
  }

  override func apply(_ method: String, _ args: ChannelArgs) throws -> Any? {
    switch method {
    case "setItems":
      items = args.argsList("items").map {
        Item(label: $0.string("label"), symbol: SymbolSpec($0.args("symbol")))
      }
      needsSegments = true
    case "setLayout":
      break  // Split layout is iOS-only; see the class comment.
    case "setSelectedIndex":
      selectedIndex = try args.required("index", args.int)
      needsSegments = true  // The tint follows the selection.
    case "setStyle":
      tint = args.color("tint")
      layer?.backgroundColor = (args.color("backgroundColor") ?? .clear).cgColor
      needsSegments = true  // The tint is baked into the selected image.
    case "getIntrinsicSize":
      return sizeReply(control.intrinsicContentSize)
    default:
      return try super.apply(method, args)
    }
    return nil
  }

  override func flush() {
    // Render first: changing the segment count can reset the selection.
    if needsSegments {
      needsSegments = false
      renderSegments()
    }
    control.selectedSegment = items.indices.contains(selectedIndex) ? selectedIndex : -1
  }

  /// Draws every segment, tinting the selected item's symbol.
  private func renderSegments() {
    control.segmentCount = items.count
    for (index, item) in items.enumerated() {
      let image = item.symbol?.image()
      if index == selectedIndex, let tint, let image, item.symbol?.color == nil {
        let config = NSImage.SymbolConfiguration(hierarchicalColor: tint)
        control.setImage(image.withSymbolConfiguration(config) ?? image, forSegment: index)
      } else {
        control.setImage(image, forSegment: index)
      }
      control.setLabel(image == nil ? item.label ?? "" : "", forSegment: index)
    }
  }

  @objc private func onChanged() {
    selectedIndex = control.selectedSegment
    // Move the tint to the newly selected segment right away.
    renderSegments()
    emit("valueChanged", ["index": selectedIndex])
  }
}
