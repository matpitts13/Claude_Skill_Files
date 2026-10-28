# /setup-machine

Bring a new (or long-unused) PC up to working Steve state. The full checklist is `~/.claude/NEW_MACHINE.md`. Read it first.

## Usage
```
/setup-machine
```

## What this does

Run each check from `NEW_MACHINE.md` in order, fixing what can be fixed and listing what needs the user:

1. **Tools**: `git`, `gh auth status`, `node -v`, `py --version`, `graphify --help`. Install graphify with `py -m pip install --user graphifyy==0.8.16` if missing; anything else missing → tell the user how to install it.
2. **Steve repo**: `~/.claude` is a git repo on `main` tracking `origin`; `git pull`. If there are local changes, show them before pulling.
3. **Hooks**: confirm `settings.json` has the PreToolUse safety hook and both SessionStart hooks; feed the safety hook a sample `git reset --hard` payload and confirm it answers `ask`.
4. **Chronicle**: run `py ~/.claude/tools/chronicle_index.py`, then report session count via `chronicle_query.py "SELECT COUNT(*) FROM sessions"`.
5. **Memory**: for the current project, check `~/.claude/projects/<encoded-path>/memory/MEMORY.md` exists. If not, tell the user to copy it from the other PC (NEW_MACHINE.md §4). Never create placeholder memory.
6. **Project**: for the current repo, check `node_modules`, `graphify-out/graph.json`, and `.env` (if `.env.example` exists). Report what's missing with the fix from NEW_MACHINE.md §5.

## Output

```
## Machine setup: <hostname>
Tools:     OK | missing: <list>
Steve:     main @ <sha>, up to date
Hooks:     safety OK, chronicle OK, graph OK
Chronicle: <n> sessions indexed
Memory:    present | MISSING (copy from other PC)
Project:   deps OK, graph MISSING, .env OK
User to do: <numbered list, or "nothing">
```

## Never

- Copy, print or commit secrets (`.env` values, `.pem` contents, credentials).
- Commit `projects/`, `chronicle.db`, or anything else gitignored.
