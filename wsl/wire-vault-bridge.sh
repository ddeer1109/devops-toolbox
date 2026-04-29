#!/usr/bin/env bash
# wire-vault-bridge.sh — WSL-side post-mount wire-up for the KnowledgeHub vault bridge.
# Assumes pCloud is mounted (run mount-pcloud.sh first if not) and dotfiles is cloned.
#
# Idempotent: each step skips if already done.
#
# Usage:
#   ./wire-vault-bridge.sh                              # Default DOTFILES_DIR=$HOME/dotfiles
#   DOTFILES_DIR=$HOME/work/dotfiles ./wire-vault-bridge.sh

set -euo pipefail

VAULT="${VAULT_DIR:-/mnt/p/KnowledgeHub}"
BRIDGE="$VAULT/claude.bridge"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
COMMANDS_DIR="$HOME/.claude/commands"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
ok()   { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC}  $1"; }
err()  { echo -e "${RED}[ERR]${NC} $1"; }

echo "=========================================="
echo " Wire vault bridge — WSL"
echo "=========================================="

# 1. Vault reachable?
if [[ ! -d "$VAULT" ]]; then
    err "Vault not found at $VAULT"
    echo "    Mount pCloud first:  sudo $(dirname "$0")/mount-pcloud.sh"
    exit 1
fi
ok "Vault reachable at $VAULT"

# 2. Bridge skeleton present?
missing=0
for sub in ideas specs outputs living scripts mcp claude-code/commands; do
    if [[ -d "$BRIDGE/$sub" ]]; then
        ok "  $sub/ present"
    else
        warn "  $sub/ missing — was the bridge ever initialized?"
        missing=$((missing+1))
    fi
done
if (( missing > 0 )); then
    warn "$missing bridge subdir(s) missing — fresh setup? Skeleton seeds:"
    echo "    mkdir -p $BRIDGE/{ideas,specs,outputs/sessions,living,scripts,mcp,claude-code/commands}"
fi

# 3. Dotfiles cloned?
if [[ ! -d "$DOTFILES_DIR" ]]; then
    err "Dotfiles not found at $DOTFILES_DIR"
    echo "    Clone first:  git clone git@github.com:ddeer1109/dotfiles.git $DOTFILES_DIR"
    echo "    Or set DOTFILES_DIR=<path> and re-run."
    exit 1
fi
ok "Dotfiles at $DOTFILES_DIR"

# 4. Run dotfiles bootstrap (idempotent — symlinks slash commands and CLAUDE.md)
echo
echo ">>> Running dotfiles bootstrap..."
"$DOTFILES_DIR/bootstrap.sh"

# 5. Verify slash commands now resolve in ~/.claude/commands
echo
echo ">>> Verifying slash commands wired..."
for cmd in bridge-save bridge-load bridge-promote; do
    if [[ -L "$COMMANDS_DIR/$cmd.md" ]]; then
        ok "  /$cmd → $(readlink "$COMMANDS_DIR/$cmd.md")"
    else
        err "  /$cmd NOT linked at $COMMANDS_DIR/$cmd.md"
    fi
done

echo
ok "Done. Test in Claude Code:  /bridge-load push   (should read living/push.md)"
