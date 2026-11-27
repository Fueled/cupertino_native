import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// Reports press-down and release over [child] so a native button can show
/// its highlight while Flutter's gesture arena decides who gets the tap.
///
/// A press is cancelled once the pointer moves beyond [kTouchSlop], so drags
/// that start on a button (e.g. scrolling) don't leave it highlighted.
class PressListener extends StatefulWidget {
  /// Creates a listener that calls [onPressedChanged] when the pressed state
  /// changes.
  const PressListener({
    super.key,
    required this.onPressedChanged,
    required this.child,
  });

  /// Called with `true` on press and `false` on release or cancel.
  final ValueChanged<bool> onPressedChanged;

  /// The widget being pressed.
  final Widget child;

  @override
  State<PressListener> createState() => _PressListenerState();
}

class _PressListenerState extends State<PressListener> {
  Offset? _downPosition;
  bool _pressed = false;

  void _setPressed(bool pressed) {
    if (_pressed == pressed) return;
    _pressed = pressed;
    widget.onPressedChanged(pressed);
  }

  void _release() {
    _downPosition = null;
    _setPressed(false);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) {
        _downPosition = event.position;
        _setPressed(true);
      },
      onPointerMove: (event) {
        final start = _downPosition;
        if (start != null && (event.position - start).distance > kTouchSlop) {
          _setPressed(false);
        }
      },
      onPointerUp: (_) => _release(),
      onPointerCancel: (_) => _release(),
      child: widget.child,
    );
  }
}
