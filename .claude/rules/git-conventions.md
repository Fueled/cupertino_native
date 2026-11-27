---
description: Fueled Git conventions for cupertino_native — trunk-based on main, conventional commits, branch naming, PR standards, agent git safety
---

# Fueled Git Conventions

> applies-to: this repo (Flutter plugin + iOS/macOS Swift)
> workflow: trunk-based — short-lived branches off `main`, merged by PR
> commits: conventional commits
> branch-naming: lowercase-dashed with optional ticket prefix

---

## Branch Model

- `main` — the only long-lived branch. Always releasable; pub.dev releases are cut from it.
- Feature branches — created per task off `origin/main`, merged back via PR.
- FORBIDDEN: committing directly to `main`.
- DO NOT keep a stale local `main` — always branch from `origin/main`.

---

## Branch Naming

- Format: `<type>/<TICKET-N>.<description>` or `<type>/<description>` (no ticket)
- The type prefix matches the commit type: `feat/`, `fix/`, `chore/`, `docs/`, `refactor/`, `perf/`, `test/`, `style/`.
- **Ticket prefix MUST be UPPERCASE** (e.g. `CN-12`) — lowercase ticket prefixes are forbidden.
- Max 40 characters for the description part (after the dot, or after `<type>/` if no ticket).
- Regex for ticket-prefixed branches: `(feat|fix|chore|docs|refactor|perf|test|style)/[A-Z]{1,5}\-\d{1,5}\.[a-zA-Z\-]{1,40}`
- Regex for plain branches: `(feat|fix|chore|docs|refactor|perf|test|style)/[a-z\-]{1,40}`

```bash
# DO
git checkout -b feat/date-picker origin/main
git checkout -b fix/macos-switch-checkbox origin/main
git checkout -b feat/CN-12.liquid-glass-toolbar origin/main
git checkout -b chore/agent-skills-and-rules origin/main

# DON'T
git checkout -b feat/cn-12.toolbar origin/main          # lowercase ticket prefix
git checkout -b feature/date-picker origin/main         # use feat/ not feature/
git checkout -b DatePicker origin/main                  # no type, uppercase
git checkout -b fix/the-slider-jumps-when-you-drag-it-quickly-on-macos origin/main  # too long
```

---

## Commit Message Format

- Format: `type(scope): description`
- One logical change per commit — if the change is hard to summarize in one line, split it into multiple commits.
- If a commit cannot be categorized with a single type, split it into separate commits.

### Types

| Type | Description |
|------|-------------|
| `feat` | A new component, property, or capability |
| `fix` | A bug fix |
| `docs` | Documentation-only changes (README, dart docs, rules, skills) |
| `style` | Code style only: formatting, whitespace — no logic change. NOT for UI/visual changes (use `feat`, `fix`, or `refactor`) |
| `refactor` | Code change that neither fixes a bug nor adds a feature |
| `perf` | A change that improves performance |
| `test` | Adding or updating tests — no production code change |
| `chore` | Build, tooling, dependency, version bumps — no production code change |

### Scope

- Always include a scope.
- Prefer the component (snake_case file name, dashes allowed): `switch`, `slider`,
  `button`, `icon`, `tab-bar`, `segmented-control`, `popup-menu-button`.
- Otherwise a platform or area: `ios`, `macos`, `example`, `channel`, `style`,
  `deps`, `release`, `skills`, `rules`.
- Combine with a slash for sub-areas: `switch/macos`.
- Ticket numbers go after the scope: `switch/CN-12`.
- Use `*` for changes that span many areas: `refactor(*): unify channel error handling`.
- No spaces, no capitals other than ticket numbers.

### Description Rules

- Imperative, present tense: "add" not "added" or "adds".
- Lowercase start.
- No trailing period.
- Max ~50 characters (after the `type(scope):` prefix).
- FORBIDDEN: `Co-Authored-By` trailers or any AI attribution lines in commit messages.

```bash
# DO
git commit -m "feat(slider): add step support on ios"
git commit -m "fix(switch/macos): render as switch not checkbox"
git commit -m "docs(button): document glass styles"
git commit -m "chore(release): bump version to 0.1.2"

# DON'T
git commit -m "fix: Fixes switch to not toggle."        # no scope, capitalized, past/3rd person, period
git commit -m "feat(slider): add step and fix tint"     # two changes in one commit
git commit -m "feat(Slider): add step support."         # uppercase scope, trailing period
```

