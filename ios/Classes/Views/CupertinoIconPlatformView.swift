import Flutter
import UIKit

final class CupertinoIconPlatformView: NativeView {
  override class var viewType: String { "CupertinoNativeIcon" }

  private let imageView = UIImageView()

  override func setUp() {
    imageView.contentMode = .scaleAspectFit
    // Template symbols (no explicit color) follow light/dark appearance.
    imageView.tintColor = .label
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
