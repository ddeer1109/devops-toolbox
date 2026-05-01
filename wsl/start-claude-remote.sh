#!/usr/bin/env bash
# start-claude-remote.sh — Start Claude Code with Remote Control for phone/browser access
# Usage: ./start-claude-remote.sh [--name "session-name"] [--permission-mode <mode>] [--sandbox] [-- <extra claude args>]
#
# Run this from the workspace you want to control remotely:
#   cd ~/some-project
#   ~/devops-toolbox/wsl/start-claude-remote.sh
#
# This starts an interactive Claude Code session in the current directory with
# Remote Control enabled so you can continue it from claude.ai/code or the
# Claude mobile app. It is a better fit than exposing the whole WSL editor when
# the real goal is just to answer Claude prompts from your phone.

set -euo pipefail

MIN_VERSION="2.1.51"
SESSION_NAME="$(basename "$PWD")"
PERMISSION_MODE=""
ENABLE_SANDBOX=false
PASSTHROUGH_ARGS=()

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[OK]${NC} $1"; }
warn()  { echo -e "${YELLOW}[SKIP]${NC} $1"; }
err()   { echo -e "${RED}[ERR]${NC} $1"; }

usage() {
    cat <<'EOF'
Usage: ./start-claude-remote.sh [options] [-- <extra claude args>]

Options:
  --name NAME               Session name shown in claude.ai/code
  --permission-mode MODE    Pass a permission mode to Claude (default, acceptEdits, plan, auto, dontAsk, bypassPermissions)
  --sandbox                 Start Claude with bash sandboxing enabled
  -h, --help                Show this help

Examples:
  ./wsl/start-claude-remote.sh
  ./wsl/start-claude-remote.sh --name auth-fix --permission-mode plan
  ./wsl/start-claude-remote.sh --sandbox -- --model claude-sonnet-4-6
EOF
}

version_gte() {
    local current="$1"
    local required="$2"

    [[ "$(printf '%s\n%s\n' "$required" "$current" | sort -V | tail -n1)" == "$current" ]]
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --name)
            [[ $# -ge 2 ]] || { err "--name requires a value"; exit 1; }
            SESSION_NAME="$2"
            shift 2
            ;;
        --permission-mode)
            [[ $# -ge 2 ]] || { err "--permission-mode requires a value"; exit 1; }
            PERMISSION_MODE="$2"
            shift 2
            ;;
        --sandbox)
            ENABLE_SANDBOX=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        --)
            shift
            PASSTHROUGH_ARGS=("$@")
            break
            ;;
        *)
            PASSTHROUGH_ARGS+=("$1")
            shift
            ;;
    esac
done

echo "========================================"
echo " Claude Code Remote Control — WSL"
echo "========================================"
echo ""

if ! command -v claude &>/dev/null; then
    err "claude CLI not found"
    echo ""
    echo "Install Claude Code first, then re-run this script."
    exit 1
fi

CLAUDE_VERSION_RAW=$(claude --version 2>/dev/null | head -1)
CLAUDE_VERSION=$(echo "$CLAUDE_VERSION_RAW" | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true)

if [[ -z "$CLAUDE_VERSION" ]]; then
    warn "Could not parse Claude version from: $CLAUDE_VERSION_RAW"
else
    info "Claude Code $CLAUDE_VERSION found"
    if ! version_gte "$CLAUDE_VERSION" "$MIN_VERSION"; then
        err "Claude Code $MIN_VERSION or newer is required for Remote Control"
        exit 1
    fi
fi

if ! claude auth status &>/dev/null; then
    err "Claude Code is not logged in"
    echo ""
    echo "Run 'claude auth login' with your Claude.ai account first."
    exit 1
fi

if [[ -n "${ANTHROPIC_API_KEY:-}" ]]; then
    warn "ANTHROPIC_API_KEY is set. Remote Control needs Claude.ai auth and may fail if API-key auth takes precedence."
fi

for provider_var in CLAUDE_CODE_USE_BEDROCK CLAUDE_CODE_USE_VERTEX CLAUDE_CODE_USE_FOUNDRY; do
    if [[ -n "${!provider_var:-}" ]]; then
        warn "$provider_var is set. Remote Control requires Claude.ai auth instead of third-party provider mode."
    fi
done

echo "Workspace: $PWD"
echo "Session:   $SESSION_NAME"
echo ""
echo "Connect from:"
echo "  - https://claude.ai/code"
echo "  - Claude mobile app (same account)"
echo ""
echo "Notes:"
echo "  - The local claude process must stay running"
echo "  - Run Claude locally in this directory once if workspace trust has not been accepted yet"
echo "  - The next screen will print the direct session URL and QR code instructions"
echo ""

CMD=(claude --remote-control --name "$SESSION_NAME")

if [[ -n "$PERMISSION_MODE" ]]; then
    CMD+=(--permission-mode "$PERMISSION_MODE")
fi

if [[ "$ENABLE_SANDBOX" == true ]]; then
    CMD+=(--sandbox)
fi

if [[ ${#PASSTHROUGH_ARGS[@]} -gt 0 ]]; then
    CMD+=("${PASSTHROUGH_ARGS[@]}")
fi

exec "${CMD[@]}"