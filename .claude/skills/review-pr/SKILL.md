---
name: review-pr
description: Validates the current branch before opening a PR. Runs format/fix, then analyze, tests, native compile checks, and a diff review in parallel via sub-agents. Use before creating a pull request.
---

# Review PR

Validate the current branch is ready for a pull request into `main` (or the
branch it is stacked on).

## Steps

1. **Check git state**
2. **Run lint fixes** (sequential — modifies code)
3. **Run analyze + test + native build + diff review** (parallel — read-only)
4. **Summarize findings**

---

## 1. Check Git State

```bash
git fetch origin
git status
git branch --show-current
git log --oneline origin/main..HEAD
```

- Determine `BASE_BRANCH`: default `main`. If the branch was cut from another
  unmerged feature branch, that branch is the base (use the stacked-branch
  detection in the `create-pr` skill).
- Show this branch's commits: `git log origin/<BASE_BRANCH>..HEAD --oneline`.
- Confirm there are no uncommitted changes that should be included. If there are
  untracked or unstaged files the user likely wants, flag them and ask.
- Confirm the branch name follows `.claude/rules/git-conventions.md`.
- Note whether the diff touches Swift:
  ```bash
  git diff origin/<BASE_BRANCH>...HEAD --name-only | grep -E '^(ios|macos)/.*\.swift$'
  ```

---

## 2. Run Lint Fixes (sequential — modifies code)

```bash
dart fix --apply && dart format .
```

If this fails, **stop** and report the error.

Then check for formatter-induced changes:

```bash
git status
git diff --stat
```

- If files changed, fold them in before continuing:
  - **Only one commit on the branch**, or the formatter only touched files from the
    last commit → amend:
    ```bash
    git add <modified files>
    git commit --amend --no-edit
    ```
  - Otherwise create a separate commit:
    ```bash
    git add <modified files>
    git commit -m "style(<scope>): apply dart formatter"
    ```
- Ask the user before amending or committing if they haven't already authorized commits.
- Do not proceed until the working tree is clean.

---

## 3. Run Checks + Diff Review (parallel — read-only)

Launch sub-agents in parallel with the Agent tool. Each check command runs
**exactly once** — they are slow. Each agent's prompt MUST include: "Run the
command exactly once. Do NOT use sed, head, tail, cat, or other Bash commands to
re-read the output — report from the Bash tool result directly."

- **Agent A — Analyze**: `flutter analyze` from the project root. Report pass/fail
  and every warning/error (missing `///` docs count as failures).
- **Agent B — Test**: `flutter test` from the project root. Report pass/fail, test
  counts, and failures.
- **Agent C — Native build** (only if Swift changed): from `example/`, run
  `flutter build macos --debug` and then `flutter build ios --debug --no-codesign`.
  Report pass/fail and any Swift compiler errors with file:line.
- **Agent D — Diff review**: review `git diff origin/<BASE_BRANCH>...HEAD` against
  `.claude/rules/platform-views.md`, `dart-code-style.md`, and
  `swift-code-style.md`. Check for:
  - `[PARITY]` — change made on iOS but not macOS (or vice versa), or a Dart →
    native method not handled on one platform
  - `[CHANNEL]` — view type / channel name / method name / argument key that
    doesn't match across Dart, iOS, and macOS
  - `[API]` — new public member without `///` docs, new component not exported from
    `lib/cupertino_native.dart`, breaking change to an existing public API
  - `[DEMO]` — new component or property not shown in `example/lib/demos/`, or
    a new demo not linked from `example/lib/main.dart`
  - `[AVAIL]` — Swift API above iOS 18 / macOS 12 without an `#available` guard
    (iOS/macOS 26 APIs also need `#if compiler(>=6.2)`)
  - `[SECRET]` — keys, tokens, signing material
  - `[DEBUG]` — `print()`, `debugPrint()`, Swift `print(`/`NSLog`, commented-out
    code, unowned TODOs
  - `[BUG]` — a state method whose args drop keys when null (so the prop can't
    be cleared), a user change not passed through `recordNativeState`, force
    casts on channel data, `context` used across an async gap, closures that
    capture `self` strongly in native views, a component bypassing
    `NativeViewState` / `NativeView`
  - `[DOCS]` — README/CHANGELOG not updated for a user-visible change
  Report the diff stat and issues grouped by tag with file:line.

Wait for all agents. If any reports a failure or blocking issue, **stop** and
report — don't proceed to creating the PR.

---

## 4. Summarize Findings

### All clear

```
✓ flutter analyze passed
✓ flutter test passed (<N> tests)
✓ example builds for macOS and iOS simulator   (or: skipped — no Swift changes)
✓ No issues found in diff

Branch: <branch-name>
Commits: <N>
Files changed: <N>

Manual check still needed: run the demo on iOS + macOS, light/dark.
```

### Issues found

```
✗ <check> failed — see output above

Issues found:
- [PARITY] macos/Classes/Views/CupertinoSliderNSView.swift: setStep not handled
- [CHANNEL] lib/components/stepper.dart:140: viewType 'CupertinoNativeSteper' ≠ 'CupertinoNativeStepper'
- [API] lib/components/stepper.dart:22: public field `step` has no doc comment
```

Do not suggest creating the PR until all blockers are resolved.
