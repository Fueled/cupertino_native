import Flutter
import UIKit

final class CupertinoSwitchPlatformView: NativeView {
  override class var viewType: String { "CupertinoNativeSwitch" }

  private let control = UISwitch()

  override func setUp() {
    // UISwitch has a fixed size, so center it rather than stretch it.
    control.translatesAutoresizingMaskIntoConstraints = false
    container.addSubview(control)
    NSLayoutConstraint.activate([
      control.centerXAnchor.constraint(equalTo: container.centerXAnchor),
      control.centerYAnchor.constraint(equalTo: container.centerYAnchor),
    ])
    control.addTarget(self, action: #selector(onChanged), for: .valueChanged)
  }

  override func apply(_ method: String, _ args: ChannelArgs) throws -> Any? {
    switch method {
    case "setValue":
      control.setOn(try args.required("value", args.bool), animated: args.bool("animated") ?? false)
    case "setEnabled":
      control.isEnabled = try args.required("enabled", args.bool)
    case "setStyle":
      control.onTintColor = args.color("tint")
    default:
      return try super.apply(method, args)
    }
    return nil
  }

  @objc private func onChanged() {
    emit("valueChanged", ["value": control.isOn])
  }
}
