import Cocoa
import FlutterMacOS
import SwiftUI

final class CupertinoSwitchNSView: NativeView {
  override class var viewType: String { "CupertinoNativeSwitch" }

  private let model = SwitchModel()
  private lazy var hostingView = NSHostingView(rootView: CupertinoSwitchView(model: model))

  override func setUp() {
    model.onUserChange = { [weak self] value in
      self?.emit("valueChanged", ["value": value])
    }
    embed(hostingView)
  }

  override func apply(_ method: String, _ args: ChannelArgs) throws -> Any? {
    switch method {
    case "setValue":
      model.setFromDart(try args.required("value", args.bool))
    case "setEnabled":
      model.enabled = try args.required("enabled", args.bool)
    case "setStyle":
      model.tint = args.color("tint").map { Color(nsColor: $0) }
    default:
      return try super.apply(method, args)
    }
    return nil
  }
}
