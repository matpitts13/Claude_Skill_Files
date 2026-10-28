# /status

Show the current project health summary.

## What this does

Runs in order and prints a consolidated report:

1. **Git status** — clean/dirty, current branch, commits ahead/behind remote
2. **TypeScript** — `npx tsc --noEmit` — pass/fail
3. **Tests** — last known test run result (from `TEST_FIX_STATE.md` if present, or runs `npm run test`)
4. **Tech debt** — summary of `TECH_DEBT.md` if present (count by severity)
5. **Graph** — if `graphify-out/graph.json` exists, `graphify check-update .` — fresh / code drift / doc drift (needs `/graphify --update`)
6. **Memory** — recent relevant memories from `MEMORY.md`

## Output format

```
## Project Status — YYYY-MM-DD HH:mm

Git:      clean | main (0 ahead, 0 behind)
TypeScript: PASS
Tests:    PASS (last run: YYYY-MM-DD)
Tech debt: 0 critical, 1 high, 3 medium
Graph:    fresh | doc drift
```

## Usage
```
/status          # terminal report
/status --page   # also publish/refresh a private Artifact dashboard
```

## `--page`

Publish the same data as a private Artifact page. Keep one HTML file per project at `~/.claude/projects/<project>/status.html` so every run republishes to the **same URL**. Add to the page: tech-debt items listed by severity, the last 10 commits, and any stale-graph warning. Never put secrets, tokens or `.env` values on the page.
