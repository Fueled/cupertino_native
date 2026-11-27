import 'package:flutter/cupertino.dart';

import '../channel/native_view_state.dart';
import '../channel/params.dart';
import '../style/sf_symbol.dart';

/// A platform-rendered SF Symbol icon.
///
/// Renders an `SFSymbol` on iOS/macOS using native APIs for best fidelity.
/// On other platforms a generic placeholder icon is shown.
class CNIcon extends StatefulWidget {
  /// Creates a platform-rendered SF Symbol icon.
  const CNIcon({
    super.key,
    required this.symbol,
    this.size,
    this.color,
    this.mode,
    this.gradient,
    this.height,
  });

  /// The SF Symbol to render.
  final CNSymbol symbol;

  /// Overrides the symbol's size.
  final double? size;

  /// Overrides the symbol's color for monochrome/hierarchical modes.
  final Color? color;

  /// Overrides the rendering mode.
  final CNSymbolRenderingMode? mode;

  /// Whether to enable the system gradient when available (iOS/macOS 26+).
  final bool? gradient;

  /// Optional fixed height; defaults to the icon's size.
  final double? height;

  @override
  State<CNIcon> createState() => _CNIconState();
}

class _CNIconState extends NativeViewState<CNIcon> {
  double get _size => widget.size ?? widget.symbol.size;

  @override
  String get viewType => 'CupertinoNativeIcon';

  @override
  NativeState describeNativeState(BuildContext context) => {
    'setSymbol': {
      'symbol': widget.symbol.encode(
        context,
        size: widget.size,
        color: widget.color,
        mode: widget.mode,
        gradient: widget.gradient,
      ),
    },
  };

  @override
  Widget buildFallback(BuildContext context) {
    return SizedBox(
      width: _size,
      height: widget.height ?? _size,
      child: Icon(
        CupertinoIcons.circle,
        size: _size,
        color: widget.color ?? widget.symbol.color,
      ),
    );
  }

  @override
  Widget layoutNativeView(BuildContext context, Widget platformView) {
    return SizedBox(
      width: _size,
      height: widget.height ?? _size,
      child: platformView,
    );
  }
}
