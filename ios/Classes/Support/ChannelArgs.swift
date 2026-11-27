import Flutter
import UIKit

/// A malformed method call from Dart.
enum ChannelError: Error {
  case missingArgument(String)

  var flutterError: FlutterError {
    switch self {
    case .missingArgument(let key):
      return FlutterError(code: "bad_args", message: "Missing \(key)", details: nil)
    }
  }
}

/// Typed access to a method call's argument map.
///
/// Dart always sends complete arguments, so a missing or null key means
/// "use the native default"; the accessors return nil for it.
struct ChannelArgs {
  private let values: [String: Any]

  init(_ raw: Any?) {
    values = raw as? [String: Any] ?? [:]
  }

  func bool(_ key: String) -> Bool? { (values[key] as? NSNumber)?.boolValue }
  func int(_ key: String) -> Int? { (values[key] as? NSNumber)?.intValue }
  func double(_ key: String) -> Double? { (values[key] as? NSNumber)?.doubleValue }
  func cgFloat(_ key: String) -> CGFloat? { double(key).map { CGFloat($0) } }
  func string(_ key: String) -> String? { values[key] as? String }

  /// A string list; non-string entries become empty strings.
  func strings(_ key: String) -> [String] {
    (values[key] as? [Any] ?? []).map { $0 as? String ?? "" }
  }

  /// A color encoded by Dart as an ARGB integer.
  func color(_ key: String) -> UIColor? {
    (values[key] as? NSNumber).map { UIColor(argb: $0.intValue) }
  }

  func colors(_ key: String) -> [UIColor] {
    (values[key] as? [Any] ?? []).compactMap { ($0 as? NSNumber).map { UIColor(argb: $0.intValue) } }
  }

  /// A nested map, or nil when absent or null.
  func args(_ key: String) -> ChannelArgs? {
    (values[key] as? [String: Any]).map { ChannelArgs($0) }
  }

  /// A list of maps; null entries become empty argument maps.
  func argsList(_ key: String) -> [ChannelArgs] {
    (values[key] as? [Any] ?? []).map { ChannelArgs($0) }
  }

  /// Reads a value that must be present, e.g. `try args.required("value", args.bool)`.
  func required<T>(_ key: String, _ read: (String) -> T?) throws -> T {
    guard let value = read(key) else { throw ChannelError.missingArgument(key) }
    return value
  }
}

extension UIColor {
  /// Creates a color from a 0xAARRGGBB integer.
  convenience init(argb: Int) {
    self.init(
      red: CGFloat((argb >> 16) & 0xFF) / 255.0,
      green: CGFloat((argb >> 8) & 0xFF) / 255.0,
      blue: CGFloat(argb & 0xFF) / 255.0,
      alpha: CGFloat((argb >> 24) & 0xFF) / 255.0
    )
  }
}
