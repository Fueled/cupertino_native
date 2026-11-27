import Flutter
import UIKit

final class CupertinoPopupMenuButtonPlatformView: NativeView {
  override class var viewType: String { "CupertinoNativePopupMenuButton" }

  private struct MenuEntry {
    let label: String
    let symbol: SymbolSpec?
    let isDivider: Bool
    let isEnabled: Bool
    let isChecked: Bool

    init(_ args: ChannelArgs) {
      label = args.string("label") ?? ""
      symbol = SymbolSpec(args.args("symbol"))
      isDivider = args.bool("divider") ?? false
      isEnabled = args.bool("enabled") ?? true
      isChecked = args.bool("checked") ?? false
    }
  }

  private let button = UIButton(type: .system)
  private var title: String?
  private var symbol: SymbolSpec?
  private var style = "plain"
  private var tint: UIColor?
  private var round = false
  private var transparent = false
  private var entries: [MenuEntry] = []
  private var needsConfiguration = false
  private var needsMenu = false

  override func setUp() {
    embed(button)
    button.showsMenuAsPrimaryAction = true
  }

  override func apply(_ method: String, _ args: ChannelArgs) throws -> Any? {
    switch method {
    case "setContent":
      title = args.string("title")
      symbol = SymbolSpec(args.args("symbol"))
      needsConfiguration = true
    case "setStyle":
      style = args.string("buttonStyle") ?? "plain"
      tint = args.color("tint")
      round = args.bool("round") ?? false
      transparent = args.bool("transparent") ?? false
      needsConfiguration = true
    case "setItems":
      entries = args.argsList("items").map(MenuEntry.init)
      needsMenu = true
    case "setPressed":
      button.isHighlighted = try args.required("pressed", args.bool)
    case "getIntrinsicSize":
      return sizeReply(button.intrinsicContentSize)
    default:
      return try super.apply(method, args)
    }
    return nil
  }

  override func flush() {
    if needsConfiguration {
      needsConfiguration = false
      button.configuration = makeConfiguration()
    }
    if needsMenu {
      needsMenu = false
      button.menu = makeMenu()
    }
  }

  private func makeConfiguration() -> UIButton.Configuration {
    if transparent {
      // Child mode: an invisible hit target over the Flutter child.
      var config = UIButton.Configuration.plain()
      config.background.backgroundColor = .clear
      config.baseForegroundColor = .clear
      return config
    }
    var config = ButtonStyling.configuration(style: style, tint: tint, round: round)
    config.title = title
    config.image = symbol?.image()
    return config
  }

  /// Builds the menu; dividers split items into inline sections. Item indices
  /// count every entry, dividers included, to match the Dart `items` list.
  private func makeMenu() -> UIMenu {
    var sections: [[UIMenuElement]] = [[]]
    for (index, entry) in entries.enumerated() {
      if entry.isDivider {
        sections.append([])
        continue
      }
      let action = UIAction(
        title: entry.label,
        image: entry.symbol?.image(),
        attributes: entry.isEnabled ? [] : [.disabled],
        state: entry.isChecked ? .on : .off
      ) { [weak self] _ in
        self?.emit("itemSelected", ["index": index])
      }
      sections[sections.count - 1].append(action)
    }
    let children = sections.filter { !$0.isEmpty }.map {
      UIMenu(title: "", options: .displayInline, children: $0)
    }
    return UIMenu(title: "", children: children)
  }
}
