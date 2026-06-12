# Claude Skill Files

Personal Claude Code configuration: global instructions, the Steve skill system, agents, commands, and hooks.

## What's here

```
~/.claude/
├── CLAUDE.md              ← Global Claude instructions (Steve system registered here)
├── settings.json          ← Permissions
├── skills/                ← Skill library (auto-invoked or slash-command triggered)
├── commands/              ← Slash commands (/ship, /review, /commit, etc.)
├── agents/                ← Named subagents (reviewer, researcher)
└── hooks/                 ← Pre-tool safety hooks
```

## Steve skill system

See [STEVE_README.md](STEVE_README.md) for the full overview of the Steve orchestration system, all available commands, and setup instructions for new projects.

## Setup on a new machine

1. Clone this repo to `~/.claude`:
   ```
   git clone https://github.com/matpitts13/Claude_Skill_Files.git ~/.claude
   ```
2. Open Claude Code — CLAUDE.md is picked up automatically.
3. Run `/init-steve` in any project to onboard it.
