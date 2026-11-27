import Cocoa
import FlutterMacOS

public class CupertinoNativePlugin: NSObject, FlutterPlugin {
  /// Every platform view the plugin provides. Adding a component means adding
  /// its view class here; the view type comes from the class.
  private static let viewClasses: [NativeView.Type] = [
    CupertinoButtonNSView.self,
    CupertinoIconNSView.self,
    CupertinoPopupMenuButtonNSView.self,
    CupertinoSegmentedControlNSView.self,
    CupertinoSliderNSView.self,
    CupertinoSwitchNSView.self,
    CupertinoTabBarNSView.self,
  ]

  public static func register(with registrar: FlutterPluginRegistrar) {
    for viewClass in viewClasses {
      registrar.register(
        NativeViewFactory(viewClass, messenger: registrar.messenger),
        withId: viewClass.viewType
      )
    }
  }
}
