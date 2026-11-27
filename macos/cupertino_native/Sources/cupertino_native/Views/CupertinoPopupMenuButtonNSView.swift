import Cocoa
import FlutterMacOS

final class CupertinoPopupMenuButtonNSView: NativeView {
  override class var viewType: String { "CupertinoNativePopupMenuButton" }

  private let button = NSButton(title: "", target: nil, action: nil)
  private var popupMenu = NSMenu()
  private var title: String?
  private var image: NSImage?
  private var transparent = false

  override func setUp() {
    button.setButtonType(.momentaryPushIn)
    button.target = self
    button.action = #selector(onPressed)
    embed(button)
  }

  override func apply(_ method: String, _ args: ChannelArgs) throws -> Any? {
    switch method {
    case "setContent":
      title = args.string("title")
      image = SymbolSpec(args.args("symbol"))?.image()
      applyContent()
    case "setStyle":
      transparent = args.bool("transparent") ?? false
      if transparent {
        // Child mode: an invisible hit target over the Flutter child.
        button.isBordered = false
      } else {
        ButtonStyling.apply(
          to: button,
          style: args.string("buttonStyle") ?? "plain",
          tint: args.color("tint"),
          round: args.bool("round") ?? false
        )
      }
      applyContent()
    case "setItems":
      popupMenu = makeMenu(args.argsList("items"))
    case "setPressed":
      alphaValue = try args.required("pressed", args.bool) ? 0.7 : 1.0
    case "getIntrinsicSize":
      return sizeReply(button.intrinsicContentSize)
    default:
      return try super.apply(method, args)
    }
    return nil
  }

  private func applyContent() {
    button.title = transparent ? "" : title ?? ""
    button.image = transparent ? nil : image
    button.imagePosition = title == nil ? .imageOnly : .imageLeading
  }

  /// Item tags are indices into the Dart `items` list, dividers included.
  private func makeMenu(_ entries: [ChannelArgs]) -> NSMenu {
    let menu = NSMenu()
    menu.autoenablesItems = false
    for (index, entry) in entries.enumerated() {
      if entry.bool("divider") ?? false {
        menu.addItem(.separator())
        continue
      }
      let item = NSMenuItem(title: entry.string("label") ?? "", action: #selector(onSelect), keyEquivalent: "")
      item.target = self
      item.tag = index
      item.isEnabled = entry.bool("enabled") ?? true
      item.state = (entry.bool("checked") ?? false) ? .on : .off
      item.image = SymbolSpec(entry.args("symbol"))?.image()
      menu.addItem(item)
    }
    return menu
  }

  @objc private func onPressed() {
    popupMenu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height), in: button)
  }

  @objc private func onSelect(_ sender: NSMenuItem) {
    emit("itemSelected", ["index": sender.tag])
  }
}
