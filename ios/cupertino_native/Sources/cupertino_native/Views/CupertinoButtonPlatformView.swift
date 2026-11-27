import Flutter
import UIKit

final class CupertinoButtonPlatformView: NativeView {
  override class var viewType: String { "CupertinoNativeButton" }

  private let button = UIButton(type: .system)
  private var title: String?
  private var symbol: SymbolSpec?
  private var style = "plain"
  private var tint: UIColor?
  private var round = false
  private var needsConfiguration = false

  override func setUp() {
    embed(button)
    button.addTarget(self, action: #selector(onPressed), for: .touchUpInside)
  }

  override func apply(_ method: String, _ args: ChannelArgs) throws -> Any? {
    switch method {
    case "setContent":
      title = args.string("title")
      symbol = SymbolSpec(args.args("symbol"))
      needsConfiguration = true
    case "setStyle":
      style = args.string("buttonStyle") ?? "plain"
      tint = args.color("tint")
      round = args.bool("round") ?? false
      needsConfiguration = true
    case "setEnabled":
      button.isEnabled = try args.required("enabled", args.bool)
    case "setSemantics":
      // nil restores UIKit's default label (the title).
      button.accessibilityLabel = args.string("label")
    case "setPressed":
      button.isHighlighted = try args.required("pressed", args.bool)
    case "getIntrinsicSize":
      return sizeReply(button.intrinsicContentSize)
    default:
      return try super.apply(method, args)
    }
    return nil
  }

  override func flush() {
    guard needsConfiguration else { return }
    needsConfiguration = false
    var config = ButtonStyling.configuration(style: style, tint: tint, round: round)
    config.title = title
    config.image = symbol?.image()
    button.configuration = config
  }

  @objc private func onPressed() {
    emit("pressed")
  }
}
