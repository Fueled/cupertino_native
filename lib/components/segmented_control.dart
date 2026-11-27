import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../channel/native_view_state.dart';
import '../channel/params.dart';
import '../style/sf_symbol.dart';

/// A Cupertino-native segmented control.
///
/// Embeds a native UISegmentedControl/NSSegmentedControl for pixel-perfect
/// fidelity on iOS and macOS.
class CNSegmentedControl extends StatefulWidget {
  /// Creates a Cupertino-native segmented control.
  const CNSegmentedControl({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onValueChanged,
    this.enabled = true,
    this.color,
    this.height = 32.0,
    this.shrinkWrap = false,
    this.sfSymbols,
    this.iconSize,
    this.iconColor,
    this.iconPaletteColors,
    this.iconGradientEnabled,
    this.iconRenderingMode,
  });

  /// Segment labels to display, in order.
  final List<String> labels;

  /// The index of the selected segment.
  final int selectedIndex;

  /// Called when the user selects a segment.
  final ValueChanged<int> onValueChanged;

  /// Whether the control is interactive.
  final bool enabled;

  /// Accent/tint color used for the selected segment.
  final Color? color;

  /// Control height.
  final double height;

  /// If true, sizes the control to its intrinsic width.
  final bool shrinkWrap;

  /// Optional SF Symbols for segments; a segment with a symbol shows it
  /// instead of its label.
  final List<CNSymbol>? sfSymbols;

  /// Overrides the symbol size for all segments.
  final double? iconSize;

  /// Overrides the symbol color for all segments.
  final Color? iconColor;

  /// Overrides the symbol palette colors for all segments.
  final List<Color>? iconPaletteColors;

  /// Overrides gradient rendering for all segments (iOS/macOS 26+).
  final bool? iconGradientEnabled;

  /// Overrides the symbol rendering mode for all segments.
  final CNSymbolRenderingMode? iconRenderingMode;

  @override
  State<CNSegmentedControl> createState() => _CNSegmentedControlState();
}

class _CNSegmentedControlState extends NativeViewState<CNSegmentedControl> {
  double? _intrinsicWidth;

  int get _segmentCount =>
      math.max(widget.labels.length, widget.sfSymbols?.length ?? 0);

  @override
  String get viewType => 'CupertinoNativeSegmentedControl';

  @override
  NativeState describeNativeState(BuildContext context) => {
    'setItems': {
      'labels': widget.labels,
      'symbols': widget.sfSymbols
          ?.map(
            (symbol) => symbol.encode(
              context,
              size: widget.iconSize,
              color: widget.iconColor,
              paletteColors: widget.iconPaletteColors,
              mode: widget.iconRenderingMode,
              gradient: widget.iconGradientEnabled,
            ),
          )
          .toList(),
    },
    'setSelectedIndex': {'index': widget.selectedIndex},
    'setEnabled': {'enabled': widget.enabled},
    'setStyle': {'tint': resolveColorToArgb(widget.color, context)},
  };

  @override
  Widget buildFallback(BuildContext context) {
    // CupertinoSegmentedControl requires at least two segments.
    if (_segmentCount < 2) return SizedBox(height: widget.height);
    return SizedBox(
      height: widget.height,
      child: CupertinoSegmentedControl<int>(
        children: {
          for (var i = 0; i < _segmentCount; i++)
            i: i < widget.labels.length
                ? Text(widget.labels[i])
                : const Icon(CupertinoIcons.circle),
        },
        groupValue: widget.selectedIndex,
        onValueChanged: widget.enabled ? widget.onValueChanged : (_) {},
      ),
    );
  }

  @override
  Widget layoutNativeView(BuildContext context, Widget platformView) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!widget.shrinkWrap && constraints.hasBoundedWidth) {
          return SizedBox(height: widget.height, child: platformView);
        }
        // Until measured, estimate so the view never gets infinite width.
        final view = SizedBox(
          height: widget.height,
          width: _intrinsicWidth ?? _segmentCount * 64.0,
          child: platformView,
        );
        return widget.shrinkWrap && constraints.hasBoundedWidth
            ? Center(child: view)
            : view;
      },
    );
  }

  @override
  void didCreateNativeView(MethodChannel channel) => _measure();

  @override
  void didSendNativeUpdates(Set<String> methods) {
    if (methods.contains('setItems')) _measure();
  }

  Future<void> _measure() async {
    final size = await measureNativeView();
    if (size != null && size.width > 0) {
      setState(() => _intrinsicWidth = size.width);
    }
  }

  @override
  void handleNativeEvent(String method, Map<Object?, Object?> args) {
    final index = (args['index'] as num?)?.toInt();
    if (method == 'valueChanged' && index != null) {
      recordNativeState('setSelectedIndex', {'index': index});
      widget.onValueChanged(index);
    }
  }
}
