---
name: graph-maintenance
description: "Keeps the graphify knowledge graph in sync with the codebase. Run after large changes or when the graph feels stale."
---

# Graph Maintenance

Invoked by `orchestrator` after large structural changes, or directly when the user reports the graph is out of date.

## When to run

- After adding a new major module or service
- After a large refactor that moved/renamed many files
- After merging a branch with significant new code
- When a `/graphify query` returns clearly stale or missing results

## Steps

1. **Check if graph exists**: `ls graphify-out/graph.json`
   - If missing: run `/graphify` (full pipeline).
   - If present: run `/graphify --update` (incremental, cheaper).

2. **Incremental update** (`--update` mode):
   - Identifies new/changed files since `graphify-out/graph.json` last modified.
   - Re-extracts only those files.
   - Merges new nodes/edges into existing graph.
   - Re-runs community detection.

3. **Verify**: After update, run a sanity query:
   ```
   /graphify query "main entry points and key modules"
   ```
   If the result looks wrong (missing major components), escalate to full rebuild.

4. **Full rebuild trigger conditions**:
   - > 30% of files changed since last full run
   - Community structure looks wrong (too many singletons)
   - User reports missing connections

## Never

- Delete `graphify-out/` manually unless explicitly asked — it contains the cached extraction results that make incremental updates fast.
- Run a full rebuild before trying `--update` first.
