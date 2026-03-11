# WSL Environment Setup

Two-level guide for setting up a professional DevOps environment on Windows 11 with WSL2.

## Level 1 — Windows / PowerShell

These steps run on the **Windows host**.

### 1.1 Install WSL2 + Ubuntu

If WSL is not yet installed:

```powershell
wsl --install -d Ubuntu
```

After installation, reboot and set your Unix username/password on first launch.

Verify:

```powershell
wsl -l -v
# Should show Ubuntu with VERSION 2
```

### 1.2 Enable Docker Desktop WSL Integration

> This is a **manual GUI step** — it cannot be scripted.

1. Open **Docker Desktop** → Settings → Resources → **WSL Integration**
2. Toggle **Enable integration with my default WSL distro**
3. Toggle the switch next to **Ubuntu**
4. Click **Apply & Restart**

After Docker restarts, open a WSL terminal and verify:

```bash
docker run hello-world
```

## Level 2 — Linux / Bash (inside WSL)

All remaining setup is handled by the bootstrap script.

### Run the bootstrap

```bash
# Clone the toolbox (if not already cloned)
git clone https://github.com/ddeer1109/devops-toolbox.git ~/devops-toolbox

# Run the bootstrap script
chmod +x ~/devops-toolbox/wsl/bootstrap.sh
~/devops-toolbox/wsl/bootstrap.sh
```

The script is **idempotent** — safe to re-run at any time. It will:

- Update system packages
- Install essential tools: `unzip`, `htop`, `tree`, `jq`
- Configure Git identity and aliases

#### Optional: Zsh

To also install Zsh, Oh My Zsh, and zsh-autosuggestions:

```bash
~/devops-toolbox/wsl/bootstrap.sh --with-zsh
```

> Zsh is great on a personal workstation but won't be available on most servers/containers.
> All scripts in this repo use `#!/usr/bin/env bash` for portability.

See [bootstrap.sh](bootstrap.sh) for details.

### Post-bootstrap

Verify everything works:

```bash
git s                 # alias for: git status
git lg                # alias for: pretty log
jq --version
docker run hello-world
```

## Additional Setup Scripts

### Mount pCloud Drive

pCloud uses a virtual drive (default `P:`) that WSL doesn't auto-mount. This script mounts it and shows how to persist via fstab.

```bash
sudo ./wsl/mount-pcloud.sh        # Mounts P: at /mnt/p
sudo ./wsl/mount-pcloud.sh Q      # Custom drive letter
```

After mounting, pCloud files are at `/mnt/p/`. Useful for cross-workspace data portability.

### VS Code Extensions

Installs a curated set of extensions for the WSL dev workflow (Java/Spring, Docker, Kafka, Git, YAML).

```bash
./wsl/setup-vscode.sh             # Install all extensions
./wsl/setup-vscode.sh --list-only # Preview what would be installed
```

Requires VS Code to be connected to WSL first (the `code` CLI must be available).
