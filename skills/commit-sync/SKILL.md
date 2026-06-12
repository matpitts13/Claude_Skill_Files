---
name: commit-sync
description: "Runs only after code-review passes. Stages specific files, writes a conventional-commit message, commits, and pushes."
---

# Commit-Sync

Invoked by orchestrator after code-review passes. This is the gated commit path — for the quick safety-check path use `/commit`.

## When to use

- Orchestrator's final step on medium/large tasks
- After `/ship` command

## Steps

1. **Verify code-review passed.** If not, stop and say so.
2. **Stage specific files** — never `git add -A`. Stage only files changed by this task.
3. **Write conventional-commit message:**
   ```
   type(scope): short summary (≤72 chars)

   - bullet: what changed and why
   - bullet: any breaking changes or notable side-effects
   ```
   Types: `feat` / `fix` / `refactor` / `test` / `docs` / `chore`
4. **Commit.**
5. **Sync** — `git pull --ff-only`. If behind and ff fails, try `git pull --no-rebase`. If that has conflicts, try `git pull --rebase` as last resort. If rebase conflicts: abort, stop, report.
6. **Push.** Never force-push. If push still fails after sync: report, stop.

## Two-strike rule

Pull fails twice → stop and report. Don't loop.

## Never

- Force-push
- `git add -A` blindly
- Commit `.env`, credentials, or secrets
