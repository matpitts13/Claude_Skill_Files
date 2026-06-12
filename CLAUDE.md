# graphify
- **graphify** (`~/.claude/skills/graphify/SKILL.md`) - any input to knowledge graph. Trigger: `/graphify`
When the user types `/graphify`, invoke the Skill tool with `skill: "graphify"` before doing anything else.

# commit
- **commit** (`~/.claude/skills/commit/SKILL.md`) - pre-commit safety checks (large files, deleted assets, cache dirs, .gitignore), then stage, commit, push. Trigger: `/commit`
When the user types `/commit`, invoke the Skill tool with `skill: "commit"` before doing anything else.

## Response Style

Role: Ultra-concise, efficient coding assistant. Minimize token usage.

1. No pleasantries ("Sure, I can help", "Here is the code", etc.)
2. Never repeat user code unless strictly modifying it.
3. Show only modified blocks or diffs — never full files.
4. Keep explanations concise; use bullet points. More than two sentences only when genuinely necessary.
5. If code is self-explanatory, output ONLY the code block.

## Code Generation

When the user provides complete code, generate the full file directly rather than giving paste/deploy instructions.

## Git / Commits

Before committing, check for large files, deleted assets, and cache directories, and ensure .gitignore is set up appropriately.

---

# Steve — Skill System

## Auto-invoked skills (no trigger needed)

These skills activate automatically when conditions are met:

- **orchestrator** — for any task spanning >1 file or >1 concern, invoke the Skill tool with `skill: "orchestrator"` before writing any code. Also manually invocable via `/orchestrate`.
- **system-safety** — passive; blocks dangerous operations without being invoked
- **system-token-economy** — passive; governs reading/writing discipline in all sessions
- **system-session** — passive; checkpoint patterns for long tasks

## User commands (type `/command`)

- `/commit` — pre-commit checks + stage + commit + push (quick path)
- `/ship` — code-review + test + commit-sync (gate path)
- `/review` — review current diff or a PR
- `/test` — run test suite at auto-detected depth
- `/autotest` — generate + run full automated test suite
- `/sdd` — interview → Software Design Document
- `/status` — project health summary
- `/release` — full release checklist
- `/ci-setup` — set up or review CI pipeline
- `/insight-repo` — save a note/decision to project memory
- `/init-steve` — first-run setup for a new project
- `/graphify` — build knowledge graph
- `/commit` — safe commit with pre-checks (already registered above)
- `/orchestrate` — manually trigger orchestrator (classify, plan, run gates, commit-sync)

## Skill reference

All skills live in `~/.claude/skills/<name>/SKILL.md`. Key skills:

| Skill | Invoked by |
|-------|-----------|
| `orchestrator` | auto (multi-file tasks) |
| `code-review` | orchestrator, `/review`, `/ship` |
| `test-strategy` | orchestrator, `/test` |
| `commit-sync` | orchestrator, `/ship` |
| `debug-protocol` | orchestrator (bug fixes), manually |
| `language-rules` | orchestrator (loads for detected stack) |
| `stack-detect` | language-rules, `/init-steve` |
| `sdd` | `/sdd`, orchestrator (large tasks) |
| `autotest` | `/autotest` |
| `testing-philosophy` | autotest (first run in repo) |
| `senior-design-gate` | orchestrator (large tasks) |
| `senior-estimation` | orchestrator (large tasks) |
| `senior-adr` | orchestrator (after large tasks) |
| `senior-security` | orchestrator (IPC/auth/file I/O tasks) |
| `senior-dependency-gate` | when new npm package proposed |
| `senior-tech-debt` | deferred fixes, `/autotest` failures |
| `senior-retrospective` | end of sprint |
| `senior-archaeology` | before deleting unfamiliar code |
| `senior-error-observability` | orchestrator (large tasks) |
| `graph-maintenance` | after large refactors |
| `release` | `/release` |
| `ci` | `/ci-setup` |

## Two-strike rule

For any task or sub-skill: after 2 distinct failed attempts at the same problem, STOP. Summarize what was tried, what each attempt revealed, and list 2–3 ranked next options. Wait for direction. Do not loop indefinitely.
