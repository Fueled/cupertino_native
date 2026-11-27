import SwiftUI

/// SwiftUI is used for the macOS switch because AppKit's `NSSwitch` can't be
/// tinted.
struct CupertinoSwitchView: View {
  @ObservedObject var model: SwitchModel

  var body: some View {
    Toggle("", isOn: $model.value)
      .labelsHidden()
      .toggleStyle(.switch)
      .disabled(!model.enabled)
      .tint(model.tint)
      .onChange(of: model.value) { newValue in
        model.valueDidChange(newValue)
      }
  }
}

final class SwitchModel: ObservableObject {
  @Published var value = false
  @Published var enabled = true
  @Published var tint: Color?

  /// Called when the user toggles the switch.
  var onUserChange: (Bool) -> Void = { _ in }

  /// A value set from Dart whose `onChange` hasn't fired yet. SwiftUI reports
  /// changes asynchronously, so a flag cleared right after assignment would
  /// be gone by then; instead the pending value is matched and consumed.
  private var pendingDartValue: Bool?

  func setFromDart(_ newValue: Bool) {
    guard newValue != value else { return }
    pendingDartValue = newValue
    value = newValue
  }

  func valueDidChange(_ newValue: Bool) {
    if let pending = pendingDartValue {
      pendingDartValue = nil
      if pending == newValue { return }
    }
    onUserChange(newValue)
  }
}
