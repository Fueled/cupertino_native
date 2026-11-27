import UIKit

/// Maps `CNButtonStyle` names to `UIButton.Configuration`s. Shared by the
/// button and popup menu button.
enum ButtonStyling {
  /// Styles whose tint fills the background rather than the foreground.
  private static let prominentStyles: Set<String> = ["filled", "borderedProminent", "prominentGlass"]

  static func configuration(style: String, tint: UIColor?, round: Bool) -> UIButton.Configuration {
    var config: UIButton.Configuration
    switch style {
    case "gray": config = .gray()
    case "tinted": config = .tinted()
    case "bordered": config = .bordered()
    case "borderedProminent": config = .borderedProminent()
    case "filled": config = .filled()
    case "glass": config = glass(prominent: false)
    case "prominentGlass": config = glass(prominent: true)
    default: config = .plain()
    }
    config.cornerStyle = round ? .capsule : .dynamic
    if let tint {
      if prominentStyles.contains(style) {
        config.baseBackgroundColor = tint
      } else {
        config.baseForegroundColor = tint
      }
    }
    return config
  }

  /// Liquid Glass on iOS 26+ (when built with an SDK that has it); tinted otherwise.
  private static func glass(prominent: Bool) -> UIButton.Configuration {
    #if compiler(>=6.2)
    if #available(iOS 26.0, *) {
      return prominent ? .prominentGlass() : .glass()
    }
    #endif
    return .tinted()
  }
}
