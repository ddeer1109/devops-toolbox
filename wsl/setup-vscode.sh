#!/usr/bin/env bash
# setup-vscode.sh — Install VS Code extensions for WSL development
# Usage: ./setup-vscode.sh [--list-only]
#
# Installs a curated set of extensions for the WSL dev workflow.
# Requires VS Code with the WSL extension already connected
# (i.e., run this from inside a WSL terminal that has VS Code's
# remote server installed — you'll know if `code --version` works).
#
# Options:
#   --list-only   Just print extensions without installing

set -euo pipefail

LIST_ONLY=false
for arg in "$@"; do
    case "$arg" in
        --list-only) LIST_ONLY=true ;;
        *) echo "Unknown option: $arg"; echo "Usage: $0 [--list-only]"; exit 1 ;;
    esac
done

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[OK]${NC} $1"; }
warn()  { echo -e "${YELLOW}[SKIP]${NC} $1"; }
err()   { echo -e "${RED}[ERR]${NC} $1"; }

echo "========================================"
echo " VS Code Extensions — WSL Setup"
echo "========================================"
echo ""

# Check code CLI is available
if ! command -v code &>/dev/null; then
    err "VS Code CLI not found in WSL"
    echo ""
    echo "  To fix:"
    echo "  1. Install VS Code on Windows"
    echo "  2. Install the 'WSL' extension (ms-vscode-remote.remote-wsl)"
    echo "  3. Open a WSL terminal from VS Code (or run 'code .' from WSL)"
    echo "  4. Re-run this script"
    exit 1
fi

# Extension list — grouped by purpose
# Format: "extension-id|description"
EXTENSIONS=(
    # --- Remote / WSL ---
    "ms-vscode-remote.remote-wsl|WSL — develop in Linux from Windows"

    # --- Java / Spring ---
    "vscjava.vscode-java-pack|Java Extension Pack (language support, debugger, test runner)"
    "vmware.vscode-spring-boot|Spring Boot Tools (navigate, run, debug Spring apps)"
    "vscjava.vscode-spring-initializr|Spring Initializr (scaffold new projects)"

    # --- Docker / Containers ---
    "ms-azuretools.vscode-docker|Docker (build, manage, deploy containers)"

    # --- Data / Kafka ---
    "jeppeandersen.vscode-kafka|Kafka (browse topics, produce/consume messages)"

    # --- Git ---
    "eamodio.gitlens|GitLens (blame, history, compare)"
    "mhutchie.git-graph|Git Graph (visual branch/commit graph)"

    # --- General productivity ---
    "esbenp.prettier-vscode|Prettier (format JSON, YAML, Markdown)"
    "redhat.vscode-yaml|YAML (validation, autocomplete for docker-compose, k8s)"
    "ms-vscode.makefile-tools|Makefile Tools"

    # --- AI ---
    "anthropic.claude-code|Claude Code"
)

# Get currently installed extensions
INSTALLED=$(code --list-extensions 2>/dev/null)

for entry in "${EXTENSIONS[@]}"; do
    ext_id="${entry%%|*}"
    ext_desc="${entry##*|}"

    if [[ "$LIST_ONLY" == true ]]; then
        echo "  $ext_id — $ext_desc"
        continue
    fi

    if echo "$INSTALLED" | grep -qi "^${ext_id}$"; then
        warn "$ext_id (already installed)"
    else
        echo ">>> Installing $ext_id..."
        if code --install-extension "$ext_id" --force 2>/dev/null; then
            info "$ext_id — $ext_desc"
        else
            err "Failed to install $ext_id"
        fi
    fi
done

if [[ "$LIST_ONLY" == true ]]; then
    echo ""
    echo "Run without --list-only to install."
    exit 0
fi

echo ""
echo "========================================"
echo " Installed Extensions"
echo "========================================"
code --list-extensions 2>/dev/null
echo ""
info "Done. Reload VS Code window if extensions don't appear immediately."
