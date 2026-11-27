import Cocoa
import FlutterMacOS

final class CupertinoSliderNSView: NativeView {
  override class var viewType: String { "CupertinoNativeSlider" }

  private let slider = NSSlider(value: 0, minValue: 0, maxValue: 1, target: nil, action: nil)
  private var step: Double = 0  // 0 = continuous

  override func setUp() {
    slider.isContinuous = true
    slider.target = self
    slider.action = #selector(onChanged)
    embed(slider)
  }

  override func apply(_ method: String, _ args: ChannelArgs) throws -> Any? {
    switch method {
    case "setRange":
      let lo = try args.required("min", args.double)
      let hi = try args.required("max", args.double)
      // An inverted range is ignored rather than passed to AppKit.
      if lo <= hi {
        slider.minValue = lo
        slider.maxValue = hi
      }
    case "setValue":
      // Setting the value programmatically doesn't fire the action, so it
      // is never echoed back to Dart as a user change.
      slider.doubleValue = try args.required("value", args.double)
    case "setStep":
      step = max(args.double("step") ?? 0, 0)
    case "setEnabled":
      slider.isEnabled = try args.required("enabled", args.bool)
    case "setStyle":
      // AppKit only exposes the filled track color; the thumb and the
      // unfilled track keep their system appearance on macOS.
      slider.trackFillColor = args.color("trackTint")
    default:
      return try super.apply(method, args)
    }
    return nil
  }

  @objc private func onChanged() {
    var value = slider.doubleValue
    if step > 0 {
      let lo = slider.minValue
      value = min(max(lo + (((value - lo) / step).rounded() * step), lo), slider.maxValue)
      slider.doubleValue = value
    }
    emit("valueChanged", ["value": value])
  }
}
