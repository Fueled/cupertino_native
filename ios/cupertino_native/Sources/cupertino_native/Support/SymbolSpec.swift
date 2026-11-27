import UIKit

/// An SF Symbol decoded from the map produced by Dart's `CNSymbol.encode`.
struct SymbolSpec {
  let name: String
  let size: CGFloat?
  let color: UIColor?
  let paletteColors: [UIColor]
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
  func image() -> UIImage? {
    guard let base = UIImage(systemName: name) else { return nil }
    var config = UIImage.SymbolConfiguration.unspecified
    if let size, size > 0 {
      config = config.applying(UIImage.SymbolConfiguration(pointSize: size))
    }
    switch mode {
    case "hierarchical":
      if let color { config = config.applying(UIImage.SymbolConfiguration(hierarchicalColor: color)) }
    case "palette":
      if !paletteColors.isEmpty { config = config.applying(UIImage.SymbolConfiguration(paletteColors: paletteColors)) }
    case "multicolor":
      config = config.applying(UIImage.SymbolConfiguration.preferringMulticolor())
    default:
      break
    }
    if gradient { config = Self.withGradient(config) }

    let image = base.applyingSymbolConfiguration(config) ?? base
    if mode == nil || mode == "monochrome", let color {
      return image.withTintColor(color, renderingMode: .alwaysOriginal)
    }
    return image
  }

  private static func withGradient(_ config: UIImage.SymbolConfiguration) -> UIImage.SymbolConfiguration {
    #if compiler(>=6.2)
    if #available(iOS 26.0, *) {
      return config.applying(UIImage.SymbolConfiguration(colorRenderingMode: .gradient))
    }
    #endif
    return config
  }
}
