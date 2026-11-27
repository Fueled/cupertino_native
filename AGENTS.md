# Cupertino Native

Flutter plugin that embeds native iOS (UIKit/SwiftUI) and macOS (AppKit/SwiftUI)
controls in Flutter via platform views and per-view method channels.

# Overview
- This project is a Flutter plugin which displays native iOS and MacOS widgets in Flutter using platform channels.
- The Flutter widgets are in the lib/components directory.
- Look at previous widgets when creating a new one to match the style.
- Each widget should have:
  - A separate file and class.
  - An example page in the example/demos directory
  - Corresponding Swift code for iOS and MacOS.
- Follow Flutter conventions for the Flutter widgets.
- After writing code, always check the Dart code with `flutter analyze`

## Project Rules

Detailed rules live in `.claude/rules/` (Cursor reads the same files through the
`.cursor/rules` symlink). Read the ones relevant to the files you touch:

- `.claude/rules/platform-views.md` — how a component is wired Dart ↔ channel ↔ Swift (always relevant)
- `.claude/rules/dart-code-style.md` — Dart style for `lib/` and `example/`
- `.claude/rules/swift-code-style.md` — Swift style for `ios/` and `macos/`
- `.claude/rules/testing.md` — tests under `test/` and `example/`
- `.claude/rules/git-conventions.md` — branches, commits, PRs, agent git safety

Reusable workflows live in `.claude/skills/` (also symlinked to `.cursor/skills`):
`create-component`, `review-pr`, `create-pr`, `create-skill-pr`, `rebase`,
`quick-rebase`, `clean-history`.

## Key Commands

- Analyze: `flutter analyze`
- Format / fix: `dart fix --apply && dart format .`
- Test: `flutter test`
- Run the demo app: `cd example && flutter run -d macos` (or an iOS simulator)
- Compile-check Swift: `cd example && flutter build macos --debug` / `flutter build ios --simulator --debug`

## Key Files

- Public exports: `lib/cupertino_native.dart`
- Dart components: `lib/components/`
- Shared channel helpers (colors, style encoding): `lib/channel/params.dart`
- Styles / SF Symbols: `lib/style/`
- iOS native code: `ios/Classes/` (`CupertinoNativePlugin.swift`, `Factories/`, `Views/`, `Shared/`)
- macOS native code: `macos/Classes/` (same layout as iOS)
- Demo app: `example/lib/main.dart` (component list) and `example/lib/demos/`
- Screenshots for the README: `misc/screenshots/`
- Release notes: `CHANGELOG.md`, version in `pubspec.yaml`

---

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add a property" → "Dart param, creation param, Swift parsing, update method on both platforms, demo shows it"
- "Fix the bug" → "Reproduce it in the example app (or a test), then make it pass"
- "Refactor X" → "`flutter analyze` and `flutter test` pass before and after; demo behaves the same on iOS and macOS"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.
