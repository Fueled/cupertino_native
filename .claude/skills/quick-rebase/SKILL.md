---
name: quick-rebase
description: Quickly rebase the current branch onto its parent (usually main) without running format, analyze, test, or native build checks. Use when you just want the rebase done. If conflicts come up, fall back to /rebase for the full flow.
---

# Quick Rebase

Fast path for rebasing onto the parent branch. Skips all post-rebase validation.

If conflicts arise, **abort and suggest `/rebase`**, which has the
conflict-resolution guidance and post-rebase checks.

## Steps

### 1. Pre-flight

```bash
git status
git branch --show-current
```

- Refuse if on `main`.
- Working tree must be clean. If not, stop and ask the user how to handle it (no
  auto-commit in the quick path).

### 2. Detect parent branch

Use the same detection as the `rebase` skill (step 2): the closest remote branch
by merge base, excluding this branch and branches stacked on it. Usually
`origin/main`. Store it as `PARENT_BRANCH`; ask the user if it's unclear.

### 3. Rebase

```bash
git fetch origin
git rebase $PARENT_BRANCH
```

- Clean finish: report success.
- Conflicts: abort and hand off.

```bash
git rebase --abort
```

Tell the user: "Hit conflicts during rebase. Run `/rebase` for the full
conflict-resolution flow with post-rebase checks."

### 4. Report

```
Quick rebase complete.

Branch: <branch-name>
Rebased onto: <parent-branch> (<short-sha>)
Commits replayed: <N>

Skipped: format, analyze, tests, native builds. Run /rebase for full validation.
```

Remind the user the next push needs `--force-with-lease` and ask for confirmation
before pushing.
