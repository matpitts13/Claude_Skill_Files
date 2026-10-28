# Steve — AI Coding System

Steve is a layered system of Claude Code skills, commands, and agents that turns Claude into a structured, senior-level engineering partner.

## What it is

A collection of `~/.claude/skills/`, `~/.claude/commands/`, and `~/.claude/agents/` files that wire up structured workflows for common engineering tasks:

- **Orchestration**: classifies task size and runs the right sub-skills
- **Quality gates**: code review, testing, security, and dependency checks before commits
- **Senior patterns**: design gates, ADRs, tech debt tracking, estimation, retrospectives
- **Language rules**: per-language coding conventions loaded on demand
- **Testing**: philosophy-first test generation with flaky detection and parking
- **Sessions**: checkpoint files that survive context compaction

## Getting started

In any new project:
```
/init-steve
```

This detects the stack, loads the relevant language rules, checks for existing tests, and prints a project status.

## Key commands

| Command | What it does |
|---------|-------------|
| `/commit` | Safe commit: pre-checks, stage, commit, push |
| `/ship` | Gated commit: code-review + test + commit-sync |
| `/review` | Review current diff or a PR number |
| `/test` | Run tests at auto-detected depth |
| `/autotest` | Generate + run full automated test suite |
| `/sdd` | Interview → Software Design Document |
| `/status` | Project health: git, types, tests, debt |
| `/release` | Full release checklist |
| `/ci-setup` | Set up GitHub Actions CI |
| `/insight-repo` | Save a note to project memory |
| `/graphify` | Build a knowledge graph of the codebase |

## Architecture

```
~/.claude/
├── CLAUDE.md              ← Global instructions (Steve sections appended)
├── settings.json          ← Permissions
├── skills/
│   ├── orchestrator/      ← Task routing brain
│   ├── code-review/       ← Pre-commit gate
│   ├── test-strategy/     ← Test depth selector
│   ├── commit-sync/       ← Gated commit path
│   ├── debug-protocol/    ← Structured debugging
│   ├── language-rules/    ← Per-language conventions (+ 9 sub-files)
│   ├── stack-detect/      ← Tech stack detection
│   ├── graph-maintenance/ ← Keep knowledge graph in sync
│   ├── system-*/          ← Passive: token-economy, safety, session
│   ├── senior-*/          ← Senior patterns: ADR, gates, debt, security, etc.
│   ├── sdd/               ← Software Design Document (+ interview template)
│   ├── autotest/          ← Test generation (+ philosophy + harness)
│   ├── testing-philosophy/ ← Foundation doc for testing
│   ├── release/           ← Release checklist
│   └── ci/                ← CI/CD setup
├── commands/              ← Slash commands (/ship, /review, etc.)
├── agents/
│   ├── reviewer.md        ← Independent code review subagent
│   └── researcher.md      ← Codebase exploration subagent
└── hooks/
    └── block-dangerous.ps1 ← Pre-tool safety hook (wired in settings.json)
```

## Block-dangerous hook

`hooks/block-dangerous.ps1` runs before every Bash/PowerShell call (wired in `settings.json` under `hooks.PreToolUse`). It reads the tool call as JSON from stdin, and on a dangerous pattern (force-push, hard reset, rebase, `git clean -f`, DROP TABLE, DELETE without WHERE, `--no-verify`, staging `.env`/keys/`chronicle.db`) it returns `permissionDecision: "ask"`.

There is no override variable: you approve or reject that one command in the permission prompt, even in auto mode. Edit `$BLOCKED` in the script to change patterns.

## Skill registration

Skills in `~/.claude/skills/<name>/SKILL.md` are auto-loaded by Claude Code. The skill list in `CLAUDE.md` tells Claude when to invoke each one.

Commands in `~/.claude/commands/<name>.md` are available as `/<name>` in any session.

Agents in `~/.claude/agents/<name>.md` are available to the `Agent` tool by name.
