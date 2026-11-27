---
name: rebase
description: Rebase the current branch onto the latest version of its parent branch (usually main), resolving any conflicts, then re-run format, analyze, and tests. Use when your branch is behind its parent and needs to be updated.
---

# Rebase onto Parent Branch

Rebase the current branch onto its parent, resolving conflicts along the way,
then validate.

## Steps

1. **Pre-flight checks**
2. **Detect parent branch**
3. **Fetch and start rebase**
4. **Resolve conflicts**
5. **Post-rebase validation**

---

## 1. Pre-flight Checks

```bash
git status
git branch --show-current
```

- Refuse if on `main`. Stop and tell the user.
- Working tree must be clean. If there are uncommitted changes, ask the user how to
  handle them (commit following `.claude/rules/git-conventions.md`, or stash).
  Don't commit without permission.

---

## 2. Detect Parent Branch

Never assume `origin/main` blindly — the branch may be stacked.

```bash
git fetch origin
CURRENT=$(git rev-parse --abbrev-ref HEAD)
for ref in $(git for-each-ref --format='%(refname:short)' refs/remotes/origin | grep -vE "^origin(/HEAD)?$"); do
  [[ "$ref" == "origin/$CURRENT" ]] && continue
  git merge-base --is-ancestor HEAD "$ref" && continue   # stacked on us, not our parent
  base=$(git merge-base HEAD "$ref" 2>/dev/null) || continue
  echo "$ref $(git rev-list --count "$base"..HEAD)"
done | sort -k2 -n | head -5
```

The candidate with the **fewest** commits between its merge base and HEAD is the
closest parent. Usually `origin/main`; a feature branch if stacked. Store it as
`PARENT_BRANCH` and **confirm with the user** if it isn't `origin/main`.

If the parent branch has already been merged into `main` (squash merge), rebasing
onto it is wrong — rebase onto `origin/main` with `--onto` instead and ask the
user first:

```bash
git rebase --onto origin/main <old-parent-tip> HEAD
```

---

## 3. Fetch and Start Rebase

```bash
git log --oneline HEAD..$PARENT_BRANCH | head -20
```

- Show how many new parent commits will be brought in.
- If there are none, the branch is up to date — tell the user and stop.

```bash
git rebase $PARENT_BRANCH
```

If it completes without conflicts, skip to step 5.

---

## 4. Resolve Conflicts

Handle conflicts **one commit at a time**.

### 4a. Understand
```bash
git status
git diff
```
Read each conflicted file in full. `HEAD` is the parent's side; the incoming side
is this branch's commit.

### 4b. Resolve
- Combine both intents when both sides changed the same code.
- If one side deletes code the other modifies, keep the modification unless the
  deletion was clearly intentional (check the commit message).
- **Parity check**: if the conflict is in `ios/` or `macos/`, look at the
  counterpart file and make sure the resolution is mirrored there.
- **Registration files** (`CupertinoNativePlugin.swift`, `lib/cupertino_native.dart`,
  `example/lib/main.dart`): both sides usually *add* entries — keep both.
- `pubspec.lock` / `example/pubspec.lock` / `Podfile.lock`: take the parent's
  version; dependencies are re-resolved in step 5.
- `pubspec.yaml` version and `CHANGELOG.md`: keep the parent's released version
  and put this branch's changelog lines under the right (unreleased) heading.
- Remove every conflict marker.

### 4c. Continue
```bash
git add <resolved-files>
git rebase --continue
```
Repeat for each conflicting commit. If a commit becomes empty: `git rebase --skip`.

### 4d. When to abort
If conflicts are too ambiguous to resolve confidently:
```bash
git rebase --abort
```
Tell the user which files/commits conflicted and ask for guidance.

---

## 5. Post-rebase Validation

```bash
flutter pub get
dart fix --apply && dart format .
```
If formatting changed files, ask before committing them.

Then run, in parallel via sub-agents (each command **exactly once**; agents must
report from the Bash result directly without re-reading output with sed/head/tail/cat):

- **Agent A**: `flutter analyze`
- **Agent B**: `flutter test`
- **Agent C** (only if Swift files changed on either side): from `example/`,
  `flutter build macos --debug` then `flutter build ios --debug --no-codesign`

If anything fails, fix it before declaring success. If the failure comes from the
parent branch's code rather than this branch, tell the user.

### Report

```
Rebase complete.

Branch: <branch-name>
Rebased onto: <parent-branch> (<short-sha>)
Conflicts resolved: <N> file(s) across <M> commit(s)  (or "none")
Checks: analyze ✓  test ✓  native build ✓/skipped
```

Remind the user the next push needs `git push --force-with-lease` because history
was rewritten, and **ask for confirmation before pushing**.
