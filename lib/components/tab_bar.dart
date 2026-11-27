import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../channel/native_view_state.dart';
import '../channel/params.dart';
import '../style/sf_symbol.dart';

/// Immutable data describing a single tab bar item.
class CNTabBarItem {
  /// Creates a tab bar item description.
  const CNTabBarItem({this.label, this.icon});

  /// Optional tab item label.
  final String? label;

  /// Optional SF Symbol for the item.
  final CNSymbol? icon;
}

/// A Cupertino-native tab bar. Uses native UITabBar/NSTabView style visuals.
class CNTabBar extends StatefulWidget {
  /// Creates a Cupertino-native tab bar.
  const CNTabBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.tint,
    this.backgroundColor,
    this.iconSize,
    this.height,
    this.split = false,
    this.rightCount = 1,
    this.shrinkCentered = true,
    this.splitSpacing = 8.0,
  });

  /// Items to display in the tab bar.
  final List<CNTabBarItem> items;

  /// The index of the currently selected item.
  final int currentIndex;

  /// Called when the user selects a new item.
  final ValueChanged<int> onTap;

  /// Accent/tint color.
  final Color? tint;

  /// Background color for the bar.
  final Color? backgroundColor;

  /// Overrides the icon size of every item.
  final double? iconSize;

  /// Fixed height; if null uses intrinsic height reported by native view.
  final double? height;

  /// When true, splits items between left and right sections. iOS only; on
  /// macOS all items render in a single group.
  final bool split;

  /// How many trailing items to pin right when [split] is true.
  final int rightCount;

  /// When true and [split] is false, sizes the bar to its intrinsic width
  /// instead of filling the available width.
  final bool shrinkCentered;

  /// Gap between left/right halves when split.
  final double splitSpacing;

  @override
  State<CNTabBar> createState() => _CNTabBarState();
}

class _CNTabBarState extends NativeViewState<CNTabBar> {
  double? _intrinsicHeight;
  double? _intrinsicWidth;

  @override
  String get viewType => 'CupertinoNativeTabBar';

  @override
  NativeState describeNativeState(BuildContext context) => {
    'setItems': {
      'items': [
        for (final item in widget.items)
          {
            'label': item.label,
            'symbol': item.icon?.encode(context, size: widget.iconSize),
          },
      ],
    },
    'setLayout': {
      'split': widget.split,
      'rightCount': widget.rightCount,
      'splitSpacing': widget.splitSpacing,
    },
    'setSelectedIndex': {'index': widget.currentIndex},
    'setStyle': {
      'tint': resolveColorToArgb(
        widget.tint ?? CupertinoTheme.of(context).primaryColor,
        context,
      ),
      'backgroundColor': resolveColorToArgb(widget.backgroundColor, context),
    },
  };

  @override
  Widget buildFallback(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: CupertinoTabBar(
        items: [
          for (final item in widget.items)
            BottomNavigationBarItem(
              icon: const Icon(CupertinoIcons.circle),
              label: item.label,
            ),
        ],
        currentIndex: widget.currentIndex,
        onTap: widget.onTap,
        backgroundColor: widget.backgroundColor,
        inactiveColor: CupertinoColors.inactiveGray,
        activeColor: widget.tint ?? CupertinoTheme.of(context).primaryColor,
      ),
    );
  }

  @override
  Widget layoutNativeView(BuildContext context, Widget platformView) {
    final height = widget.height ?? _intrinsicHeight ?? 50.0;
    final width = !widget.split && widget.shrinkCentered
        ? _intrinsicWidth
        : null;
    return SizedBox(height: height, width: width, child: platformView);
  }

  @override
  void didCreateNativeView(MethodChannel channel) => _measure();

  @override
  void didSendNativeUpdates(Set<String> methods) {
    if (methods.contains('setItems') || methods.contains('setLayout')) {
      _measure();
    }
  }

  Future<void> _measure() async {
    final size = await measureNativeView();
    if (size == null) return;
    setState(() {
      if (size.height > 0) _intrinsicHeight = size.height;
      if (size.width > 0) _intrinsicWidth = size.width;
    });
  }

  @override
  void handleNativeEvent(String method, Map<Object?, Object?> args) {
    final index = (args['index'] as num?)?.toInt();
    if (method == 'valueChanged' &&
        index != null &&
        index != widget.currentIndex) {
      recordNativeState('setSelectedIndex', {'index': index});
      widget.onTap(index);
    }
  }
}
