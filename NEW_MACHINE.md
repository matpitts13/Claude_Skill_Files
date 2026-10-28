# New machine setup

Everything needed to run Steve on another Windows PC. Git carries the skill system; this file covers the rest, which **cannot go in this repo because it's public** (memory, transcripts, credentials, secrets).

In Claude Code on the new machine, `/setup-machine` walks through this list and checks each step.

---

## 1. Install tools

| Tool | Install | Check |
|---|---|---|
| Git | git-scm.com (includes Git Bash, which the hooks use) | `git --version` |
| GitHub CLI | `winget install GitHub.cli`, then `gh auth login` | `gh auth status` |
| Node.js LTS | nodejs.org | `node -v` |
| Python + `py` launcher | python.org (tick "py launcher") | `py --version` |
| graphify | `py -m pip install --user graphifyy==0.8.16` | `graphify --help` |
| VS Code + Claude Code extension | marketplace | — |

If `graphify` isn't found, add Python's user Scripts folder to PATH (`py -m site --user-base`, then `\Python3xx\Scripts`). Use `py`, never bare `python` (the Windows Store alias intercepts it).

## 2. Clone Steve into `~/.claude`

If Claude Code has already run once, `~/.claude` exists and `git clone` will refuse. In PowerShell:

```powershell
cd $env:USERPROFILE\.claude
git init
git remote add origin https://github.com/matpitts13/Claude_Skill_Files.git
git fetch origin
git checkout -f -B main origin/main
```

Fresh machine (no `~/.claude` yet): `git clone https://github.com/matpitts13/Claude_Skill_Files.git $env:USERPROFILE\.claude`.

Then sign in: open Claude Code and run `/login`. claude.ai skills and connectors (`skills/synced/`, `plugins/`) come back with your account.

## 3. Chronicle (SQLite session history)

`~/.claude/chronicle.db` is **not** in git: it contains full session transcripts. It's rebuilt from the transcript files:

```powershell
py $env:USERPROFILE\.claude\tools\chronicle_index.py
```

The SessionStart hook already runs this on every session, so it builds itself the first time you open Claude Code. It's incremental, so running it again costs nothing.

**It only indexes transcripts on this machine.** To get the old PC's history too, copy the transcripts across (step 4) and run the indexer again.

## 4. Memory and transcripts (private, copy by hand)

Both live under `~/.claude/projects/<encoded-project-path>/`:

- `memory/`: the curated auto-memory (`MEMORY.md` plus one file per fact). **This is the one that matters.**
- `*.jsonl`: raw session transcripts (feed chronicle).

Copy the `projects/` folder from the old PC over USB, OneDrive or a **private** repo. Never put it in this repo: it holds personal info (email, postal address, account details).

The folder name is the project's full path with every non-alphanumeric character turned into `-`. For example `C:\Users\mat_o\Documents\Mat\Software_Creation\repos\CKN_SCTRH` becomes `c--Users-mat-o-Documents-Mat-Software-Creation-repos-CKN-SCTRH`. **If the username or repo location differs on the new PC**, open the project once in Claude Code to create its new folder, then move the old `memory/` into it.

## 5. Per-project things git doesn't carry

Clone each repo, run `npm ci`, then:

### All repos with a code graph
- `graphify-out/` is gitignored. Either copy the folder from the old PC (free) or run `/graphify` (costs LLM tokens). After that, the SessionStart hook keeps the code side fresh automatically.

### CKN_SCTRH (Ravenburst app)
- `.env`: needs `CLOUD_MS_CLIENT_ID`, `CLOUD_GOOGLE_CLIENT_ID`, `CLOUD_GOOGLE_CLIENT_SECRET`. Copy it from the old PC, or get the values from the Entra ID and Google Cloud consoles. Empty values are fine for normal dev; cloud storage just reads as "not configured".
- **License signing private key (`.pem`)**: kept outside the repo on purpose, and `scripts/generate-license.js` finds it through the `RAVENBURST_LICENSE_KEY_FILE` env var. Only needed on a machine that issues activation codes. Copy it securely and set the env var. **Losing it means a new key pair plus an app update before more codes can be issued**, so keep an offline backup.
- CI release secrets live in GitHub Actions, not on any machine.

### RAVENBURTST_WEBSITE and ravenburst-admin
- `npx wrangler login` (no global wrangler). Worker secrets live in Cloudflare, not locally.
- ravenburst-admin can use `CLOUDFLARE_API_TOKEN` instead of `wrangler login`.

## 6. Keeping both machines in sync

- `git pull` in `~/.claude` before working; commit and push Steve changes when done. Scan the diff for personal info first (public repo).
- Memory doesn't sync on its own. After a big session on one PC, copy the changed `memory/` files across.
- `chronicle.db` stays per-machine; never copy it over the other machine's.
