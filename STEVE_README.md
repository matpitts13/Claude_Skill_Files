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
    └── block-dangerous.ps1 ← Pre-tool hook (manual wire-up needed)
```

## Block-dangerous hook

The `hooks/block-dangerous.ps1` script blocks dangerous patterns (force-push, hard reset, DROP TABLE without WHERE, etc.) but must be wired up manually in `settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "powershell -NonInteractive -File C:\\Users\\mat_o\\.claude\\hooks\\block-dangerous.ps1 -ToolName Bash -ToolInput $INPUT"
          }
        ]
      }
    ]
  }
}
```

Check Claude Code documentation for the exact `$INPUT` variable syntax before enabling.

### Override (for legitimate force-push, reset, etc.)

The hook is overridable via an environment variable. **Claude must ask for explicit user permission before setting this.**

```powershell
$env:STEVE_ALLOW_DANGEROUS = "1"   # allow for this shell session
# ... do the thing ...
$env:STEVE_ALLOW_DANGEROUS = ""    # clear immediately after
```

The override applies only to the current shell session — it does not persist across restarts. Claude will not set it without the user explicitly saying to allow the operation.

## Skill registration

Skills in `~/.claude/skills/<name>/SKILL.md` are auto-loaded by Claude Code. The skill list in `CLAUDE.md` tells Claude when to invoke each one.

Commands in `~/.claude/commands/<name>.md` are available as `/<name>` in any session.

Agents in `~/.claude/agents/<name>.md` are available to the `Agent` tool by name.
