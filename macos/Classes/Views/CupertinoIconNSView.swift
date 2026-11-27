import Cocoa
import FlutterMacOS

final class CupertinoIconNSView: NativeView {
  override class var viewType: String { "CupertinoNativeIcon" }

  private let imageView = NSImageView()

  override func setUp() {
    imageView.imageScaling = .scaleProportionallyUpOrDown
    // Template symbols (no explicit color) follow light/dark appearance.
    imageView.contentTintColor = .labelColor
    embed(imageView)
  }

  override func apply(_ method: String, _ args: ChannelArgs) throws -> Any? {
    switch method {
    case "setSymbol":
      imageView.image = SymbolSpec(args.args("symbol"))?.image()
    case "getIntrinsicSize":
      return sizeReply(imageView.image?.size ?? .zero)
    default:
      return try super.apply(method, args)
    }
    return nil
  }
}
