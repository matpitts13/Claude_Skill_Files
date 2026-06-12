# /status

Show the current project health summary.

## What this does

Runs in order and prints a consolidated report:

1. **Git status** — clean/dirty, current branch, commits ahead/behind remote
2. **TypeScript** — `npx tsc --noEmit` — pass/fail
3. **Tests** — last known test run result (from `TEST_FIX_STATE.md` if present, or runs `npx vitest run`)
4. **Tech debt** — summary of `TECH_DEBT.md` if present (count by severity)
5. **Memory** — recent relevant memories from `MEMORY.md`

## Output format

```
## Project Status — YYYY-MM-DD HH:mm

Git:      clean | main (0 ahead, 0 behind)
TypeScript: PASS
Tests:    PASS (last run: YYYY-MM-DD)
Tech debt: 0 critical, 1 high, 3 medium
```

## Usage
```
/status
```
