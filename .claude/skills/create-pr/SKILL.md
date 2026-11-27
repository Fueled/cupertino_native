---
name: create-pr
description: Creates a pull request into main (or the branch it is stacked on) using the project PR template. Use after review-pr has passed. Pushes the branch if needed and opens the PR on GitHub.
---

# Create PR

Open a pull request from the current branch to its base branch using the project
PR template.

## Steps

0. **Route check**
1. **Gather branch info**
2. **Draft PR title and body**
3. **Confirm with user**
4. **Push and create PR**

---

## 0. Route Check — Agent Config PRs

```bash
git fetch origin
git diff origin/main...HEAD --name-only
```

If **all** changed files are agent configuration (`.claude/`, `.cursor/`,
`AGENTS.md`, `CLAUDE.md`), use the `create-skill-pr` skill instead and stop here.

---

## 1. Gather Branch Info

```bash
git status -sb
git log --oneline origin/main..HEAD
```

**Stacked-branch detection** — if this branch was cut from another *unmerged*
branch, that branch is the base:

```bash
CURRENT=$(git rev-parse --abbrev-ref HEAD)
for ref in $(git for-each-ref --format='%(refname:short)' refs/remotes/origin | grep -vE "^origin(/HEAD|/main)?$"); do
  [[ "$ref" == "origin/$CURRENT" ]] && continue
  if git merge-base --is-ancestor "$ref" HEAD && ! git merge-base --is-ancestor "$ref" origin/main; then
    echo "candidate base: $ref (commits on top: $(git rev-list --count "$ref"..HEAD))"
  fi
done
```

Pick the candidate with the FEWEST commits on top; its name minus `origin/` is
`BASE_BRANCH`. Otherwise `BASE_BRANCH=main`.

```bash
git log origin/<BASE_BRANCH>..HEAD --oneline
git diff origin/<BASE_BRANCH>...HEAD --stat
```

- If there are uncommitted changes:
  - **Formatter-only** → commit them as `style(<scope>): apply dart formatter`
    (with the user's permission).
  - **Substantive** → ask whether to include them.
  - Do not push until the working tree is clean.
- If `BASE_BRANCH` isn't `main`, find its PR:
  ```bash
  gh pr list --head <BASE_BRANCH> --state open
  ```
  Store the number as `BASE_PR_NUMBER`.

---

## 2. Draft PR Title and Body

### Title
- With ticket(s): `[TICKET-N] Short Description` (multiple: `[CN-1.CN-4] …`)
- Without ticket: `[Type] Short Description` — `Feat`, `Fix`, `Chore`, `Docs`,
  `Refactor`, `Test`, `Style`, `Perf`, from the dominant commit type
- Title Case, max 70 characters
- Only take ticket numbers from commits unique to this branch
  (`origin/<BASE_BRANCH>..HEAD`) and from the branch name.

### Body

If `.github/pull_request_template.md` exists, use it. Otherwise use:

```markdown
### What changes does your PR introduce?

This PR:

1. <one numbered item per logical change / commit>

Depends on #<BASE_PR_NUMBER>

### Platforms verified

- [ ] iOS (simulator/device + version)
- [ ] macOS (version)
- [ ] Light and dark mode

### Do your changes cause any side effects?

<!-- Breaking API changes, behaviour changes in existing components -->

### Do you want any specific feedback?

<!-- [Text here] -->

### Screenshots

<!-- iOS / macOS screenshots for visual changes -->

## Checklist
- [ ] Public API has `///` docs and follows [Effective Dart](https://dart.dev/effective-dart/style)
- [ ] Implemented on both iOS and macOS
- [ ] Demo page updated in `example/lib/demos/`
- [ ] README / CHANGELOG updated if user-visible
- [ ] `flutter analyze` and `flutter test` pass
```

- Fill **What changes** from the commit log and diff.
- Keep the `Depends on` line only when `BASE_PR_NUMBER` exists.
- Pre-check (`[x]`) checklist items that `review-pr` confirmed. Leave platform
  verification unchecked unless the user told you they tested it.
- Leave side effects / feedback / screenshots as comments for the user.

---

## 3. Confirm With User

Show the target branch, title, and body. Ask: **"Does this look good? I'll push
the branch and open the PR."** Do not proceed until the user confirms.

---

## 4. Push and Create PR

```bash
git push -u origin HEAD

gh pr create \
  --base <BASE_BRANCH> \
  --title "<title>" \
  --body "<drafted body>"
```

- Always `git push -u origin HEAD` so the upstream is the branch itself, not `main`.
- Use the detected `BASE_BRANCH`, not a hardcoded `main`.
- Never `--force` unless the user explicitly asks.
- No AI attribution lines in the PR body.
- Output the PR URL.
