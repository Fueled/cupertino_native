import Cocoa

/// Maps `CNButtonStyle` names onto `NSButton` bezels. Shared by the button
/// and popup menu button.
enum ButtonStyling {
  /// Styles whose tint fills the bezel rather than the content.
  private static let prominentStyles: Set<String> = ["filled", "borderedProminent", "prominentGlass"]

  static func apply(to button: NSButton, style: String, tint: NSColor?, round: Bool) {
    button.isBordered = style != "plain"
    switch style {
    case "bordered", "borderedProminent", "filled":
      button.bezelStyle = .rounded
    case "glass", "prominentGlass":
      button.bezelStyle = glassBezel
    default:
      button.bezelStyle = .texturedRounded
    }
    // Applied after the style so a style change can't drop the round shape.
    if round { button.bezelStyle = .circular }

    if prominentStyles.contains(style) {
      button.bezelColor = tint
      button.contentTintColor = tint == nil ? nil : .white
    } else {
      button.bezelColor = nil
      button.contentTintColor = tint
    }
  }

  /// Liquid Glass on macOS 26+ (when built with an SDK that has it).
  private static var glassBezel: NSButton.BezelStyle {
    #if compiler(>=6.2)
    if #available(macOS 26.0, *) { return .glass }
    #endif
    return .texturedRounded
  }
}
