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

# "git", then any global options such as -C <dir>, then the subcommand.
$Git = '\bgit(?:\s+-[cC]\s+(?:"[^"]*"|''[^'']*''|\S+)|\s+--[\w-]+(?:=\S+)?|\s+-[pP]\b)*\s+'
# Stays within one command: stops at a separator or a new line.
$Rest = '[^;&|\n]*'

# Each entry: @{ Pattern = '...'; Reason = '...' }
$BLOCKED = @(
    @{ Pattern = "${Git}push\b$Rest\s(?:--force(?!-with-lease|-if-includes)\b|-[a-z]*f[a-z]*\b|\+\S)"; Reason = 'Force-push can overwrite upstream history. Prefer --force-with-lease.' }
    @{ Pattern = "${Git}reset\b$Rest\s--hard\b"; Reason = 'Discards all local changes irreversibly.' }
    @{ Pattern = "${Git}clean\b$Rest\s(?:-[a-z]*f|--force)"; Reason = 'Deletes untracked files irreversibly.' }
    @{ Pattern = "${Git}rebase\b(?!$Rest\s--(?:abort|continue|skip|quit)\b)"; Reason = 'Rebase rewrites history.' }
    @{ Pattern = '\brm\s+(?:-[a-z]*r[a-z]*f[a-z]*|-[a-z]*f[a-z]*r[a-z]*|-r\s+-f|-f\s+-r|--recursive\s+--force|--force\s+--recursive)\s+(?:--\s+)?["'']?(?:/|~|\$HOME|\$\{HOME\})/?\*?["'']?(?:\s|$|[;&|)])'; Reason = 'Deletes the root or home directory.' }
    @{ Pattern = '\bRemove-Item\b(?=.*-Recurse)(?=.*-Force).*C:\\Windows'; Reason = 'Windows system directory delete.' }
    @{ Pattern = '\bDROP\s+(?:TABLE|DATABASE|SCHEMA)\b'; Reason = 'Drops data irreversibly.' }
    @{ Pattern = '\btruncate\s+table\b'; Reason = 'Deletes all rows irreversibly.' }
    # Lowercase "truncate" alone is usually English or the shell command, so only uppercase counts without TABLE.
    @{ Pattern = '\bTRUNCATE\s+[\w."`\[]'; Reason = 'Deletes all rows irreversibly.'; CaseSensitive = $true }
    @{ Pattern = '\bDELETE\s+FROM\s+[\w."`\[\]]+\s*(?:;|$|"|'')'; Reason = 'DELETE without WHERE clause deletes all rows.' }
    @{ Pattern = '--no-verify'; Reason = 'Bypasses git hooks. Fix the hook failure instead.' }
)

$reason = $null
foreach ($entry in $BLOCKED) {
    $hit = if ($entry.CaseSensitive) { $Command -cmatch $entry.Pattern } else { $Command -match $entry.Pattern }
    if ($hit) { $reason = "Steve safety: $($entry.Reason)"; break }
}

# Staging check: every "git add" in the command, token by token.
if (-not $reason) {
    foreach ($stage in [regex]::Matches($Command, "${Git}add\s+($Rest)", 'IgnoreCase')) {
        $tokens = $stage.Groups[1].Value.Trim() -split '\s+'
        foreach ($token in $tokens) {
            if (@('.', '*', '-a', '--all') -contains $token) {
                $reason = 'Steve safety: stages everything, which can sweep in secrets. Stage specific files.'
                break
            }
            $name = (($token -replace '^["'']|["'']$', '') -split '[\\/]')[-1].ToLowerInvariant()
            if ($name -match '^\.env(?:\.(?!example$|sample$|template$).+)?$' -or
                $name -match '\.(?:pem|key)$' -or
                $name.StartsWith('id_rsa') -or
                $name.Contains('credentials') -or
                $name.Contains('secrets') -or
                $name -eq 'chronicle.db') {
                $reason = "Steve safety: staging '$token' - likely sensitive."
                break
            }
        }
        if ($reason) { break }
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
