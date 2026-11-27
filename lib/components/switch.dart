import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

import '../channel/native_view_state.dart';
import '../channel/params.dart';

/// Controller for a [CNSwitch] that allows imperative updates from Dart
/// to the underlying native UISwitch/NSSwitch instance.
class CNSwitchController {
  MethodChannel? _channel;

  void _attach(MethodChannel channel) {
    _channel = channel;
  }

  void _detach(MethodChannel channel) {
    if (identical(_channel, channel)) _channel = null;
  }

  /// Sets the switch [value]. When [animated] is true the change is animated
  /// on the native control.
  Future<void> setValue(bool value, {bool animated = false}) async {
    final channel = _channel;
    if (channel == null) return;
    await channel.invokeMethod('setValue', {
      'value': value,
      'animated': animated,
    });
  }

  /// Enables or disables user interaction on the native switch.
  Future<void> setEnabled(bool enabled) async {
    final channel = _channel;
    if (channel == null) return;
    await channel.invokeMethod('setEnabled', {'enabled': enabled});
  }
}

/// A Cupertino-native switch rendered by the host platform.
///
/// On iOS/macOS this uses a platform view to embed UISwitch/NSSwitch, and
/// falls back to [CupertinoSwitch] on unsupported platforms.
class CNSwitch extends StatefulWidget {
  /// Creates a Cupertino-native switch.
  const CNSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.controller,
    this.height = 44.0,
    this.color,
  });

  /// Whether the switch is on.
  final bool value;

  /// Whether the control is interactive.
  final bool enabled;

  /// Callback invoked when the user toggles the value.
  final ValueChanged<bool> onChanged;

  /// Optional controller to imperatively control the native view.
  final CNSwitchController? controller;

  /// Visual height of the embedded platform view.
  final double height;

  /// Optional tint color to apply to the switch.
  final Color? color;

  @override
  State<CNSwitch> createState() => _CNSwitchState();
}

class _CNSwitchState extends NativeViewState<CNSwitch> {
  @override
  String get viewType => 'CupertinoNativeSwitch';

  @override
  NativeState describeNativeState(BuildContext context) => {
    'setValue': {'value': widget.value},
    'setEnabled': {'enabled': widget.enabled},
    'setStyle': {
      'tint': resolveColorToArgb(
        widget.color ?? CupertinoTheme.of(context).primaryColor,
        context,
      ),
    },
  };

  @override
  Set<Factory<OneSequenceGestureRecognizer>> get gestureRecognizers => {
    Factory<HorizontalDragGestureRecognizer>(
      () => HorizontalDragGestureRecognizer(),
    ),
    Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
  };

  @override
  Widget buildFallback(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: CupertinoSwitch(
        value: widget.value,
        activeTrackColor: widget.color,
        onChanged: widget.enabled ? widget.onChanged : null,
      ),
    );
  }

  @override
  Widget layoutNativeView(BuildContext context, Widget platformView) {
    // Platform views expand to fill unbounded axes (e.g. inside a Row), so
    // give the view a finite width from the native switch's ~51x31pt aspect
    // ratio. The native control is centered inside it.
    return SizedBox(
      height: widget.height,
      width: widget.height * 51.0 / 31.0,
      child: platformView,
    );
  }

  @override
  void didCreateNativeView(MethodChannel channel) {
    widget.controller?._attach(channel);
  }

  @override
  void didUpdateWidget(covariant CNSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    final channel = nativeChannel;
    if (channel != null && oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(channel);
      widget.controller?._attach(channel);
    }
  }

  @override
  void dispose() {
    final channel = nativeChannel;
    if (channel != null) widget.controller?._detach(channel);
    super.dispose();
  }

  @override
  void handleNativeEvent(String method, Map<Object?, Object?> args) {
    final value = args['value'];
    if (method == 'valueChanged' && value is bool) {
      recordNativeState('setValue', {'value': value});
      widget.onChanged(value);
    }
  }
}
