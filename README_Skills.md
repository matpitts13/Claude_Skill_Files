# README: Skills, Commands & Agents

Complete reference for all Steve skills, commands, and agents in `~/.claude/`.

---

## Commands (type `/command` in any session)

| Command | Description | Skill it invokes |
|---------|-------------|-----------------|
| `/commit` | Pre-commit safety checks + stage + commit + push | `commit` |
| `/ship` | code-review → test → commit-sync (full gate) | `code-review`, `test-strategy`, `commit-sync` |
| `/review` | Review current diff or a PR. `ultra` = deep cloud review | `code-review` |
| `/test [small\|medium\|large]` | Run test suite at specified or auto-detected depth | `test-strategy` |
| `/autotest` | Generate + run Vitest + Playwright tests, park flaky failures | `autotest`, `testing-philosophy` |
| `/sdd` | Interview → write/update `docs/SDD.md` | `sdd` |
| `/status` | Git, TypeScript, tests, tech debt summary | — |
| `/release [patch\|minor\|major]` | Quality gates + version bump + tag + push | `release` |
| `/ci-setup` | Create or review `.github/workflows/ci.yml` | `ci` |
| `/insight-repo "note"` | Save note/decision to project memory | — |
| `/init-steve` | First-run setup: detect stack, check harness, graphify | `stack-detect`, `autotest/harness`, `graphify` |
| `/graphify` | Build/update knowledge graph of the codebase | `graphify` |

---

## Skills Reference

### Core workflow skills

#### `orchestrator`
**Trigger:** auto-activates on any multi-file or multi-concern task  
**What it does:** Classifies task size (small/medium/large), gates by size, invokes sub-skills in order, creates backup branch before large work. Two-strike rule: after 2 failed attempts → stop + summarize.

#### `code-review`
**Trigger:** orchestrator (medium/large), `/review`, `/ship`  
**What it does:** Reviews diff for correctness, security, contracts, error handling, and new packages. Delegates to `reviewer` subagent for medium/large diffs. Output: PASS/FAIL bullet list.

#### `test-strategy`
**Trigger:** orchestrator, `/test`  
**What it does:** Runs lint+typecheck (small), Vitest (medium), or full suite+build+audit (large). Creates tests for new logic on medium/large tasks.

#### `commit-sync`
**Trigger:** orchestrator (after code-review passes), `/ship`  
**What it does:** Stages specific files, writes a conventional-commit message, commits, then syncs with ff-only → merge → rebase-as-last-resort.

#### `debug-protocol`
**Trigger:** orchestrator (bug-fix tasks), manually  
**What it does:** Reproduce → isolate → hypothesize → fix → verify. States hypothesis before touching code. Two-strike rule applies.

---

### Language skills

#### `language-rules`
**Trigger:** orchestrator (medium/large), manually  
**What it does:** Routes to per-language sub-files based on detected stack.

**Sub-files:**

| File | Stack |
|------|-------|
| `typescript.md` | TypeScript / JavaScript |
| `react.md` | React |
| `electron.md` | Electron (IPC, security, packaging) |
| `node-npm.md` | Node.js scripts and npm |
| `html-css.md` | HTML / CSS |
| `liquid-shopify.md` | Shopify Liquid themes |
| `csharp.md` | C# |
| `cpp.md` | C++ (C++17+) |
| `sqlite.md` | SQLite (schema, migrations, queries) |

#### `stack-detect`
**Trigger:** `language-rules`, `/init-steve`  
**What it does:** Reads `package.json` and file extensions to return a list of active language tags.

---

### System skills (passive — always active)

#### `system-safety`
Never force-push, hard-reset, or drop tables without explicit confirmation. Blocks staging `.env` or credentials. Creates backup branch before large work.

#### `system-token-economy`
Read selectively (grep first, read less). Don't repeat code in responses. Compress subagent results. No re-reading files already read.