> Older history in this repo predates these conventions (`fix: Fixes …`). Don't
> rewrite it; follow the format above for all new commits.

---

## Git Workflow

- DO run `git fetch` before creating a new branch.
- DO create branches from the remote: `git checkout -b <branch> origin/main`, then
  `git branch --unset-upstream` (or push with `-u`) so the branch doesn't track `main`.
- DO rebase onto `origin/main` before pushing: `git rebase origin/main`.
- DO resolve all conflicts from a rebase before continuing further work.
- DO open a pull request into `main`. Code review is required before merge.

```bash
git fetch
git checkout -b feat/date-picker origin/main
# ... make changes, commit ...
git fetch
git rebase origin/main
git push -u origin HEAD
# open PR to main
```

---

## Staging and Commit Hygiene

- DO stage specific files: `git add <file1> <file2>` — never `git add .` or `git add -A`.
- DO review `git diff --staged` before every commit.
- DO run `git status` before and after committing.
- A single file may contain changes belonging to different logical commits — stage only what belongs.
- Keep the Dart, iOS, macOS, and demo changes for one component change in the **same**
  commit — they only work together.
- Don't commit build output (`example/build/`, `.dart_tool/`, `.build/`, `Flutter/ephemeral/`) or
  unrelated `pubspec.lock` / Xcode project churn.

---

## Releases

- Bump `version:` in `pubspec.yaml` and add a matching `## x.y.z` section at the
  top of `CHANGELOG.md` (bulleted `* Sentence.` entries) in the same commit:
  `chore(release): bump version to x.y.z`.
- Update `README.md` (and `misc/screenshots/`) when a component is added or its
  public API changes.
- Publishing to pub.dev is done by a human — agents never run `flutter pub publish`.

---

## Pull Request Titles

PR titles use a **different format** from commit messages.

- Format with ticket: `[TICKET-N] Short Description`
- Format without ticket: `[Type] Short Description` — Type is capitalized: `Feat`, `Fix`, `Chore`, `Docs`, `Refactor`, `Test`, `Style`, `Perf`
- Description in Title Case.
- Max 70 characters total.
- FORBIDDEN: vague titles like "Fixes", "Changes", "WIP", "Updates".

```
# DO
[Feat] Date Picker Component
[Fix] MacOS Switch Rendering as Checkbox
[Chore] Agent Skills and Rules
[CN-12] Liquid Glass Toolbar

# DON'T
feat(slider): add step            # commit format, not PR format
[Fix] macos switch                # lowercase description
WIP: date picker                  # vague
```

---

## Claude Code Web — Branch Naming

The `claude/` branch prefix is **only** used when running in the Claude Code web
environment, where pushes are restricted to branches prefixed with `claude/`.
Mirror the normal convention under that prefix:

- `claude/feat/<description>` / `claude/feat/<TICKET-N>.<description>`
- `claude/fix/<description>` / `claude/fix/<TICKET-N>.<description>`
- `claude/chore/<description>`, `claude/refactor/<description>`

All other conventions still apply after the `claude/` prefix. Commits made from
Claude Code web use the **user's own Git account**.

```bash
# DO
claude/fix/macos-switch-checkbox
claude/feat/CN-12.liquid-glass-toolbar

# DON'T
claude/show-project-skills-r8nex     # task-title style, no type prefix
```

---

## Agent Safety Boundaries

- FORBIDDEN: committing or pushing without explicit user permission.
- FORBIDDEN: `git push --force` or `git push --force-with-lease` without explicit user permission.
- FORBIDDEN: destructive commands without explicit user permission:
  - `git reset --hard`
  - `git checkout .` / `git restore .`
  - `git clean -f`
  - `git branch -D`
  - `git stash drop`
- FORBIDDEN: committing files containing secrets, credentials, API keys, or signing
  material (`.env`, `*.p12`, `*.mobileprovision`, `*.pem`, `*.key`, tokens, passwords).
- If any security-sensitive content is detected in staged changes: STOP immediately, do not commit, and alert the user.
- DO always run `git status` to understand the current state before any git operation.
- DO always run `git diff --staged` to review what will be committed.
- DO verify the commit succeeded by checking `git status` after committing.
- When uncertain about any git operation, STOP and ask the user.
