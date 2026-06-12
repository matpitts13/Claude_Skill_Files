---
name: commit
description: "Pre-commit safety routine: flags large files, deleted assets, and cache directories; updates .gitignore if needed; then stages, commits with a descriptive message, and pushes."
trigger: /commit
---

# /commit

Run the full pre-commit safety routine, then commit and push.

## Usage

```
/commit                        # fetch, check, commit, sync, and push
/commit "your message here"    # same with a specific message
/commit --no-push              # check and commit only, skip sync+push
/commit --no-sync              # commit and push without pulling remote changes
/commit --dry-run              # show what would be flagged/staged without committing
```

## What You Must Do When Invoked

Follow these steps in order. Do not skip steps.

### Step 0 — Fetch remote state

Run `git fetch origin` to update remote tracking refs. This is always safe and costs nothing.
Then check divergence:

```powershell
$behind = (git rev-list HEAD..@{u} --count 2>$null).Trim()
$ahead  = (git rev-list @{u}..HEAD --count 2>$null).Trim()
if ($behind -gt 0) { Write-Host "Behind remote by $behind commit(s). Will sync after committing." }
```

If `--no-sync` was given, skip the divergence note and skip Step 7b entirely.

### Step 1 — Check for large files

Run the following to find files over 1 MB that are not already gitignored:

```powershell
git ls-files --others --exclude-standard | ForEach-Object {
    $size = (Get-Item $_ -ErrorAction SilentlyContinue).Length
    if ($size -gt 1MB) { "$_ ($([math]::Round($size/1MB,1)) MB)" }
}
# Also check tracked files
git ls-files | ForEach-Object {
    $size = (Get-Item $_ -ErrorAction SilentlyContinue).Length
    if ($size -gt 1MB) { "$_ ($([math]::Round($size/1MB,1)) MB)" }
}
```

If any large files are found, list them and ask the user whether to add them to `.gitignore` or include them. Do not proceed past this step until resolved.

If `--dry-run` was given, print the list and stop here — do not commit.

### Step 2 — Check for deleted assets

```powershell
git status --short | Where-Object { $_ -match '^\s*D\s+.*\.(png|jpg|jpeg|gif|svg|ico|webp|pdf|woff|woff2|ttf|eot)' }
```

If any deleted asset files are found, list them and warn the user. Ask: are these deletions intentional? If the user is unsure, show a `git diff --name-only` to help them decide. Only continue with confirmation.

### Step 3 — Check for cache and build directories

Check for common cache/build directories that are untracked and should likely be gitignored:

```powershell
$cacheDirs = @(
    'node_modules', '.next', 'dist', 'build', 'out', '.cache',
    '__pycache__', '.pytest_cache', '.mypy_cache', 'graphify-out/cache',
    '.turbo', 'coverage', '.nyc_output', 'tmp', 'temp'
)
$found = @()
foreach ($dir in $cacheDirs) {
    if (Test-Path $dir) {
        $status = git ls-files --error-unmatch $dir 2>$null
        if ($LASTEXITCODE -ne 0) {
            # Not tracked — check if it's gitignored
            $ignored = git check-ignore -q $dir 2>$null
            if ($LASTEXITCODE -ne 0) {
                $found += $dir
            }
        }
    }
}
if ($found.Count -gt 0) { $found -join "`n" }
```

For each found directory, recommend adding it to `.gitignore`. If the user agrees (or if it's an obvious cache like `node_modules`, `__pycache__`, etc.), add it automatically and tell the user what you added.

### Step 4 — Update .gitignore if needed

If you identified files or directories in Steps 1–3 that should be ignored, append them to `.gitignore` now. Show the user exactly what lines you are adding before writing.

Use this pattern to append only entries that don't already exist:

```powershell
$gitignorePath = '.gitignore'
$existing = if (Test-Path $gitignorePath) { Get-Content $gitignorePath } else { @() }
$toAdd = @('ENTRY1', 'ENTRY2')  # replace with actual entries
$new = $toAdd | Where-Object { $_ -notin $existing }
if ($new) { Add-Content $gitignorePath ($new -join "`n") }
```

### Step 5 — Show staging summary

```powershell
git status --short
```

Print a clean summary of what will be staged. If the working tree is clean (nothing to commit), tell the user and stop — do not create an empty commit.

If `--dry-run` was given, stop here.

### Step 6 — Stage and commit

If the user did not provide a commit message, write one yourself: a concise one-liner summarizing the changes (feature, fix, refactor, docs, etc.) based on what `git diff --staged` and `git status` show. Look at `git log --oneline -5` to match the project's existing commit style.

Stage the appropriate files — prefer specific paths over `git add -A` when some files should be excluded. Then commit:

```powershell
git add <specific files or .>
git commit -m "$(cat <<'EOF'
<your message here>
EOF
)"
```

On Windows PowerShell, use a here-string:

```powershell
$msg = @'
<your message here>
'@
git commit -m $msg
```

If the commit fails due to a pre-commit hook, fix the underlying issue — do not use `--no-verify`.

### Step 7 — Sync then push

Unless `--no-push` was given:

**Step 7a — Sync with remote** (skip if `--no-sync`):

If the remote is ahead, sync before pushing. Try in order — stop at first success:

1. **Fast-forward** (preferred — no new commit, clean):
   ```powershell
   git pull --ff-only
   ```
   If this succeeds, go to Step 7b.

2. **Merge commit** (creates one merge commit, preserves both histories):
   ```powershell
   git pull --no-rebase
   ```
   If this succeeds with no conflicts, go to Step 7b.
   If there are conflicts: `git merge --abort`, then try step 3.

3. **Rebase** (last resort — rewrites history, use only when merge failed):
   ```powershell
   git pull --rebase
   ```
   If this succeeds, go to Step 7b.
   If there are conflicts: `git rebase --abort`. STOP. Print the conflicting files, tell the user to resolve manually, and do not push.

**Step 7b — Push:**
```powershell
git push
```
If the branch has no upstream, push with `-u origin <branch-name>`.

After pushing, confirm success with the commit hash and branch name. End with a one-line summary: what was committed, how it synced (ff / merge / rebase / no sync needed), and where it was pushed.

## Honesty Rules

- Never use `git add -A` or `git add .` if there are files that should remain unstaged.
- Never skip the large-file check.
- Never commit `.env` files, credentials, or secrets — if spotted, block and warn loudly.
- Never use `--no-verify` to bypass hooks.
- Always show the user what you're adding to `.gitignore` before writing it.
