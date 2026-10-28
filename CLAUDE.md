# graphify
- **graphify** (`~/.claude/skills/graphify/SKILL.md`) - any input to knowledge graph. Trigger: `/graphify`
When the user types `/graphify`, invoke the Skill tool with `skill: "graphify"` before doing anything else.

# commit
- **commit** (`~/.claude/skills/commit/SKILL.md`) - pre-commit safety checks (large files, deleted assets, cache dirs, .gitignore), then stage, commit, push. Trigger: `/commit`
When the user types `/commit`, invoke the Skill tool with `skill: "commit"` before doing anything else.

## Graph first — MANDATORY

**If `graphify-out/graph.json` exists in the project, query it BEFORE reaching for grep/glob to answer any relationship question.** Not optional, not "if convenient."

A relationship question is anything of the form: what calls X · what does X depend on · where is X used · which files own concern Y · what breaks if I change X · which modules are central/highest-risk · what handles type or enum Z.

Use the installed `graphify` CLI, not a raw JSON dump — it ranks and truncates to a token budget server-side, so the answer landing in context is already trimmed instead of paying for the whole `graphify-out/graph.json`:
```bash
graphify query "<question>" --budget 1500      # BFS, ranked + truncated to budget
graphify query "<question>" --dfs              # DFS — trace a specific chain/path
graphify path "NodeA" "NodeB"                  # shortest path between two concepts
graphify explain "Symbol"                      # plain-language node + neighbors
graphify affected "X" --depth 2                # reverse traversal — "what breaks if I change X"
```
Only fall back to a raw `node -e require('./graphify-out/graph.json')` read for something none of the above cover (e.g. computing raw degree across all links to rank god nodes).

**Why this is a hard rule:** a chain of greps to map relationships costs several tool calls and far more tokens than one graph query, and it is exactly the "re-deriving from scratch" that `system-token-economy` exists to prevent. The graph is the external memory — use it.

**Code drift is auto-handled:** a SessionStart hook runs `graphify update .` (AST-only, async, ~25s) in any repo with `graphify-out/graph.json`, so code nodes are fresh shortly after session start. Doc drift still needs `/graphify --update`.

**Keeping it fresh, cheaply:** `graphify check-update <path>` is a no-LLM, cron-safe check for whether a semantic re-extraction is pending — run this before trusting a possibly-stale graph, instead of forcing a full rebuild every session. If it flags real drift: `graphify update <path>` re-extracts code (AST only, no LLM cost, safe to run often); add `--force` after refactors that renamed/deleted files (overwrites even if the rebuild has fewer nodes). Doc/paper changes still need the LLM-driven `graph-maintenance` skill (`/graphify --update`), since those require semantic re-extraction, not just AST.

**Staleness is not an excuse to skip it.** Check `built_at_commit` / file mtime against `git log -1`. If it is behind, still query it first, then verify anything load-bearing with a targeted grep, and say plainly that the graph was stale. If it is badly stale, run `graphify check-update` and escalate to `graph-maintenance` if it confirms drift — do not silently fall back to grep-only for the rest of the session.

**Content questions route through the graph too, not straight to Grep.** Every graph node carries `source_file` + `source_location` (an exact line). For "what's the signature of X" / "where is X defined" / "show me X": `graphify explain "X"` (or `query`) first to get file+line, then `Read(file, offset=<line>, limit=~20)` — a directed read, not a search. This resolves almost every content question, because almost everything you'd ask about is a named symbol and therefore a node.

Reach for Grep only when the graph genuinely can't answer: the target isn't a named entity at all (a literal string, a comment, a config value not worth extracting as a node), or the graph is confirmed stale and missing something that should be there. Grep-as-first-resort is the failure mode this section exists to prevent.

## Chronicle — cross-project session history

`~/.claude/chronicle.db` is a SQLite index over every session transcript on this machine (`~/.claude/projects/*/*.jsonl`), built by `~/.claude/tools/chronicle_index.py`. It answers "what did we do in project X" / "when did we touch file Y" / "what was decided last time" — raw ground-truth history, distinct from the curated auto-memory (which is distilled) and from `graphify` (which is code structure, not conversation history).

- Query read-only: `python ~/.claude/tools/chronicle_query.py "SELECT ... FROM sessions|turns|session_files ..."`. Filter `sessions`/`turns` by `cwd` to scope to one project, order by `started_at`/`timestamp` for recency.
- Re-run `python ~/.claude/tools/chronicle_index.py` to pick up new sessions — it's incremental (tracks a per-file line offset), so re-running costs almost nothing once already up to date.
- Treat it as history *beneath* the curated files: check auto-memory and this CLAUDE.md first, fall back to chronicle only when you need "what actually happened," not "what's the current rule."

## Lookup ladder

Climb down only as far as needed, cheapest first:

1. **Already-loaded context** — auto-memory (`MEMORY.md` + typed files) and this CLAUDE.md are preloaded every session at zero marginal cost. Check what you already have before spending a tool call.
2. **`graphify`** — code structure and relationships (see "Graph first" above). Cheap, ranked, token-budgeted.
3. **`chronicle.db`** — raw cross-project session history (see "Chronicle" above). Cheap SQL query.
4. **Grep/Read** — last resort: literal strings, content not modeled as a graph node, or confirming/patching a stale graph or chronicle.

Don't skip a rung because the one below feels faster to reach for out of habit — steps 1–3 are all cheaper than step 4.

## Shell tool choice on Windows

Default to the **PowerShell** tool over Bash for anything touching Windows paths, environment variables, or native `.exe` tools — `graphify` and `commit` are both authored entirely in PowerShell, zero bash, so that's the shell this environment is actually built around. Bash (git-bash) is fine for portable POSIX-idiomatic one-liners, but mixing in Windows paths there is a real cost, not a style preference: `C:\...` vs `/c/...` translation, BOM surprises reading files Windows tools wrote, and the Windows Store `python` app-execution-alias stub silently intercepting bare `python` calls even when the real interpreter is on PATH (use `py` or an absolute path instead). If a Bash command involving Windows paths or executables fails, don't retry variations in Bash — switch to PowerShell.

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
- **Two-strike rule** (below) — passive; applies to every tool call, not just formal sub-skill invocations

## User commands (type `/command`)

- `/commit` — pre-commit checks + stage + commit + push (quick path)
- `/ship` — code-review + test + commit-sync (gate path)
- `/review` — review current diff or a PR
- `/test` — run test suite at auto-detected depth
- `/autotest` — generate + run full automated test suite
- `/sdd` — interview → Software Design Document
- `/status` — project health summary (`--page` publishes it as a private dashboard)
- `/setup-machine` — bring another PC up to working Steve state (checklist in `~/.claude/NEW_MACHINE.md`: tools, chronicle DB, memory copy, per-project secrets)
- `/bakeoff` — build 2–3 competing approaches in worktrees, independent judge picks (manual, expensive)
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

## Two-strike rule (canonical — other files point here, don't restate)

Applies at **every** granularity — a single stuck tool call, a sub-skill, or a whole task, not just formal task/sub-skill boundaries: after 2 distinct failed attempts at the same goal, STOP. Summarize what was tried, what each attempt revealed, and list 2–3 ranked next options. Wait for direction. Do not quietly try a 3rd variation.

"Distinct" means a genuinely different approach, not the same command run again. Two different quoting strategies for one shell command, two different fixes for one bug, two different flags for one CLI call — those each count as an attempt. Retrying the identical thing hoping for a different result doesn't reset the count.
