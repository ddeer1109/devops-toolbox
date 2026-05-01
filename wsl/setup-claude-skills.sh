#!/usr/bin/env bash
# setup-claude-skills.sh — Install a curated set of Claude Code skills
# Usage: chmod +x setup-claude-skills.sh && ./setup-claude-skills.sh
# Safe to re-run — skips skills already installed in ~/.claude/skills/
#
# Surgical install (no plugin marketplaces): a small focused set chosen
# for Daniel's current work (Python, Postgres, Kafka, K8s/DevOps).
# Edit the SKILLS arrays below to add/remove.

set -euo pipefail

# --- Colors ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[OK]${NC} $1"; }
warn()  { echo -e "${YELLOW}[SKIP]${NC} $1"; }
err()   { echo -e "${RED}[ERR]${NC} $1"; }

echo "========================================"
echo " Claude Code Skills — surgical install"
echo "========================================"
echo ""

# --- 1. Prerequisites ---
if ! command -v npx &>/dev/null; then
    err "npx not found — install Node.js first"
    exit 1
fi
info "npx found"

if ! command -v claude &>/dev/null; then
    warn "claude CLI not found — skills will install, but you'll need Claude Code to use them"
fi

SKILLS_DIR="$HOME/.claude/skills"
mkdir -p "$SKILLS_DIR"

# --- 2. Skills to install ---
# Format: "<repo-url>|<skill-name>"
# Flags used: -g (global, ~/.claude/skills) -y (no prompts)
#             --copy (durable — survives npx cache eviction)
#             -a claude-code (target Claude Code agent dir)
SKILLS=(
    # DevOps / infra
    "https://github.com/jeffallan/claude-skills|devops-engineer"
    "https://github.com/jeffallan/claude-skills|kubernetes-specialist"
    "https://github.com/jeffallan/claude-skills|sre-engineer"
    "https://github.com/jeffallan/claude-skills|monitoring-expert"

    # Python / data
    "https://github.com/jeffallan/claude-skills|python-pro"
    "https://github.com/jeffallan/claude-skills|postgres-pro"
    "https://github.com/jeffallan/claude-skills|debugging-wizard"

    # Standalone — Python code-review best practices
    "https://github.com/wispbit-ai/skills|python-expert-best-practices-code-review"
)

install_skill() {
    local source="$1"
    local skill="$2"
    local target="$SKILLS_DIR/$skill"

    if [[ -e "$target" ]]; then
        warn "$skill already present at $target"
        return 0
    fi

    echo ">>> Installing $skill from $source"
    if npx -y skills add "$source" --skill "$skill" -g -y --copy -a claude-code; then
        info "$skill installed"
    else
        err "Failed to install $skill"
        return 1
    fi
}

echo ">>> Installing ${#SKILLS[@]} skill(s)..."
echo ""
for entry in "${SKILLS[@]}"; do
    IFS='|' read -r source skill <<< "$entry"
    install_skill "$source" "$skill" || true
done

# --- 3. Verification summary ---
echo ""
echo "========================================"
echo " Verification Summary"
echo "========================================"
echo ""
echo "Installed skills in $SKILLS_DIR:"
if [[ -d "$SKILLS_DIR" ]]; then
    ls -1 "$SKILLS_DIR" | while read -r s; do
        if [[ -L "$SKILLS_DIR/$s" ]]; then
            echo "  $s -> $(readlink "$SKILLS_DIR/$s")"
        else
            echo "  $s"
        fi
    done
else
    warn "$SKILLS_DIR does not exist"
fi

echo ""
info "Done. Restart Claude Code (or start a new session) to load the skills."
echo ""
echo "Manage skills:"
echo "  npx skills list -g                  # list installed (global)"
echo "  npx skills remove -g <name>         # remove a skill"
echo "  npx skills find <keyword>           # search for more skills"
