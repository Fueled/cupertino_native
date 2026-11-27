import Cocoa
import FlutterMacOS

/// Base class for every platform view in the plugin.
///
/// Dart describes a view's state as channel methods (`setValue`,
/// `setStyle`, ...) with complete arguments. The same methods arrive twice:
/// once as the creation params, applied in order before the view is shown,
/// and later over the per-view channel whenever that part of the state
/// changes. Subclasses therefore implement each method once, in
/// `apply(_:_:)`, as a setter that fully replaces that part of the state.
///
/// Subclasses don't define initializers: they declare their controls as
/// stored properties and build the hierarchy in `setUp()`.
class NativeView: NSView {
  /// Platform view type registered with Flutter; also the channel prefix.
  class var viewType: String { fatalError("\(self) must override viewType") }

  private let channel: FlutterMethodChannel

  required init(viewId: Int64, messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "\(Self.viewType)_\(viewId)", binaryMessenger: messenger)
    super.init(frame: .zero)
    wantsLayer = true
    layer?.backgroundColor = NSColor.clear.cgColor
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterError(code: "disposed", message: "The native view was released", details: nil))
        return
      }
      self.handle(call, result: result)
    }
    setUp()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { nil }

  deinit {
    channel.setMethodCallHandler(nil)
  }

  /// Builds the view hierarchy. Called once, before any state is applied.
  func setUp() {}

  /// Applies one state update and returns the value sent back to Dart.
  ///
  /// Subclasses handle their own methods and defer to `super` for the rest.
  /// Throw `ChannelError` for malformed arguments.
  func apply(_ method: String, _ args: ChannelArgs) throws -> Any? {
    switch method {
    case "setBrightness":
      let isDark = try args.required("isDark", args.bool)
      // Subviews, including SwiftUI hosting views, inherit the appearance.
      appearance = NSAppearance(named: isDark ? .darkAqua : .aqua)
      return nil
    default:
      return FlutterMethodNotImplemented
    }
  }

  /// Called after a batch of updates: the creation params, or a single
  /// channel call. Views that rebuild from accumulated state do it here, once.
  func flush() {}

  /// Sends an event to Dart, such as `valueChanged`.
  func emit(_ method: String, _ arguments: [String: Any]? = nil) {
    channel.invokeMethod(method, arguments: arguments)
  }

  /// Adds `subview`, pinned to all four edges.
  func embed(_ subview: NSView) {
    subview.translatesAutoresizingMaskIntoConstraints = false
    addSubview(subview)
    NSLayoutConstraint.activate([
      subview.leadingAnchor.constraint(equalTo: leadingAnchor),
      subview.trailingAnchor.constraint(equalTo: trailingAnchor),
      subview.topAnchor.constraint(equalTo: topAnchor),
      subview.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
  }

  /// Encodes a size as the reply to `getIntrinsicSize`.
  func sizeReply(_ size: CGSize) -> [String: Double] {
    ["width": Double(size.width), "height": Double(size.height)]
  }

  /// Applies the creation params: `{"updates": [[method, args], ...]}`.
  fileprivate func applyCreationParams(_ params: Any?) {
    let updates = (params as? [String: Any])?["updates"] as? [[Any]] ?? []
    for update in updates {
      guard update.count == 2, let method = update[0] as? String else { continue }
      _ = try? apply(method, ChannelArgs(update[1]))
    }
    flush()
  }

  private func handle(_ call: FlutterMethodCall, result: FlutterResult) {
    do {
      let value = try apply(call.method, ChannelArgs(call.arguments))
      flush()
      result(value)
    } catch let error as ChannelError {
      result(error.flutterError)
    } catch {
      result(FlutterError(code: "error", message: "\(error)", details: nil))
    }
  }
}

/// Creates `NativeView`s of one type and applies their creation params.
final class NativeViewFactory: NSObject, FlutterPlatformViewFactory {
  private let viewClass: NativeView.Type
  private let messenger: FlutterBinaryMessenger

  init(_ viewClass: NativeView.Type, messenger: FlutterBinaryMessenger) {
    self.viewClass = viewClass
    self.messenger = messenger
    super.init()
  }

  func createArgsCodec() -> (FlutterMessageCodec & NSObjectProtocol)? {
    FlutterStandardMessageCodec.sharedInstance()
  }

  func create(withViewIdentifier viewId: Int64, arguments args: Any?) -> NSView {
    let view = viewClass.init(viewId: viewId, messenger: messenger)
    view.applyCreationParams(args)
    return view
  }
}
