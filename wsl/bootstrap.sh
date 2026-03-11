#!/usr/bin/env bash
# bootstrap.sh — Idempotent WSL environment setup
# Usage: chmod +x bootstrap.sh && ./bootstrap.sh [--with-zsh]
# Safe to re-run — skips steps that are already done.
#
# Options:
#   --with-zsh   Install Zsh, Oh My Zsh, and zsh-autosuggestions plugin

set -euo pipefail

# --- Parse flags ---
INSTALL_ZSH=false
for arg in "$@"; do
    case "$arg" in
        --with-zsh) INSTALL_ZSH=true ;;
        *) echo "Unknown option: $arg"; echo "Usage: $0 [--with-zsh]"; exit 1 ;;
    esac
done

# --- Colors ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[OK]${NC} $1"; }
warn()  { echo -e "${YELLOW}[SKIP]${NC} $1"; }
err()   { echo -e "${RED}[ERR]${NC} $1"; }

echo "========================================"
echo " WSL Bootstrap — devops-toolbox"
echo "========================================"
echo ""

# --- 1. System update ---
echo ">>> Updating system packages..."
sudo apt update -qq && sudo apt upgrade -y -qq
info "System packages updated"

# --- 2. Install essential packages ---
PACKAGES=(unzip htop tree jq)

for pkg in "${PACKAGES[@]}"; do
    if dpkg -s "$pkg" &>/dev/null; then
        warn "$pkg already installed"
    else
        sudo apt install -y -qq "$pkg"
        info "$pkg installed"
    fi
done

# --- 3. Git global config ---
GIT_USER="Daniel"
GIT_EMAIL="dmwator11@gmail.com"

current_name=$(git config --global user.name 2>/dev/null || echo "")
current_email=$(git config --global user.email 2>/dev/null || echo "")

if [[ "$current_name" == "$GIT_USER" && "$current_email" == "$GIT_EMAIL" ]]; then
    warn "Git identity already configured ($GIT_USER <$GIT_EMAIL>)"
else
    git config --global user.name "$GIT_USER"
    git config --global user.email "$GIT_EMAIL"
    info "Git identity set to $GIT_USER <$GIT_EMAIL>"
fi

# Core settings
git config --global core.editor "vim"
git config --global init.defaultBranch "main"
git config --global pull.rebase false

# --- 4. Git aliases ---
git config --global alias.s "status -sb"
git config --global alias.lg "log --oneline --graph --decorate --all"
git config --global alias.amend "commit --amend --no-edit"
git config --global alias.undo "reset HEAD~1 --mixed"
info "Git aliases configured (s, lg, amend, undo)"

# --- 5. Zsh (optional) ---
if [[ "$INSTALL_ZSH" == true ]]; then
    # Install zsh package
    if dpkg -s zsh &>/dev/null; then
        warn "zsh already installed"
    else
        sudo apt install -y -qq zsh
        info "zsh installed"
    fi

    # Oh My Zsh
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        warn "Oh My Zsh already installed"
    else
        echo ">>> Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        info "Oh My Zsh installed"
    fi

    # zsh-autosuggestions plugin
    ZSH_AUTOSUGGEST_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
    if [[ -d "$ZSH_AUTOSUGGEST_DIR" ]]; then
        warn "zsh-autosuggestions already installed"
    else
        git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_AUTOSUGGEST_DIR"
        info "zsh-autosuggestions plugin installed"
    fi

    # Enable plugin in .zshrc
    if [[ -f "$HOME/.zshrc" ]]; then
        if grep -q "zsh-autosuggestions" "$HOME/.zshrc"; then
            warn "zsh-autosuggestions already enabled in .zshrc"
        else
            sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions)/' "$HOME/.zshrc"
            info "zsh-autosuggestions enabled in .zshrc"
        fi
    fi

    # Set Zsh as default shell
    current_shell=$(getent passwd "$(whoami)" | cut -d: -f7)
    if [[ "$current_shell" == *"zsh"* ]]; then
        warn "Zsh is already the default shell"
    else
        sudo chsh -s "$(which zsh)" "$(whoami)"
        info "Default shell changed to Zsh"
    fi
else
    warn "Zsh skipped (use --with-zsh to install)"
fi

# --- Verification summary ---
echo ""
echo "========================================"
echo " Verification Summary"
echo "========================================"

check() {
    if command -v "$1" &>/dev/null; then
        info "$1 → $(command -v "$1")"
    else
        err "$1 not found"
    fi
}

check unzip
check htop
check tree
check jq
check git
if [[ "$INSTALL_ZSH" == true ]]; then
    check zsh
fi

echo ""
echo "Git identity:"
echo "  user.name  = $(git config --global user.name)"
echo "  user.email = $(git config --global user.email)"
echo ""
echo "Git aliases:"
echo "  git s     → status -sb"
echo "  git lg    → log --oneline --graph --decorate --all"
echo "  git amend → commit --amend --no-edit"
echo "  git undo  → reset HEAD~1 --mixed"
echo ""

if command -v docker &>/dev/null; then
    info "Docker CLI available"
else
    warn "Docker CLI not found — enable Docker Desktop WSL integration (see README.md Level 1)"
fi

# --- 6. VS Code extensions ---
if command -v code &>/dev/null; then
    info "VS Code CLI detected — run './wsl/setup-vscode.sh' to install extensions"
else
    warn "VS Code CLI not found — connect to WSL from VS Code first, then run setup-vscode.sh"
fi

# --- 7. pCloud mount ---
echo ""
echo ">>> pCloud drive mount:"
if mount | grep -q "/mnt/p"; then
    info "pCloud already mounted at /mnt/p"
elif [[ -d "/mnt/p" ]]; then
    warn "Mount point /mnt/p exists but not mounted — run: sudo ./wsl/mount-pcloud.sh"
else
    warn "pCloud not mounted — run: sudo ./wsl/mount-pcloud.sh"
fi

echo ""
if [[ "$INSTALL_ZSH" == true ]]; then
    info "Bootstrap complete! Restart your terminal to use Zsh."
else
    info "Bootstrap complete!"
fi
echo ""
echo "Next steps:"
echo "  sudo ./wsl/mount-pcloud.sh       # Mount pCloud P: drive"
echo "  ./wsl/setup-vscode.sh            # Install VS Code extensions"
