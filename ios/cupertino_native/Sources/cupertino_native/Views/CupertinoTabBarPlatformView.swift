import Flutter
import UIKit

/// A `UITabBar`, or two of them side by side in split mode.
///
/// Every channel method updates the stored state; `flush()` then renders it,
/// rebuilding the bars only when items or layout changed.
final class CupertinoTabBarPlatformView: NativeView, UITabBarDelegate {
  override class var viewType: String { "CupertinoNativeTabBar" }

  private struct Item {
    let label: String?
    let symbol: SymbolSpec?
  }

  private var items: [Item] = []
  private var split = false
  private var rightCount = 1
  private var splitSpacing: CGFloat = 8
  private var selectedIndex = 0
  private var tint: UIColor?
  private var background: UIColor?
  private var needsRebuild = false

  /// One bar, or [left, right] when split.
  private var bars: [UITabBar] = []
  /// Number of items in the first bar.
  private var leftCount = 0

  override func apply(_ method: String, _ args: ChannelArgs) throws -> Any? {
    switch method {
    case "setItems":
      items = args.argsList("items").map {
        Item(label: $0.string("label"), symbol: SymbolSpec($0.args("symbol")))
      }
      needsRebuild = true
    case "setLayout":
      split = args.bool("split") ?? false
      rightCount = max(args.int("rightCount") ?? 1, 0)
      splitSpacing = args.cgFloat("splitSpacing") ?? 8
      needsRebuild = true
    case "setSelectedIndex":
      selectedIndex = try args.required("index", args.int)
    case "setStyle":
      tint = args.color("tint")
      background = args.color("backgroundColor")
    case "getIntrinsicSize":
      return sizeReply(intrinsicSize())
    default:
      return try super.apply(method, args)
    }
    return nil
  }

  override func flush() {
    if needsRebuild {
      needsRebuild = false
      rebuildBars()
    }
    applyStyle()
    applySelection()
  }

  func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
    guard let barIndex = bars.firstIndex(where: { $0 === tabBar }),
          let itemIndex = tabBar.items?.firstIndex(of: item) else { return }
    selectedIndex = (barIndex == 0 ? 0 : leftCount) + itemIndex
    applySelection()
    emit("valueChanged", ["index": selectedIndex])
  }

  // MARK: - Rendering

  private func rebuildBars() {
    bars.forEach { $0.removeFromSuperview() }
    let isSplit = split && rightCount > 0 && items.count > rightCount
    leftCount = isSplit ? items.count - rightCount : items.count
    let ranges = isSplit ? [0..<leftCount, leftCount..<items.count] : [0..<items.count]
    bars = ranges.map { range in
      let bar = UITabBar()
      bar.delegate = self
      bar.translatesAutoresizingMaskIntoConstraints = false
      bar.items = range.map { index in
        let image = items[index].symbol?.image()
        return UITabBarItem(title: items[index].label, image: image, selectedImage: image)
      }
      container.addSubview(bar)
      return bar
    }
    if isSplit {
      layoutSplit(left: bars[0], right: bars[1])
    } else if let bar = bars.first {
      NSLayoutConstraint.activate([
        bar.leadingAnchor.constraint(equalTo: container.leadingAnchor),
        bar.trailingAnchor.constraint(equalTo: container.trailingAnchor),
        bar.topAnchor.constraint(equalTo: container.topAnchor),
        bar.bottomAnchor.constraint(equalTo: container.bottomAnchor),
      ])
    }
  }

  /// Sizes both bars to their content when they fit, otherwise splits the
  /// width proportionally to their item counts.
  private func layoutSplit(left: UITabBar, right: UITabBar) {
    let leftWidth = left.sizeThatFits(.zero).width
    let rightWidth = right.sizeThatFits(.zero).width
    var constraints = [
      left.leadingAnchor.constraint(equalTo: container.leadingAnchor),
      left.topAnchor.constraint(equalTo: container.topAnchor),
      left.bottomAnchor.constraint(equalTo: container.bottomAnchor),
      right.trailingAnchor.constraint(equalTo: container.trailingAnchor),
      right.topAnchor.constraint(equalTo: container.topAnchor),
      right.bottomAnchor.constraint(equalTo: container.bottomAnchor),
    ]
    if leftWidth + rightWidth + splitSpacing > container.bounds.width {
      let rightFraction = CGFloat(rightCount) / CGFloat(items.count)
      constraints += [
        right.widthAnchor.constraint(equalTo: container.widthAnchor, multiplier: rightFraction),
        left.trailingAnchor.constraint(equalTo: right.leadingAnchor, constant: -splitSpacing),
      ]
    } else {
      constraints += [
        left.widthAnchor.constraint(equalToConstant: leftWidth),
        right.widthAnchor.constraint(equalToConstant: rightWidth),
        left.trailingAnchor.constraint(lessThanOrEqualTo: right.leadingAnchor, constant: -splitSpacing),
      ]
    }
    NSLayoutConstraint.activate(constraints)
  }

  private func applyStyle() {
    // With an appearance set, `barTintColor` is ignored; the background has
    // to go through the appearance instead.
    let appearance = UITabBarAppearance()
    appearance.configureWithDefaultBackground()
    if let background { appearance.backgroundColor = background }
    for bar in bars {
      bar.standardAppearance = appearance
      bar.scrollEdgeAppearance = appearance
      bar.tintColor = tint
    }
  }

  private func applySelection() {
    for (barIndex, bar) in bars.enumerated() {
      let local = selectedIndex - (barIndex == 0 ? 0 : leftCount)
      let barItems = bar.items ?? []
      bar.selectedItem = barItems.indices.contains(local) ? barItems[local] : nil
    }
  }

  private func intrinsicSize() -> CGSize {
    let unbounded = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
    let sizes = bars.map { $0.sizeThatFits(unbounded) }
    guard !sizes.isEmpty else { return .zero }
    let width = sizes.reduce(0) { $0 + $1.width } + splitSpacing * CGFloat(sizes.count - 1)
    return CGSize(width: width, height: sizes.map(\.height).max() ?? 0)
  }
}
