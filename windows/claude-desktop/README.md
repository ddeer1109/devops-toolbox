# Claude Desktop — vault bridge MCP

Windows-side scripts that wire **Claude Desktop** to the `claude.bridge/` subfolder of the KnowledgeHub vault via the official filesystem MCP server. Once installed, Claude Desktop can read and write *only* inside `P:\KnowledgeHub\claude.bridge\`.

The Linux/WSL counterpart (Claude Code slash commands) lives in [`dotfiles/claude/commands/`](https://github.com/ddeer1109/dotfiles) — `bridge-save.md`, `bridge-load.md`, `bridge-promote.md`. Symlinked into `~/.claude/commands/` by `dotfiles/bootstrap.sh`.

## Files

| File | Purpose |
|---|---|
| `Install-ClaudeDesktopMcp.ps1` | Idempotent — adds/updates the `bridge` MCP entry in `%APPDATA%\Claude\claude_desktop_config.json`. Backs up existing config on first run. |
| `Verify-Bridge.ps1` | Health check — verifies bridge folder + subfolders exist, Claude Desktop config has the entry, `npx` is available. Exit 1 on failure. |
| `filesystem-server.json` | Standalone reference of the MCP entry shape. Not consumed by the installer — useful for manual edits or other tools. |

## Prerequisites

1. **pCloud Desktop** installed, signed in, drive mapped to `P:` (default). Wait for initial sync to complete.
2. **Claude Desktop** installed and launched at least once (creates `%APPDATA%\Claude\`).
3. **Node.js** installed (`npx` is required to run the filesystem MCP server).

## Run order

```powershell
cd C:\path\to\devops-toolbox\windows\claude-desktop

# Defaults: bridge at P:\KnowledgeHub\claude.bridge, server name "bridge"
.\Install-ClaudeDesktopMcp.ps1

# Custom path or name:
.\Install-ClaudeDesktopMcp.ps1 -BridgePath "D:\Other\claude.bridge" -ServerName "bridge2"

# Restart Claude Desktop, then verify
.\Verify-Bridge.ps1
```

## Why this scoping matters

The MCP server is **scoped to `claude.bridge/` only**. Claude Desktop cannot write to `wiki/`, root inboxes, `_schema.md`, or any other vault subdirectory. Wiki maintenance happens via Claude Code (full filesystem access through WSL) or directly in Obsidian.

This is the boundary that lets the AI bridge be append-friendly without risking the curated parts of the vault.

## Troubleshooting

- **Bridge folder MISSING** → mount pCloud, wait for sync, re-run.
- **`npx` not found** → install Node.js (winget: `winget install OpenJS.NodeJS.LTS`).
- **Config not updating** → fully quit Claude Desktop (system tray, not just window close); re-launch.
- **MCP entry points to wrong path** → re-run `Install-ClaudeDesktopMcp.ps1` with the correct `-BridgePath`. The script overwrites the existing entry.
