import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

import '../channel/native_view_state.dart';
import '../channel/params.dart';

/// Controller for a [CNSlider] allowing imperative changes to the native
/// NSSlider/UISlider instance.
class CNSliderController {
  MethodChannel? _channel;

  void _attach(MethodChannel channel) {
    _channel = channel;
  }

  void _detach(MethodChannel channel) {
    if (identical(_channel, channel)) _channel = null;
  }

  /// Sets the current slider [value]. When [animated] is true, animates to it.
  Future<void> setValue(double value, {bool animated = false}) async {
    final channel = _channel;
    if (channel == null) return;
    await channel.invokeMethod('setValue', {
      'value': value,
      'animated': animated,
    });
  }

  /// Sets the valid [min] and [max] range of the slider.
  Future<void> setRange({required double min, required double max}) async {
    final channel = _channel;
    if (channel == null) return;
    await channel.invokeMethod('setRange', {'min': min, 'max': max});
  }

  /// Enables or disables user interaction on the slider.
  Future<void> setEnabled(bool enabled) async {
    final channel = _channel;
    if (channel == null) return;
    await channel.invokeMethod('setEnabled', {'enabled': enabled});
  }
}

/// A Cupertino-native slider rendered by the host platform.
///
/// On iOS/macOS this embeds UISlider/NSSlider via a platform view and falls
/// back to [CupertinoSlider] on other platforms.
class CNSlider extends StatefulWidget {
  /// Creates a Cupertino-native slider.
  const CNSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0.0,
    this.max = 1.0,
    this.enabled = true,
    this.controller,
    this.height = 44.0,
    this.color,
    this.thumbColor,
    this.trackColor,
    this.trackBackgroundColor,
    this.step,
  }) : assert(min <= max, 'min must not be greater than max');

  /// Current slider value.
  final double value;

  /// Minimum value.
  final double min;

  /// Maximum value.
  final double max;

  /// Whether the control is interactive.
  final bool enabled;

  /// Callback when the value changes due to user interaction.
  final ValueChanged<double> onChanged;

  /// Optional controller to imperatively interact with the native view.
  final CNSliderController? controller;

  /// Visual height of the embedded platform view.
  final double height;

  /// General accent color, used for the active track when [trackColor] is
  /// null.
  final Color? color;

  /// Explicit thumb color; if null, uses the native default. iOS only.
  final Color? thumbColor;

  /// Explicit active track color.
  final Color? trackColor;

  /// Explicit inactive track color. iOS only.
  final Color? trackBackgroundColor;

  /// Optional step interval for discrete values.
  final double? step;

  @override
  State<CNSlider> createState() => _CNSliderState();
}

class _CNSliderState extends NativeViewState<CNSlider> {
  double get _clampedValue => widget.min <= widget.max
      ? widget.value.clamp(widget.min, widget.max).toDouble()
      : widget.value;

  int? get _divisions {
    final step = widget.step;
    if (step == null || step <= 0 || widget.max <= widget.min) return null;
    return ((widget.max - widget.min) / step).round();
  }

  @override
  String get viewType => 'CupertinoNativeSlider';

  @override
  NativeState describeNativeState(BuildContext context) => {
    // Range before value, so the value isn't clamped to a stale range.
    'setRange': {'min': widget.min, 'max': widget.max},
    'setValue': {'value': _clampedValue},
    'setStep': {'step': widget.step},
    'setEnabled': {'enabled': widget.enabled},
    'setStyle': {
      // The thumb keeps its native default unless set explicitly.
      'trackTint': resolveColorToArgb(
        widget.trackColor ??
            widget.color ??
            CupertinoTheme.of(context).primaryColor,
        context,
      ),
      'thumbTint': resolveColorToArgb(widget.thumbColor, context),
      'trackBackgroundTint': resolveColorToArgb(
        widget.trackBackgroundColor,
        context,
      ),
    },
  };

  @override
  Set<Factory<OneSequenceGestureRecognizer>> get gestureRecognizers => {
    // Claim horizontal drags and taps so the slider works inside scroll views.
    Factory<HorizontalDragGestureRecognizer>(
      () => HorizontalDragGestureRecognizer(),
    ),
    Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
  };

  @override
  Widget buildFallback(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: CupertinoSlider(
        value: _clampedValue,
        min: widget.min,
        max: widget.max,
        divisions: _divisions,
        activeColor: widget.trackColor ?? widget.color,
        thumbColor: widget.thumbColor ?? CupertinoColors.white,
        onChanged: widget.enabled ? widget.onChanged : null,
      ),
    );
  }

  @override
  Widget layoutNativeView(BuildContext context, Widget platformView) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: platformView,
    );
  }

  @override
  void didCreateNativeView(MethodChannel channel) {
    widget.controller?._attach(channel);
  }

  @override
  void didUpdateWidget(covariant CNSlider oldWidget) {
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
    final value = (args['value'] as num?)?.toDouble();
    if (method == 'valueChanged' && value != null) {
      recordNativeState('setValue', {'value': value});
      widget.onChanged(value);
    }
  }
}
