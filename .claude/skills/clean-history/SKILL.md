---
name: clean-history
description: Clean up a feature branch's commit history by folding branch-noise fix commits back into the commit that introduced the code. Use when a branch has "fix typo", "wip", "address review" commits that patch earlier work on the same branch and you want a clean history before opening a PR.
---

# Clean Branch History

Fold branch-noise fixes back into the commit that introduced the code, so the branch reads as if it was written right the first time.

A commit that fixes code introduced **earlier in this same branch** is not a real app fix. The buggy code never reached `main`, so the fix is just noise. This skill folds each such commit into its originating commit, leaving a clean, logical commit list. It only touches commits ahead of the parent branch, never the parent itself.

It does **not** push. History is rewritten locally; the next push needs `--force-with-lease`, which the user runs after confirming (see `.claude/rules/git-conventions.md`).

## When to use

- A feature branch has commits like `fix typo`, `wip`, `oops`, `lint`, `address review`, `fixup` that patch earlier commits on the same branch.
- You want a clean history before opening a PR.

**Do NOT use** to merge unrelated logical commits, collapse a whole feature into one commit, or rewrite anything already in `main`.

## Steps

### 1. Pre-flight

```bash
git status
git branch --show-current
```

- Refuse if on `main`. Stop and tell the user.
- Working tree must be clean. If dirty, stop and ask the user how to handle it — do **not** auto-commit.
- If the branch is already pushed and a PR has review comments, warn the user that
  rewriting history can detach those comments from their lines.

### 2. Detect parent branch

Use the same detection as the `rebase` skill (step 2). Usually `origin/main`:

```bash
git fetch origin
PARENT=$(git merge-base HEAD origin/main)   # or the stacked parent branch's merge base
```

Store it as `$PARENT`. If ambiguous, ask the user.

### 3. Gather commits and diffs

```bash
git log --reverse -p $PARENT..HEAD
```

- If there is only **one** commit ahead, there is nothing to fold. Report and stop.
- Read each commit's message and diff.

### 4. Classify each commit (diff-aware)

For every commit in `$PARENT..HEAD`, decide:

- **Keep** — introduces new code, OR modifies code that already exists in `$PARENT` (a real app fix that belongs in history).
- **Fold** — only modifies lines/files that were **first introduced earlier in this same branch**. Target = the **most recent earlier commit it touches**.
- **Keep + note** — touches both branch-new code and parent code. Default to keep, and flag it in the plan so the user can decide.

This is per-commit judgment, not a message-pattern match. A `fix(...)` that touches parent code stays; a `feat(...)` that only patches this-branch code can fold. To check whether a file/line predates the branch:

```bash
# does this path exist in the parent?
git cat-file -e $PARENT:<path> 2>/dev/null && echo "exists in parent" || echo "new on branch"
```

For lines within a file that exists in the parent, inspect `git log $PARENT..HEAD -- <path>` to see whether the specific code being changed was added on this branch.

### 5. Present the plan and wait for approval

Show a table of every commit:

```
KEEP   75c90eb  feat: add feature A
FOLD   4726c1b  fix: typo in feature A        → into 75c90eb (feat: add feature A)
KEEP   4d23c11  feat: add feature B
```

Then show the resulting commit list. **Wait for explicit approval.** Nothing is modified before this. If nothing is foldable, say so and stop.

### 6. Create a backup branch

```bash
BACKUP=backup/$(git branch --show-current)-$(git rev-parse --short HEAD)
git branch "$BACKUP"
```

A single `git reset --hard "$BACKUP"` restores the original history.

### 7. Rewrite history (non-interactive)

Build a rebase todo, then drive an autosquash-style rebase without the interactive `-i` prompt (which would hang in this environment).

- Start from `git rev-list --reverse $PARENT..HEAD` for the commit order.
- Emit one line per commit: `pick <sha> <subject>` for keeps.
- For each fold commit, place its line **directly below its target** with the verb `fixup` (keeps the target's message, discards the fix's message).

Write the todo inside the git dir (so it can never be committed), then run:

```bash
TODO="$(git rev-parse --absolute-git-dir)/clean-history-todo"
# $TODO contains the reordered pick/fixup lines, e.g.:
#   pick 75c90eb feat(slider): add step support
#   fixup 4726c1b fix(slider): typo in step docs
#   pick 4d23c11 feat(slider): show step in demo
GIT_SEQUENCE_EDITOR="cp $TODO" GIT_EDITOR=true git rebase -i $PARENT
```

`GIT_SEQUENCE_EDITOR` overwrites git's generated todo with ours; `GIT_EDITOR=true` accepts the kept messages without opening an editor. Remove the temp file afterward.

If the rebase hits a **conflict**, something is off (folding a fix into its own originating commit should not conflict). Do not attempt clever resolution:

```bash
git rebase --abort
git reset --hard "$BACKUP"
```

Then report to the user and stop.

### 8. Verify — tree must be identical

The rewrite must change only commit boundaries, never the final code:

```bash
git diff "$BACKUP" HEAD
```

This **must be empty**. If it is not, the rewrite is wrong — restore and stop:

```bash
git reset --hard "$BACKUP"
```

Also show old vs new history:

```bash
git log --oneline $PARENT..$BACKUP   # before
git log --oneline $PARENT..HEAD      # after
```

### 9. Report

```
History cleaned.

Branch: <branch-name>
Parent: <parent>
Folded: <N> fix commit(s) into their originating commits
Commits: <old count> → <new count>
Backup: <backup-branch-name>  (git reset --hard <backup> to restore)
Tree unchanged: verified (git diff vs backup is empty)
```

Remind the user the next push needs `git push --force-with-lease` since history was rewritten, and **ask for confirmation before pushing**. Never push automatically.

### 10. Offer to clean up the backup

Once the user has confirmed the rewrite is good (and the push, if any, has landed), **ask whether to delete the backup branch**:

```bash
git branch -D "$BACKUP"
```

Do not delete it automatically — it is the only escape hatch back to the original history. Only remove it after the user agrees.

## Common mistakes

- **Touching the parent.** Only operate on `$PARENT..HEAD`. Never reorder or fold commits that exist in `main`.
- **Folding a real fix.** A `fix(...)` that patches code already in the parent is a genuine app fix — keep it. Only fold fixes to code introduced on this branch.
- **Skipping the tree check.** The empty `git diff` against the backup is the correctness guarantee. Always run it.
- **Auto-pushing.** Stop after the rewrite. The force-push is the user's call.
- **Using `git rebase -i` without `GIT_SEQUENCE_EDITOR`.** The interactive prompt hangs in this environment. Always drive the todo non-interactively.
- **Deleting the backup without asking.** The backup branch is the recovery path. Offer to remove it, but only delete after the user confirms.
