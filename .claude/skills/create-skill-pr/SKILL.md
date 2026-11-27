---
name: create-skill-pr
description: Open a pull request for agent configuration changes — skills and rules in .claude/, the .cursor/ links, AGENTS.md, CLAUDE.md. Use when no code changed. Automatically routed from create-pr when only agent config files are changed.
---

## Purpose
Create a PR for agent configuration changes. Use this whenever **all** changed
files are agent config. If the branch also changes code (`.dart`, `.swift`,
tests, assets, pubspec, README), use `create-pr` instead.

## Triggers
- "open a PR for this skill", "create a skill PR", "PR the rule changes"
- Routed here from `create-pr`

---

## File Restrictions

```bash
git fetch origin
git diff origin/main...HEAD --name-only
```

**Permitted paths** (ALL changed files must match):
- `.claude/` — skills, rules, settings
- `.cursor/` — Cursor config and symlinks
- `AGENTS.md`, `CLAUDE.md`

Anything else means this is not a skill-only PR. Ask the user to either move
those changes to another branch or use `create-pr`.

---

## Commit Convention

Follow `.claude/rules/git-conventions.md`:

- Type is `docs` for skill/rule content, `chore` for settings or tooling wiring
- Scope is `skills`, `rules`, or `agents` (for AGENTS.md / CLAUDE.md / .cursor)
- No AI attribution, no trailing period, imperative tense

```bash
# DO
docs(skills): add create-component skill
docs(rules): document channel naming in platform-views
chore(agents): link cursor rules to .claude

# DON'T
docs: update skill                                # missing scope
docs(skills/create-component): add step 8         # too granular
```

Fix non-conforming messages (with the user's permission) before opening the PR.

---

## PR Title

- With ticket: `[TICKET-N] Short Description`
- Without ticket: `[Docs] Short Description` or `[Chore] Short Description`
- Title Case, max 70 characters

```
# DO
[Chore] Agent Skills and Rules
[Docs] Add Swift Style Rule

# DON'T
docs(skills): update create-pr   # commit format
[Docs] updated skills            # lowercase, past tense
```

---

## PR Description

Short and factual. No checklists or testing sections — no code changed.

```markdown
## What Changed
- Brief description of each skill/rule file changed and why

## Why
One sentence on the reason for the change.
```

---

## Workflow

1. Verify all changed files are agent config — stop if not
2. Verify commit messages — fix if not (ask first)
3. Draft title + description and show the user for approval
4. Once approved:

```bash
git push -u origin HEAD

gh pr create \
  --base main \
  --title "<title>" \
  --body "<drafted body>"
```

5. Return the PR URL

---

## Source of Truth

`.claude/skills/` and `.claude/rules/` are the source of truth. `.cursor/skills`
and `.cursor/rules` are symlinks to them — always edit the files under
`.claude/`, never replace the symlinks with copies.

## See Also
- `create-pr` — for code PRs
