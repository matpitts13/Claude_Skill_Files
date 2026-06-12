# block-dangerous.ps1
# Hook: runs before tool execution to block dangerous operations.
# Configure in settings.json under hooks.PreToolUse.
#
# OVERRIDE: To allow a blocked operation for a single command, Claude must
# first get explicit user permission, then set:
#   $env:STEVE_ALLOW_DANGEROUS = "1"
# The env var applies only to the current shell session. Clear it after use:
#   $env:STEVE_ALLOW_DANGEROUS = ""
#
# Claude may NOT set STEVE_ALLOW_DANGEROUS without explicit user permission.

param(
    [string]$ToolName,
    [string]$ToolInput
)

# If the user has explicitly granted override permission this session, pass through
# but log what was allowed so the user can see it.
if ($env:STEVE_ALLOW_DANGEROUS -eq "1") {
    Write-Warning "STEVE_ALLOW_DANGEROUS is set — dangerous operation allowed by user permission."
    exit 0
}

# Patterns that are blocked by default. Each entry is:
# @{ Pattern = '...'; Reason = '...' }
$BLOCKED = @(
    @{ Pattern = 'git push --force(?!-with-lease)'; Reason = 'Force-push can overwrite upstream history. Use --force-with-lease instead, or get user permission.' }
    @{ Pattern = 'git reset --hard';                Reason = 'Discards all local changes irreversibly.' }
    @{ Pattern = 'git clean -f';                    Reason = 'Deletes untracked files irreversibly.' }
    @{ Pattern = 'git rebase(?!.*--abort)';         Reason = 'Rebase rewrites history. Confirm rebase is appropriate before proceeding.' }
    @{ Pattern = 'rm -rf /';                        Reason = 'Root filesystem delete.' }
    @{ Pattern = 'Remove-Item.*-Recurse.*-Force.*C:\\Windows'; Reason = 'Windows system directory delete.' }
    @{ Pattern = 'DROP TABLE';                      Reason = 'Drops a table irreversibly. Confirm with user.' }
    @{ Pattern = 'DELETE FROM \w+ *$';              Reason = 'DELETE without WHERE clause — deletes all rows.' }
    @{ Pattern = '--no-verify';                     Reason = 'Bypasses git hooks. Fix the hook failure instead.' }
)

foreach ($entry in $BLOCKED) {
    if ($ToolInput -match $entry.Pattern) {
        Write-Error "BLOCKED: '$($entry.Pattern)' — $($entry.Reason)`n`nTo allow this, get explicit user permission then set: `$env:STEVE_ALLOW_DANGEROUS = '1'"
        exit 1
    }
}

# Sensitive file staging check
if ($ToolName -eq "Bash" -and $ToolInput -match "git add") {
    $sensitiveFiles = @('.env', 'credentials', '.pem', '.key', 'id_rsa', 'secrets')
    foreach ($f in $sensitiveFiles) {
        if ($ToolInput -match [regex]::Escape($f)) {
            Write-Error "BLOCKED: Staging a file matching '$f' — likely sensitive. Confirm with user.`n`nTo allow: get user permission then set `$env:STEVE_ALLOW_DANGEROUS = '1'"
            exit 1
        }
    }
}

exit 0
