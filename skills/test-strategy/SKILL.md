---
name: test-strategy
description: "Decides and runs the right test depth for the task size. Creates tests for new logic on medium/large tasks."
---

# Test Strategy

Invoked by orchestrator after code is written. Depth scales with task size.

## Load first

On first use in a new repo, load `testing-philosophy` skill to set the right foundation before building anything.

## Depth by size

**Small** — lint + typecheck only. One line: "Small change — skipping test run."
```powershell
npx tsc --noEmit
npx eslint src --max-warnings 0
```

**Medium** — run existing suite. Create tests for any new logic lacking coverage.
```powershell
npx vitest run
```

**Large** — full suite + build verification + `npm audit`.
```powershell
npx vitest run
npm run build
npm audit --audit-level=high
```

## Creating tests

When new logic has no coverage on a medium/large task:
1. Detect framework from `package.json` (Vitest preferred, Jest fallback).
2. Write test file alongside the module (`*.test.ts` or `*.spec.ts`).
3. Test pure functions directly; test IPC handlers via Vitest (not Playwright).
4. Test the contract (input → output), not the implementation.

## Never

- Skip tests on medium/large tasks without saying so explicitly.
- Write tests that mock the DB — use in-memory SQLite instead.
- Write Playwright tests for things Vitest can cover.
