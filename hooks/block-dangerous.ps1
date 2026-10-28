# block-dangerous.ps1
# PreToolUse hook for Bash/PowerShell. Claude Code pipes the tool call as JSON on stdin.
# A match does not hard-block: it returns permissionDecision "ask", so the user approves
# or rejects that one command (this works in auto mode too). No match -> exit 0, no opinion.

$ErrorActionPreference = 'Stop'
try {
    $payload = [Console]::In.ReadToEnd() | ConvertFrom-Json
} catch {
    exit 0
}

$Command = [string]$payload.tool_input.command
if (-not $Command) { exit 0 }

# Each entry: @{ Pattern = '...'; Reason = '...' }
$BLOCKED = @(
    @{ Pattern = 'git push (.* )?(--force|-f)(?!-with-lease)\b'; Reason = 'Force-push can overwrite upstream history. Prefer --force-with-lease.' }
    @{ Pattern = 'git reset --hard';                Reason = 'Discards all local changes irreversibly.' }
    @{ Pattern = 'git clean -[a-z]*f';              Reason = 'Deletes untracked files irreversibly.' }
    @{ Pattern = 'git rebase(?!.*--abort)';         Reason = 'Rebase rewrites history.' }
    @{ Pattern = 'rm -rf /(\s|$)';                  Reason = 'Root filesystem delete.' }
    @{ Pattern = 'Remove-Item.*-Recurse.*-Force.*C:\\Windows'; Reason = 'Windows system directory delete.' }
    @{ Pattern = 'DROP TABLE';                      Reason = 'Drops a table irreversibly.' }
    @{ Pattern = 'DELETE FROM \w+ *(;|$|")';        Reason = 'DELETE without WHERE clause deletes all rows.' }
    @{ Pattern = '--no-verify';                     Reason = 'Bypasses git hooks. Fix the hook failure instead.' }
)

$reason = $null
foreach ($entry in $BLOCKED) {
    if ($Command -match $entry.Pattern) { $reason = "Steve safety: $($entry.Reason)"; break }
}

# Sensitive file staging check
if (-not $reason -and $Command -match 'git add') {
    $sensitiveFiles = @('.env', 'credentials', '.pem', '.key', 'id_rsa', 'secrets', 'chronicle.db')
    foreach ($f in $sensitiveFiles) {
        if ($Command -match [regex]::Escape($f)) { $reason = "Steve safety: staging a file matching '$f' - likely sensitive."; break }
    }
}

if ($reason) {
    @{
        hookSpecificOutput = @{
            hookEventName            = 'PreToolUse'
            permissionDecision       = 'ask'
            permissionDecisionReason = $reason
        }
    } | ConvertTo-Json -Depth 4 -Compress
}
exit 0
