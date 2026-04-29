# Cross-machine bootstrap

End-to-end provisioning order for a fresh Windows + WSL2 + pCloud + Claude Desktop + Claude Code machine. Walk top-to-bottom; each step is idempotent and re-runnable.

Designed for: setting up the Polish PC during vacation with the same posture as the primary WSL workstation.

## Prerequisites (do once on the Windows host)

| # | Step | Notes |
|---|---|---|
| 0.1 | Install Windows 11 (or 10) and complete OOBE | — |
| 0.2 | Install Git for Windows + configure SSH key for GitHub | needed for cloning across both Windows and WSL |
| 0.3 | Install **pCloud Desktop**, sign in, **wait for full initial sync** | drive mapped to `P:` (default) |
| 0.4 | Install **Claude Desktop** ([claude.ai/download](https://claude.ai/download)) and launch once | creates `%APPDATA%\Claude\` |
| 0.5 | Install **Node.js LTS** (winget: `OpenJS.NodeJS.LTS`) | required by the filesystem MCP server (`npx`) |

## 1 — Windows side

```powershell
# Run PowerShell as Administrator
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

# Clone the toolbox somewhere durable
git clone https://github.com/ddeer1109/devops-toolbox.git C:\code\devops-toolbox
cd C:\code\devops-toolbox

# 1a. Optional — winget batch install of dev tools (JDK, Python, VS Code, Docker Desktop, Git, Maven, pCloud already installed)
.\wsl\setup-windows.ps1

# 1b. Wire Claude Desktop's filesystem MCP to the vault bridge
.\windows\claude-desktop\Install-ClaudeDesktopMcp.ps1
# (custom path:  .\windows\claude-desktop\Install-ClaudeDesktopMcp.ps1 -BridgePath "D:\Other\claude.bridge")

# 1c. Restart Claude Desktop fully (system tray → Quit), relaunch, then verify
.\windows\claude-desktop\Verify-Bridge.ps1
```

If `Verify-Bridge.ps1` exits 0, Claude Desktop can now read/write `P:\KnowledgeHub\claude.bridge\`.

## 2 — WSL side

```bash
# 2a. Install WSL2 + Ubuntu (skip if already installed)
#     PowerShell:  wsl --install -d Ubuntu

# 2b. Inside WSL, clone the two repos
mkdir -p ~/work && cd ~/work
git clone git@github.com:ddeer1109/devops-toolbox.git
git clone git@github.com:ddeer1109/dotfiles.git
# Other repos as needed: kafka-streams-learning, micro-tools, sm-dish, DevOps-doc

# 2c. System packages + git config
~/work/devops-toolbox/wsl/bootstrap.sh
# (with zsh:  ~/work/devops-toolbox/wsl/bootstrap.sh --with-zsh)

# 2d. Mount pCloud
sudo ~/work/devops-toolbox/wsl/mount-pcloud.sh
# Verify:  ls /mnt/p/KnowledgeHub  (should list README.md, _schema.md, claude.bridge/, wiki/, ...)

# 2e. Wire vault bridge — runs dotfiles bootstrap + verifies slash commands
DOTFILES_DIR=~/work/dotfiles ~/work/devops-toolbox/wsl/wire-vault-bridge.sh

# 2f. (Optional) language stacks
sudo ~/work/devops-toolbox/wsl/setup-java.sh
sudo ~/work/devops-toolbox/wsl/setup-python.sh
~/work/devops-toolbox/wsl/setup-vscode.sh
```

## 3 — Smoke test

| Test | Expected |
|---|---|
| **Claude Desktop**: ask "list files in claude.bridge/living" | shows `push.md`, `pull.md`, `exp-architecture.md` |
| **Claude Code** (in WSL): `/bridge-load push` | summarizes `claude.bridge/living/push.md` |
| **Claude Code**: `/bridge-save smoke-test` | writes `claude.bridge/outputs/smoke-test.md`; delete after |

## 4 — Persistence across reboots

`mount-pcloud.sh` mounts but doesn't persist. Two options:

- **fstab entry** (auto-remount when WSL starts, *if pCloud is already running*):
  ```
  P:\ /mnt/p drvfs defaults 0 0
  ```
  Add to `/etc/fstab`. Caveat: if pCloud starts after WSL, the mount fails silently and you must `sudo mount -a` (or re-run `mount-pcloud.sh`).
- **Systemd unit** (more reliable): out of scope; revisit if the fstab path proves fragile.

## 5 — When something drifts

If the Polish PC and primary WSL diverge (different paths, different mount letter, etc.):

```bash
# Each repo is git — check both ends are in sync
for d in dotfiles devops-toolbox kafka-streams-learning micro-tools sm-dish DevOps-doc; do
    echo "== $d =="
    git -C ~/work/$d status -sb
done

# Vault is pCloud-synced — check no conflict files
find /mnt/p/KnowledgeHub -name '*Conflict*' -o -name '* (1).md'
```

If there are pCloud conflict files, resolve manually (vault is non-versioned). If there are uncommitted git changes, commit/push from whichever machine has the work.

## 6 — Order-of-operations gotchas

- **Don't run `Install-ClaudeDesktopMcp.ps1` before pCloud has finished initial sync.** The script verifies the bridge path exists; if pCloud is still ghost-folder mode it will fail or, worse, succeed against an incomplete tree.
- **Don't run `wire-vault-bridge.sh` before `mount-pcloud.sh`.** It will exit early on "vault not found" but the message is friendlier if you go in order.
- **Restart Claude Desktop fully** (system tray, not just window) for MCP changes to load. The app reads its config only at process start.
