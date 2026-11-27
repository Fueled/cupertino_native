import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

import '../channel/native_view_state.dart';
import '../channel/params.dart';
import '../channel/press_listener.dart';
import '../style/button_style.dart';
import '../style/sf_symbol.dart';

/// Base type for entries in a [CNPopupMenuButton] menu.
abstract class CNPopupMenuEntry {
  /// Const constructor for subclasses.
  const CNPopupMenuEntry();
}

/// A selectable item in a popup menu.
class CNPopupMenuItem extends CNPopupMenuEntry {
  /// Creates a selectable popup menu item.
  const CNPopupMenuItem({
    required this.label,
    this.icon,
    this.enabled = true,
    this.checked = false,
  });

  /// Display label for the item.
  final String label;

  /// Optional SF Symbol shown before the label.
  final CNSymbol? icon;

  /// Whether the item can be selected.
  final bool enabled;

  /// Whether the item should display a check mark.
  final bool checked;
}

/// A visual divider between popup menu items.
class CNPopupMenuDivider extends CNPopupMenuEntry {
  /// Creates a visual divider between items.
  const CNPopupMenuDivider();
}

/// A Cupertino-native popup menu button.
///
/// On iOS/macOS this embeds a native popup button and shows a native menu.
class CNPopupMenuButton extends StatefulWidget {
  /// Creates a popup menu button with a custom child widget.
  ///
  /// The entire area of the child widget will be clickable to open the menu.
  /// A transparent native button overlay is used to handle menu interactions.
  const CNPopupMenuButton({
    super.key,
    required this.child,
    required this.items,
    required this.onSelected,
    this.tint,
  }) : buttonLabel = null,
       buttonIcon = null,
       width = null,
       round = false,
       height = null,
       shrinkWrap = false,
       buttonStyle = CNButtonStyle.plain;

  /// Creates a text-labeled popup menu button.
  const CNPopupMenuButton.label({
    super.key,
    required this.buttonLabel,
    required this.items,
    required this.onSelected,
    this.tint,
    this.height = 32.0,
    this.shrinkWrap = false,
    this.buttonStyle = CNButtonStyle.plain,
  }) : child = null,
       buttonIcon = null,
       width = null,
       round = false;

  /// Creates a round, icon-only popup menu button.
  const CNPopupMenuButton.icon({
    super.key,
    required this.buttonIcon,
    required this.items,
    required this.onSelected,
    this.tint,
    double size = 44.0,
    this.buttonStyle = CNButtonStyle.glass,
  }) : child = null,
       buttonLabel = null,
       round = true,
       width = size,
       height = size,
       shrinkWrap = false,
       super();

  /// Custom child widget to display (non-null when using child constructor).
  final Widget? child;

  /// Text for the button (null when using [buttonIcon] or [child]).
  final String? buttonLabel;

  /// Icon for the button (non-null in icon mode).
  final CNSymbol? buttonIcon;

  /// Fixed width in icon mode; otherwise computed/intrinsic.
  final double? width;

  /// Whether this is the round icon variant.
  final bool round;

  /// Entries that populate the popup menu.
  final List<CNPopupMenuEntry> items;

  /// Called with the selected index when the user makes a selection.
  ///
  /// Indices count every entry in [items], including dividers.
  final ValueChanged<int> onSelected;

  /// Tint color for the control.
  final Color? tint;

  /// Control height; icon mode uses diameter semantics. Null when using [child].
  final double? height;

  /// If true, sizes the control to its intrinsic width.
  final bool shrinkWrap;

  /// Visual style to apply to the button.
  final CNButtonStyle buttonStyle;

  /// Whether this instance is configured as an icon button variant.
  bool get isIconButton => buttonIcon != null;

  /// Whether this instance uses a custom child widget.
  bool get hasChild => child != null;

  @override
  State<CNPopupMenuButton> createState() => _CNPopupMenuButtonState();
}

class _CNPopupMenuButtonState extends NativeViewState<CNPopupMenuButton> {
  double? _intrinsicWidth;

  bool get _isLabelButton => !widget.isIconButton && !widget.hasChild;

  @override
  String get viewType => 'CupertinoNativePopupMenuButton';

  @override
  NativeState describeNativeState(BuildContext context) => {
    'setContent': {
      'title': widget.buttonLabel,
      'symbol': widget.buttonIcon?.encode(context),
    },
    'setStyle': {
      'buttonStyle': widget.buttonStyle.name,
      'tint': resolveColorToArgb(
        widget.tint ?? CupertinoTheme.of(context).primaryColor,
        context,
      ),
      'round': widget.round,
      // Child mode: an invisible native button over the Flutter child.
      'transparent': widget.hasChild,
    },
    'setItems': {
      'items': [
        for (final entry in widget.items)
          switch (entry) {
            CNPopupMenuItem() => {
              'label': entry.label,
              'symbol': entry.icon?.encode(context),
              'enabled': entry.enabled,
              'checked': entry.checked,
            },
            _ => {'divider': true},
          },
      ],
    },
  };

  @override
  Set<Factory<OneSequenceGestureRecognizer>> get gestureRecognizers => {
    Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
  };

  Future<void> _showFallbackMenu() async {
    final selected = await showCupertinoModalPopup<int>(
      context: context,
      builder: (sheetContext) => CupertinoActionSheet(
        title: widget.buttonLabel != null ? Text(widget.buttonLabel!) : null,
        actions: [
          for (var i = 0; i < widget.items.length; i++)
            if (widget.items[i] case final CNPopupMenuItem item)
              CupertinoActionSheetAction(
                onPressed: () => Navigator.of(sheetContext).pop(i),
                child: Text(item.label),
              )
            else
              const SizedBox(height: 8),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(sheetContext).pop(),
          isDefaultAction: true,
          child: const Text('Cancel'),
        ),
      ),
    );
    if (selected != null && mounted) widget.onSelected(selected);
  }

  @override
  Widget buildFallback(BuildContext context) {
    if (widget.hasChild) {
      return GestureDetector(onTap: _showFallbackMenu, child: widget.child);
    }
    return SizedBox(
      height: widget.height,
      width: widget.isIconButton ? (widget.width ?? widget.height) : null,
      child: CupertinoButton(
        padding: widget.isIconButton
            ? const EdgeInsets.all(4)
            : const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        onPressed: _showFallbackMenu,
        child: widget.isIconButton
            ? Icon(CupertinoIcons.ellipsis, size: widget.buttonIcon?.size)
            : Text(widget.buttonLabel ?? ''),
      ),
    );
  }

  @override
  Widget layoutNativeView(BuildContext context, Widget platformView) {
    Widget pressable(Widget child) => PressListener(
      onPressedChanged: (pressed) =>
          sendNativeCommand('setPressed', {'pressed': pressed}),
      child: child,
    );

    if (widget.hasChild) {
      return Stack(
        children: [
          widget.child!,
          Positioned.fill(child: pressable(platformView)),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        double? width;
        if (widget.isIconButton) {
          width = widget.width ?? widget.height;
        } else if (widget.shrinkWrap || !constraints.hasBoundedWidth) {
          width = _intrinsicWidth ?? 80.0;
        }
        return pressable(
          SizedBox(height: widget.height, width: width, child: platformView),
        );
      },
    );
  }

  @override
  void didCreateNativeView(MethodChannel channel) {
    if (_isLabelButton) _measure();
  }

  @override
  void didSendNativeUpdates(Set<String> methods) {
    if (_isLabelButton && methods.contains('setContent')) _measure();
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
    if (method == 'itemSelected' && index != null) widget.onSelected(index);
  }
}
