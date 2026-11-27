import Flutter
import UIKit

public class CupertinoNativePlugin: NSObject, FlutterPlugin {
  /// Every platform view the plugin provides. Adding a component means adding
  /// its view class here; the view type comes from the class.
  private static let viewClasses: [NativeView.Type] = [
    CupertinoButtonPlatformView.self,
    CupertinoIconPlatformView.self,
    CupertinoPopupMenuButtonPlatformView.self,
    CupertinoSegmentedControlPlatformView.self,
    CupertinoSliderPlatformView.self,
    CupertinoSwitchPlatformView.self,
    CupertinoTabBarPlatformView.self,
  ]

  public static func register(with registrar: FlutterPluginRegistrar) {
    for viewClass in viewClasses {
      registrar.register(
        NativeViewFactory(viewClass, messenger: registrar.messenger()),
        withId: viewClass.viewType
      )
    }
  }
}
