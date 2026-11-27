---
paths:
  - "lib/**/*.dart"
  - "example/lib/**/*.dart"
---

# Dart Code Style

## String Values — CRITICAL
When copying or modifying code, NEVER alter quote characters inside string values.
- ❌ Never convert `"Don't"` to `"Don’t"` (curly apostrophe)
- ✅ Preserve exact characters within string literals character-for-character

This matters doubly here: view types, channel names, method names, and SF Symbol
names are all string literals that must match the Swift side exactly.

## Public API Docs — CRITICAL
`analysis_options.yaml` enables `public_member_api_docs` for `lib/`. Every public
class, constructor, field, and method needs a `///` doc comment, or
`flutter analyze` fails.
- ✅ Describe what the member does and, for props, what the native control does with it
- ✅ Reference other members with `[CNSwitch]`-style brackets
- ❌ Don't restate the name (`/// The value.` on `value`)

The `example/` app is excluded from this lint.

## Comments
- ❌ Avoid comments for obvious operations
- ✅ Add comments only for complex logic or non-obvious behavior (e.g. why a
  platform view needs a finite width, why a post-frame callback is used)
- ✅ Keep `//` inline comments brief

## Reuse Existing Utilities — Don't Duplicate

Before adding a helper, search for an existing one and reuse it.

- **Color → native**: `resolveColorToArgb` and `encodeStyle` in
  `lib/channel/params.dart`. Don't hand-roll ARGB conversion.
- **SF Symbols**: `CNSymbol` and `CNSymbolRenderingMode` in `lib/style/sf_symbol.dart`.
- **Button styles**: `lib/style/button_style.dart`.
- If a new style key is needed by several components, add it to `encodeStyle`
  rather than encoding it locally.

If you suspect a helper already exists but aren't sure it fits, STOP and ask
before building a new one.

## Public API Shape
- Prefix public widgets, controllers, and style types with `CN`.
- Use `const` constructors with `super.key` and named parameters; mark required
  inputs `required` and give optional visual props sensible defaults.
- Prefer named constructors for variants (e.g. `CNButton.icon`,
  `CNPopupMenuButton.icon`) over boolean mode flags.
- Expose imperative control through an optional `CN<Name>Controller` whose
  methods no-op when no channel is attached.
- Keep channel plumbing (`MethodChannel`, `_last*` caches) private to the `State`.
- Export every new public file from `lib/cupertino_native.dart`.

## Widget Method Naming
Omit the "build" prefix from private widget builder methods:
```dart
// ✅ Good
Widget _fallback() { ... }
Widget _platformView() { ... }

// ❌ Bad
Widget _buildFallback() { ... }
```

## Widget Composition
- Use a private widget class (not a function) when the piece has its own state,
  lifecycle, or is reused.
- Functions are fine for simple stateless snippets.

## TODO Comments
Format: `// TODO: (Name) Description`

```dart
// ✅ Good
// TODO: (Jane) Support step on iOS slider

// ❌ Bad — missing name or description
// TODO: fix
```

## Color Opacity — CRITICAL
Always use `withValues(alpha:)` instead of the deprecated `withOpacity()`:
```dart
// ✅ Good
color: CupertinoColors.systemBlue.withValues(alpha: 0.3)

// ❌ Bad
color: CupertinoColors.systemBlue.withOpacity(0.3)
```

Use the `.a/.r/.g/.b` component accessors, not the deprecated `.alpha/.red/…`
or `.value` getters.

## Avoid the `Opacity` Widget
`Opacity` forces an offscreen render pass — and over a platform view it may not
apply to the native layer at all. Fold alpha into the color instead (and pass
that color to native), and use `Opacity` only for composite Flutter-only subtrees.
