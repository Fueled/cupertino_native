import Flutter
import UIKit

final class CupertinoSliderPlatformView: NativeView {
  override class var viewType: String { "CupertinoNativeSlider" }

  private let slider = UISlider()
  private var step: Double = 0  // 0 = continuous

  override func setUp() {
    embed(slider)
    slider.addTarget(self, action: #selector(onChanged), for: .valueChanged)
  }

  override func apply(_ method: String, _ args: ChannelArgs) throws -> Any? {
    switch method {
    case "setRange":
      let lo = try args.required("min", args.double)
      let hi = try args.required("max", args.double)
      // An inverted range would make UIKit misbehave; ignore it.
      if lo <= hi {
        slider.minimumValue = Float(lo)
        slider.maximumValue = Float(hi)
      }
    case "setValue":
      let value = try args.required("value", args.double)
      slider.setValue(Float(value), animated: args.bool("animated") ?? false)
    case "setStep":
      step = max(args.double("step") ?? 0, 0)
    case "setEnabled":
      slider.isEnabled = try args.required("enabled", args.bool)
    case "setStyle":
      slider.minimumTrackTintColor = args.color("trackTint")
      slider.maximumTrackTintColor = args.color("trackBackgroundTint")
      slider.thumbTintColor = args.color("thumbTint")
    default:
      return try super.apply(method, args)
    }
    return nil
  }

  @objc private func onChanged() {
    var value = Double(slider.value)
    if step > 0 {
      let lo = Double(slider.minimumValue)
      let hi = Double(slider.maximumValue)
      value = min(max(lo + (((value - lo) / step).rounded() * step), lo), hi)
      slider.value = Float(value)
    }
    emit("valueChanged", ["value": value])
  }
}
