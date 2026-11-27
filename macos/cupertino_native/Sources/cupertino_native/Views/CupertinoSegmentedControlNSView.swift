import Cocoa
import FlutterMacOS

final class CupertinoSegmentedControlNSView: NativeView {
  override class var viewType: String { "CupertinoNativeSegmentedControl" }

  private let control = NSSegmentedControl(labels: [], trackingMode: .selectOne, target: nil, action: nil)
  private var labels: [String] = []
  private var symbols: [SymbolSpec?] = []
  private var selectedIndex = -1
  private var needsSegments = false

  override func setUp() {
    control.target = self
    control.action = #selector(onChanged)
    embed(control)
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
      control.selectedSegmentBezelColor = args.color("tint")
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
    control.selectedSegment = (0..<control.segmentCount).contains(selectedIndex) ? selectedIndex : -1
  }

  private func rebuildSegments() {
    control.segmentCount = max(labels.count, symbols.count)
    for index in 0..<control.segmentCount {
      if index < symbols.count, let image = symbols[index]?.image() {
        control.setImage(image, forSegment: index)
        control.setLabel("", forSegment: index)
      } else {
        control.setImage(nil, forSegment: index)
        control.setLabel(index < labels.count ? labels[index] : "", forSegment: index)
      }
    }
  }

  @objc private func onChanged() {
    selectedIndex = control.selectedSegment
    emit("valueChanged", ["index": selectedIndex])
  }
}
