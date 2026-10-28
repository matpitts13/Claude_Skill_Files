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
npm run test
```

**Large** — full suite + build verification + `npm audit`.
```powershell
npm run test
npm run build
npm audit --audit-level=high
```

## Resolving the test command

`npm run test` (not `npx vitest run`) — `npx` can resolve a globally installed Vitest that mismatches the project's pinned version, producing false failures like "Vitest failed to find the runner" even when the suite is green. Always run the project's own `package.json` scripts. If a project has no `test` script, check `package.json` for the actual runner before falling back to `npx`.

## Creating tests

When new logic has no coverage on a medium/large task:
1. Detect framework from `package.json` (Vitest preferred, Jest fallback).
2. Write test file alongside the module (`*.test.ts` or `*.spec.ts`).
3. Test pure functions directly; test IPC handlers via Vitest (not Playwright).
4. Test the contract (input → output), not the implementation.

## On-screen verification (UI changes, medium/large)

Green tests don't prove the user's workflow works. When the task changes anything a user sees or clicks:
1. Launch the app via the `run` skill (Electron: `npm run dev`).
2. Reproduce the user's actual scenario step by step — the one from the request, not a happy path you chose.
3. Screenshot the result and look at it before reporting done. Use Playwright's Electron driver if the project has one; otherwise the `computer-use` skill.
4. If the app can't be launched in this session, say so explicitly — never imply it was verified.

## Never

- Skip tests on medium/large tasks without saying so explicitly.
- Report a UI change as working based on tests alone.
- Write tests that mock the DB — use in-memory SQLite instead.
- Write Playwright tests for things Vitest can cover.
