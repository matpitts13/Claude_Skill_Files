# /init-steve

Initialize Steve for a new project. Run once when starting work in a new repo.

## Usage
```
/init-steve
```

## What this does

1. **Stack detection** — runs `stack-detect` skill, identifies frameworks and languages
2. **Language rules** — loads the relevant language rule files for this stack
3. **Graphify check** — runs `/graphify` if no `graphify-out/graph.json` exists
4. **SDD check** — checks if `docs/SDD.md` exists; if not, offers to create one
5. **Test harness check** — checks for `vitest.config.*` and `playwright.config.*`; if missing, offers to set up the harness via `autotest/harness.md`
6. **Memory init** — creates `~/.claude/projects/<name>/memory/` if not present; runs a brief orientation pass and saves any immediately relevant project context
7. **Permissions** — offers to run `/fewer-permission-prompts` to allowlist this repo's common read-only commands
8. **Routines (offer, never auto-create)** — if the repo has a GitHub remote, offers a weekly cloud routine via `/schedule`: tech-debt triage + `npm audit`, reporting only when something changed. Routines run on a fresh clone, so nothing that needs local-only files (`graphify-out/`, `.env`) — the SessionStart hook already keeps the graph fresh locally
9. **Status** — prints a `/status` summary

## After running

You're ready to work. The orchestrator will auto-invoke the right skills for each task based on the detected stack.
