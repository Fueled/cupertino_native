import Cocoa
import FlutterMacOS

final class CupertinoButtonNSView: NativeView {
  override class var viewType: String { "CupertinoNativeButton" }

  private let button = NSButton(title: "", target: nil, action: nil)

  override func setUp() {
    button.setButtonType(.momentaryPushIn)
    button.target = self
    button.action = #selector(onPressed)
    embed(button)
  }

  override func apply(_ method: String, _ args: ChannelArgs) throws -> Any? {
    switch method {
    case "setContent":
      let title = args.string("title")
      let image = SymbolSpec(args.args("symbol"))?.image()
      button.title = title ?? ""
      button.image = image
      button.imagePosition = title == nil ? .imageOnly : .imageLeading
    case "setStyle":
      ButtonStyling.apply(
        to: button,
        style: args.string("buttonStyle") ?? "plain",
        tint: args.color("tint"),
        round: args.bool("round") ?? false
      )
    case "setEnabled":
      button.isEnabled = try args.required("enabled", args.bool)
    case "setSemantics":
      // nil restores AppKit's default label (the title).
      button.setAccessibilityLabel(args.string("label"))
    case "setPressed":
      alphaValue = try args.required("pressed", args.bool) ? 0.7 : 1.0
    case "getIntrinsicSize":
      return sizeReply(button.intrinsicContentSize)
    default:
      return try super.apply(method, args)
    }
    return nil
  }

  @objc private func onPressed() {
    emit("pressed")
  }
}
