# /ship

Gate + commit + push for the current task. Orchestrated path.

## What this does

Runs in order:
1. `code-review` skill — reviews the current diff
2. If code-review passes: `test-strategy` skill at medium depth
3. If tests pass: `commit-sync` skill — stages, commits with conventional message, syncs, pushes

## Usage
```
/ship
/ship "optional message override"
```

## When to use

After completing a feature or fix and wanting to merge-ready it. This is the full gate — prefer `/commit` for quick saves during development.

## Stops when

- Code review finds a FAIL item → fix it, then re-run `/ship`
- Tests fail → fix them, then re-run `/ship`
- Sync conflicts → reports the conflict, stops for manual resolution
