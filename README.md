# Claude Skill Files

Personal Claude Code configuration: global instructions, the Steve skill system, agents, commands, and hooks.

## What's here

```
~/.claude/
├── CLAUDE.md              ← Global Claude instructions (Steve system registered here)
├── settings.json          ← Model, hooks (safety, chronicle, graph refresh)
├── skills/                ← Skill library (auto-invoked or slash-command triggered)
├── commands/              ← Slash commands (/ship, /review, /setup-machine, etc.)
├── agents/                ← Named subagents (reviewer, researcher)
├── hooks/                 ← Pre-tool safety hook
├── tools/                 ← Chronicle (SQLite session history) indexer + query
└── NEW_MACHINE.md         ← Full setup for another PC
```

## Steve skill system

See [STEVE_README.md](STEVE_README.md) for the full overview of the Steve orchestration system, all available commands, and setup instructions for new projects.

## Setup on a new machine

See **[NEW_MACHINE.md](NEW_MACHINE.md)**: tools, cloning into an existing `~/.claude`, rebuilding the chronicle DB, and copying the things that can't live in a public repo (memory, `.env`, signing keys). Once the repo is in place, `/setup-machine` checks every step.

Then run `/init-steve` in any project to onboard it.
