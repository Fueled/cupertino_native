import Flutter
import UIKit

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
class NativeView: NSObject, FlutterPlatformView {
  /// Platform view type registered with Flutter; also the channel prefix.
  class var viewType: String { fatalError("\(self) must override viewType") }

  /// Root view handed to Flutter. Subclasses embed their controls in it.
  let container: UIView
  private let channel: FlutterMethodChannel

  required init(frame: CGRect, viewId: Int64, messenger: FlutterBinaryMessenger) {
    container = UIView(frame: frame)
    channel = FlutterMethodChannel(name: "\(Self.viewType)_\(viewId)", binaryMessenger: messenger)
    super.init()
    container.backgroundColor = .clear
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterError(code: "disposed", message: "The native view was released", details: nil))
        return
      }
      self.handle(call, result: result)
    }
    setUp()
  }

  deinit {
    channel.setMethodCallHandler(nil)
  }

  func view() -> UIView { container }

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
      container.overrideUserInterfaceStyle = isDark ? .dark : .light
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

  /// Adds `subview` to the container, pinned to all four edges.
  func embed(_ subview: UIView) {
    subview.translatesAutoresizingMaskIntoConstraints = false
    container.addSubview(subview)
    NSLayoutConstraint.activate([
      subview.leadingAnchor.constraint(equalTo: container.leadingAnchor),
      subview.trailingAnchor.constraint(equalTo: container.trailingAnchor),
      subview.topAnchor.constraint(equalTo: container.topAnchor),
      subview.bottomAnchor.constraint(equalTo: container.bottomAnchor),
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

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }

  func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
    let view = viewClass.init(frame: frame, viewId: viewId, messenger: messenger)
    view.applyCreationParams(args)
    return view
  }
}
