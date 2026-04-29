<#
.SYNOPSIS
    Health check for the claude.bridge setup on Windows.

.DESCRIPTION
    Verifies: bridge folder + subfolders exist, Claude Desktop config has the
    'bridge' MCP server entry pointing at the right path, npx is available.
    Exits 1 if any check fails.
#>
[CmdletBinding()]
param(
    [string]$BridgePath = "P:\KnowledgeHub\claude.bridge",
    [string]$ServerName = "bridge"
)

$pass = New-Object System.Collections.Generic.List[string]
$fail = New-Object System.Collections.Generic.List[string]

# 1. Bridge folder + subfolders
if (Test-Path $BridgePath) {
    $pass.Add("Bridge folder exists: $BridgePath")
    foreach ($sub in 'ideas','specs','outputs','scripts','mcp','claude-code\commands') {
        $p = Join-Path $BridgePath $sub
        if (Test-Path $p) { $pass.Add("  $sub\ ok") } else { $fail.Add("  $sub\ MISSING") }
    }
} else {
    $fail.Add("Bridge folder MISSING: $BridgePath")
}

# 2. Claude Desktop config + MCP entry
$configPath = Join-Path $env:APPDATA "Claude\claude_desktop_config.json"
if (Test-Path $configPath) {
    try {
        $cfg = Get-Content $configPath -Raw | ConvertFrom-Json
        if ($cfg.mcpServers -and $cfg.mcpServers.$ServerName) {
            $argStr = $cfg.mcpServers.$ServerName.args -join ' '
            if ($argStr -like "*$BridgePath*") {
                $pass.Add("MCP '$ServerName' configured -> $BridgePath")
            } else {
                $fail.Add("MCP '$ServerName' points to wrong path: $argStr")
            }
        } else {
            $fail.Add("MCP '$ServerName' NOT configured. Run Install-ClaudeDesktopMcp.ps1")
        }
    } catch {
        $fail.Add("Could not parse $configPath : $($_.Exception.Message)")
    }
} else {
    $fail.Add("Claude Desktop config not found: $configPath")
}

# 3. npx availability (filesystem MCP server runs via npx)
$npx = Get-Command npx -ErrorAction SilentlyContinue
if ($npx) { $pass.Add("npx available: $($npx.Source)") }
else { $fail.Add("npx NOT found - install Node.js so the filesystem MCP server can run") }

# Report
Write-Host ""
Write-Host "=== PASS ($($pass.Count)) ===" -ForegroundColor Green
$pass | ForEach-Object { Write-Host "  $_" }

if ($fail.Count -gt 0) {
    Write-Host ""
    Write-Host "=== FAIL ($($fail.Count)) ===" -ForegroundColor Red
    $fail | ForEach-Object { Write-Host "  $_" }
    exit 1
}

Write-Host ""
Write-Host "All checks passed." -ForegroundColor Green
