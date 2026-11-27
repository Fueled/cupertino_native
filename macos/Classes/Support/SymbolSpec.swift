import Cocoa

/// An SF Symbol decoded from the map produced by Dart's `CNSymbol.encode`.
struct SymbolSpec {
  let name: String
  let size: CGFloat?
  let color: NSColor?
  let paletteColors: [NSColor]
  let mode: String?
  let gradient: Bool

  /// Returns nil when `args` is absent or names no symbol.
  init?(_ args: ChannelArgs?) {
    guard let args, let name = args.string("name"), !name.isEmpty else { return nil }
    self.name = name
    size = args.cgFloat("size")
    color = args.color("color")
    paletteColors = args.colors("paletteColors")
    mode = args.string("mode")
    gradient = args.bool("gradient") ?? false
  }

  /// Renders the symbol.
  ///
  /// - `hierarchical` uses `color`; `palette` uses `paletteColors`;
  ///   `multicolor` uses the symbol's own colors.
  /// - `monochrome` or no mode: drawn in `color` when set.
  /// - Without any color the image stays a template, so the hosting
  ///   control's tint applies and it follows light/dark appearance.
  func image() -> NSImage? {
    guard let base = NSImage(systemSymbolName: name, accessibilityDescription: nil) else { return nil }
    var configs: [NSImage.SymbolConfiguration] = []
    if let size, size > 0 {
      configs.append(NSImage.SymbolConfiguration(pointSize: size, weight: .regular))
    }
    switch mode {
    case "hierarchical":
      if let color { configs.append(NSImage.SymbolConfiguration(hierarchicalColor: color)) }
    case "palette":
      if !paletteColors.isEmpty { configs.append(NSImage.SymbolConfiguration(paletteColors: paletteColors)) }
    case "multicolor":
      configs.append(NSImage.SymbolConfiguration.preferringMulticolor())
    default:
      // A one-color palette draws the whole symbol in that color.
      if let color { configs.append(NSImage.SymbolConfiguration(paletteColors: [color])) }
    }
    if gradient, let config = Self.gradientConfiguration() { configs.append(config) }

    guard let first = configs.first else { return base }
    let config = configs.dropFirst().reduce(first) { $0.applying($1) }
    return base.withSymbolConfiguration(config) ?? base
  }

  private static func gradientConfiguration() -> NSImage.SymbolConfiguration? {
    #if compiler(>=6.2)
    if #available(macOS 26.0, *) {
      return NSImage.SymbolConfiguration(colorRenderingMode: .gradient)
    }
    #endif
    return nil
  }
}
