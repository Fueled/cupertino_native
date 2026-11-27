import 'package:flutter/cupertino.dart';

import '../style/sf_symbol.dart';

/// Converts a [Color] to ARGB int (0xAARRGGBB). Private helper.
int? _argbFromColor(Color? color) {
  if (color == null) return null;
  // Use component accessors recommended by lints (.a/.r/.g/.b as doubles 0..1)
  final a = (color.a * 255.0).round() & 0xff;
  final r = (color.r * 255.0).round() & 0xff;
  final g = (color.g * 255.0).round() & 0xff;
  final b = (color.b * 255.0).round() & 0xff;
  return (a << 24) | (r << 16) | (g << 8) | b;
}

/// Resolves a possibly dynamic Cupertino color to a concrete ARGB int
/// for the current [BuildContext]. Falls back to the raw color if not dynamic.
int? resolveColorToArgb(Color? color, BuildContext context) {
  if (color == null) return null;
  if (color is CupertinoDynamicColor) {
    final resolved = color.resolveFrom(context);
    return _argbFromColor(resolved);
  }
  return _argbFromColor(color);
}

/// Wire encoding of a [CNSymbol], decoded natively by `SymbolSpec`.
extension CNSymbolEncoding on CNSymbol {
  /// Encodes this symbol for the native side, resolving colors against
  /// [context].
  ///
  /// The optional parameters are widget-level overrides; when non-null they
  /// win over the symbol's own values.
  Map<String, Object?> encode(
    BuildContext context, {
    double? size,
    Color? color,
    List<Color>? paletteColors,
    CNSymbolRenderingMode? mode,
    bool? gradient,
  }) {
    final palette = paletteColors ?? this.paletteColors;
    return {
      'name': name,
      'size': size ?? this.size,
      'color': resolveColorToArgb(color ?? this.color, context),
      'paletteColors': palette
          ?.map((c) => resolveColorToArgb(c, context))
          .toList(),
      'mode': (mode ?? this.mode)?.name,
      'gradient': gradient ?? this.gradient ?? false,
    };
  }
}
