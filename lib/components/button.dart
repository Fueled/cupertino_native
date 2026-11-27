import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

import '../channel/native_view_state.dart';
import '../channel/params.dart';
import '../channel/press_listener.dart';
import '../style/button_style.dart';
import '../style/sf_symbol.dart';

/// A Cupertino-native push button.
///
/// Embeds a native UIButton/NSButton for authentic visuals and behavior on
/// iOS and macOS. Falls back to [CupertinoButton] on other platforms.
class CNButton extends StatefulWidget {
  /// Creates a text button variant of [CNButton].
  const CNButton({
    super.key,
    required this.label,
    this.onPressed,
    this.enabled = true,
    this.tint,
    this.height = 32.0,
    this.shrinkWrap = false,
    this.style = CNButtonStyle.plain,
    this.semanticLabel,
  }) : icon = null,
       width = null,
       round = false;

  /// Creates a round, icon-only variant of [CNButton].
  const CNButton.icon({
    super.key,
    required this.icon,
    this.onPressed,
    this.enabled = true,
    this.tint,
    double size = 44.0,
    this.style = CNButtonStyle.glass,
    this.semanticLabel,
  }) : label = null,
       round = true,
       width = size,
       height = size,
       shrinkWrap = false,
       super();

  /// Button text (null in icon mode).
  final String? label;

  /// Button icon (non-null in icon mode).
  final CNSymbol? icon;

  /// Callback when pressed.
  final VoidCallback? onPressed;

  /// Whether the control is interactive and tappable.
  final bool enabled;

  /// Accent/tint color.
  final Color? tint;

  /// Control height.
  final double height;

  /// Fixed width used in icon/round mode.
  final double? width;

  /// If true, sizes the control to its intrinsic width.
  final bool shrinkWrap;

  /// Visual style to apply.
  final CNButtonStyle style;

  /// Whether the icon variant (round) is used.
  final bool round;

  /// Label read by VoiceOver and other assistive technologies.
  ///
  /// Set this for icon-only buttons, which have no text to read. When null,
  /// the native control's default label is used (its title, if any).
  final String? semanticLabel;

  /// Whether this instance is configured as the icon variant.
  bool get isIcon => icon != null;

  @override
  State<CNButton> createState() => _CNButtonState();
}

class _CNButtonState extends NativeViewState<CNButton> {
  double? _intrinsicWidth;

  bool get _isEnabled => widget.enabled && widget.onPressed != null;

  @override
  String get viewType => 'CupertinoNativeButton';

  @override
  NativeState describeNativeState(BuildContext context) => {
    'setContent': {
      'title': widget.label,
      'symbol': widget.icon?.encode(context),
    },
    'setStyle': {
      'buttonStyle': widget.style.name,
      'tint': resolveColorToArgb(
        widget.tint ?? CupertinoTheme.of(context).primaryColor,
        context,
      ),
      'round': widget.round,
    },
    'setEnabled': {'enabled': _isEnabled},
    'setSemantics': {'label': widget.semanticLabel},
  };

  @override
  Set<Factory<OneSequenceGestureRecognizer>> get gestureRecognizers => {
    // Forward taps to native; let Flutter keep drags for scrolling.
    Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
  };

  @override
  Widget buildFallback(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: widget.isIcon ? (widget.width ?? widget.height) : null,
      child: CupertinoButton(
        padding: widget.isIcon
            ? const EdgeInsets.all(4)
            : const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        onPressed: _isEnabled ? widget.onPressed : null,
        child: Semantics(
          label: widget.semanticLabel,
          excludeSemantics: widget.semanticLabel != null,
          child: widget.isIcon
              ? Icon(CupertinoIcons.ellipsis, size: widget.icon?.size)
              : Text(widget.label ?? ''),
        ),
      ),
    );
  }

  @override
  Widget layoutNativeView(BuildContext context, Widget platformView) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double? width;
        if (widget.isIcon) {
          width = widget.width ?? widget.height;
        } else if (widget.shrinkWrap || !constraints.hasBoundedWidth) {
          width = _intrinsicWidth ?? 80.0;
        }
        return PressListener(
          onPressedChanged: (pressed) =>
              sendNativeCommand('setPressed', {'pressed': pressed}),
          child: SizedBox(
            height: widget.height,
            width: width,
            child: platformView,
          ),
        );
      },
    );
  }

  @override
  void didCreateNativeView(MethodChannel channel) {
    if (!widget.isIcon) _measure();
  }

  @override
  void didSendNativeUpdates(Set<String> methods) {
    if (!widget.isIcon && methods.contains('setContent')) _measure();
  }

  Future<void> _measure() async {
    final size = await measureNativeView();
    if (size != null && size.width > 0) {
      setState(() => _intrinsicWidth = size.width);
    }
  }

  @override
  void handleNativeEvent(String method, Map<Object?, Object?> args) {
    if (method == 'pressed' && _isEnabled) widget.onPressed!();
  }
}
