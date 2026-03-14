#!/usr/bin/env bash
# setup-python.sh — Configure Python development tooling on WSL
# Usage: sudo ./setup-python.sh
#
# Ubuntu 24.04 ships Python 3.12 but without pip or venv.
# This script adds the dev tooling needed for real work:
#   - pip (package manager)
#   - venv (virtual environments — the standard way)
#   - dev headers (needed to compile C extensions)
#
# Philosophy: We use venv, not conda/pyenv. venv is built into Python,
# works everywhere, and is what you'll see in production. Each project
# gets its own venv — no global pip installs except core tools.

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[OK]${NC} $1"; }
warn()  { echo -e "${YELLOW}[SKIP]${NC} $1"; }
err()   { echo -e "${RED}[ERR]${NC} $1"; }

echo "========================================"
echo " Python Setup — WSL"
echo "========================================"
echo ""

if [[ $EUID -ne 0 ]]; then
    err "This script must be run with sudo"
    exit 1
fi

# Check Python is present
if ! command -v python3 &>/dev/null; then
    err "Python 3 not found — installing..."
    apt install -y -qq python3
fi

PYTHON_VER=$(python3 --version 2>&1 | awk '{print $2}')
PYTHON_MAJOR_MINOR=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
info "Python $PYTHON_VER found"

# --- Install pip ---
if command -v pip3 &>/dev/null; then
    warn "pip3 already installed"
else
    echo ">>> Installing pip..."
    apt install -y -qq python3-pip
    info "pip installed"
fi

# --- Install venv ---
VENV_PKG="python${PYTHON_MAJOR_MINOR}-venv"
if dpkg -s "$VENV_PKG" &>/dev/null; then
    warn "$VENV_PKG already installed"
else
    echo ">>> Installing venv..."
    apt install -y -qq "$VENV_PKG"
    info "venv installed"
fi

# --- Install dev headers (needed for packages with C extensions) ---
DEV_PKG="python${PYTHON_MAJOR_MINOR}-dev"
if dpkg -s "$DEV_PKG" &>/dev/null; then
    warn "$DEV_PKG already installed"
else
    echo ">>> Installing dev headers..."
    apt install -y -qq "$DEV_PKG"
    info "dev headers installed"
fi

# --- Install core global tools (pipx for isolated CLI tools) ---
if command -v pipx &>/dev/null; then
    warn "pipx already installed"
else
    echo ">>> Installing pipx..."
    apt install -y -qq pipx
    # Ensure pipx bin dir is on PATH
    pipx ensurepath 2>/dev/null || true
    info "pipx installed"
fi

# --- Verification ---
echo ""
echo "========================================"
echo " Verification"
echo "========================================"
echo ""
echo "Python:  $(python3 --version 2>&1)"
echo "pip:     $(pip3 --version 2>&1 | head -1)"
echo "pipx:    $(pipx --version 2>&1 || echo 'not found')"
echo ""
echo "Usage:"
echo "  # Create a project venv"
echo "  python3 -m venv .venv"
echo "  source .venv/bin/activate"
echo "  pip install -r requirements.txt"
echo ""
echo "  # Install CLI tools globally (isolated)"
echo "  pipx install httpie"
echo "  pipx install black"
# --- Add python/py aliases ---
ALIAS_FILE="/etc/profile.d/python-aliases.sh"
cat > "$ALIAS_FILE" <<'ALIASEOF'
# Set by devops-toolbox/wsl/setup-python.sh
alias python=python3
alias py=python3
alias pip=pip3
ALIASEOF
info "Aliases configured in $ALIAS_FILE (python, py, pip)"

echo ""
echo "NOTE: Open a new terminal or run 'source $ALIAS_FILE'"
echo "      to use 'py' and 'python' aliases."
echo ""
info "Done."
