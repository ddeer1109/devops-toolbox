<#
.SYNOPSIS
    Idempotently merges the claude.bridge filesystem MCP server into Claude Desktop config.

.DESCRIPTION
    Reads %APPDATA%\Claude\claude_desktop_config.json, ensures mcpServers.<ServerName>
    points at the bridge folder via @modelcontextprotocol/server-filesystem, writes back.
    On first run, backs up the existing config to claude_desktop_config.json.bak.

.EXAMPLE
    .\Install-ClaudeDesktopMcp.ps1

.EXAMPLE
    .\Install-ClaudeDesktopMcp.ps1 -BridgePath "D:\Other\claude.bridge"
#>
[CmdletBinding()]
param(
    [string]$BridgePath = "P:\KnowledgeHub\claude.bridge",
    [string]$ServerName = "bridge"
)

$ErrorActionPreference = "Stop"

$configDir  = Join-Path $env:APPDATA "Claude"
$configPath = Join-Path $configDir "claude_desktop_config.json"

if (-not (Test-Path $configDir)) {
    Write-Error "Claude Desktop config dir not found: $configDir`nInstall and launch Claude Desktop at least once before running this script."
    exit 1
}

if (-not (Test-Path $BridgePath)) {
    Write-Error "Bridge path not found: $BridgePath`nMount pCloud and ensure the folder exists."
    exit 1
}

# Load existing config or start fresh
if (Test-Path $configPath) {
    $backupPath = "$configPath.bak"
    if (-not (Test-Path $backupPath)) {
        Copy-Item $configPath $backupPath
        Write-Host "Backed up existing config -> $backupPath"
    }
    $config = Get-Content $configPath -Raw | ConvertFrom-Json
} else {
    $config = [PSCustomObject]@{}
    Write-Host "No existing config found; creating fresh."
}

# Ensure mcpServers exists
if (-not $config.PSObject.Properties.Match('mcpServers').Count) {
    $config | Add-Member -MemberType NoteProperty -Name mcpServers -Value ([PSCustomObject]@{})
}

$entry = [PSCustomObject]@{
    command = "npx"
    args    = @("-y", "@modelcontextprotocol/server-filesystem", $BridgePath)
}

if ($config.mcpServers.PSObject.Properties.Match($ServerName).Count) {
    $config.mcpServers.$ServerName = $entry
    Write-Host "Updated existing '$ServerName' MCP server entry."
} else {
    $config.mcpServers | Add-Member -MemberType NoteProperty -Name $ServerName -Value $entry
    Write-Host "Added new '$ServerName' MCP server entry."
}

$json = $config | ConvertTo-Json -Depth 10
[System.IO.File]::WriteAllText($configPath, $json, (New-Object System.Text.UTF8Encoding $false))
Write-Host "Wrote: $configPath"
Write-Host ""
Write-Host "Restart Claude Desktop for the change to take effect." -ForegroundColor Yellow