#### `system-session`
`TEST_FIX_STATE.md` for checkpoint files during long tasks. `TECH_DEBT.md` for parked items. Patterns survive context compaction.

---

### Senior skills

#### `senior-adr`
**Trigger:** orchestrator (large tasks)  
**What it does:** Writes `docs/adr/NNNN-title.md` with context, options, decision, and consequences.

#### `senior-design-gate`
**Trigger:** orchestrator (large tasks, pre-code)  
**What it does:** 7-point checklist: scope clarity, data model impact, IPC contracts, deps, existing patterns, test surface, rollback.

#### `senior-dependency-gate`
**Trigger:** when a new npm package is proposed  
**What it does:** Checks necessity, package health, security, bundle size, and license. Returns APPROVE/BLOCK.

#### `senior-tech-debt`
**Trigger:** deferred fixes, `/autotest` failures, sprint end  
**What it does:** Appends to `TECH_DEBT.md` with severity triage (Critical/High/Medium/Low + PARKed tests).

#### `senior-archaeology`
**Trigger:** before deleting unfamiliar code  
**What it does:** `git blame` + `git show` + search to find why code exists. Returns a Finding/Origin/Safe-to-remove verdict.

#### `senior-error-observability`
**Trigger:** orchestrator (large tasks)  
**What it does:** Reviews error handling: swallowed exceptions, missing awaits, weak error messages, logging discipline.

#### `senior-security`
**Trigger:** orchestrator (IPC/auth/file tasks), `/security-review`  
**What it does:** Electron security checklist + injection checks + secret leakage + npm audit.

#### `senior-retrospective`
**Trigger:** sprint end  
**What it does:** What was built / went well / was harder / would change / is deferred. Feeds into `TECH_DEBT.md` and memory.

#### `senior-estimation`
**Trigger:** orchestrator (large tasks)  
**What it does:** Breaks task into sub-tasks, classifies XS/S/M/L/XL, flags risks, recommends spike-first for XL items.

---

### Advanced skills

#### `sdd`
**Trigger:** `/sdd`, orchestrator (large tasks)  
**What it does:** Interviews user (one question group at a time), writes `docs/SDD.md`. Waits for confirmation before coding.  
Sub-file: `sdd/interview-template.md`

#### `autotest`
**Trigger:** `/autotest`  
**What it does:** IPC pre-pass (Vitest) → unit tests → Playwright E2E → two-run flaky detection → fix loop → parking to `TECH_DEBT.md` → Testing Health report.  
Sub-files: `autotest/philosophy.md`, `autotest/harness.md`

#### `testing-philosophy`
**Trigger:** `autotest` (first run in repo)  
**What it does:** Foundation doc. Test pyramid, what NOT to test, real deps over mocks, cross-OS filename rules, flaky test policy.

#### `graph-maintenance`
**Trigger:** after large refactors  
**What it does:** `--update` incremental sync of graphify knowledge graph. Full rebuild if > 30% of files changed.

#### `release`
**Trigger:** `/release`  
**What it does:** TypeScript check → tests → audit → build → smoke test → CHANGELOG entry → `npm version` → tag → push.

#### `ci`
**Trigger:** `/ci-setup`  
**What it does:** Creates `.github/workflows/ci.yml` for detected stack (TypeScript + Vitest + optional Playwright).

---

## Agents

#### `reviewer`
Used by `code-review` for medium/large diffs. Reviews with fresh eyes, free of implementation bias. Returns PASS/FAIL with file:line references.

#### `researcher`
Used by `orchestrator` for significant library doc reading or unfamiliar code exploration. Returns compressed summary: finding, evidence, gaps, recommendation. Read-only.

---

## Hooks

#### `hooks/block-dangerous.ps1`
Blocks patterns like `git push --force`, `git reset --hard`, `DROP TABLE`, `--no-verify`, staging `.env` files. Must be manually wired in `settings.json` — see `STEVE_README.md` for the hook config format.
