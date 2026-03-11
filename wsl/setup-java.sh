#!/usr/bin/env bash
# setup-java.sh — Install and configure Java JDKs on WSL
# Usage: sudo ./setup-java.sh [--jdk 17] [--jdk 21] [--default 17]
#
# Installs OpenJDK from Ubuntu repos and configures JAVA_HOME.
# Uses update-alternatives to switch between versions.
#
# Without arguments, installs JDK 17 + 21 with 17 as default.
#
# Examples:
#   sudo ./setup-java.sh                    # JDK 17 (default) + 21
#   sudo ./setup-java.sh --jdk 17           # Only JDK 17
#   sudo ./setup-java.sh --default 21       # JDK 17 + 21, default to 21
#
# After install, switch versions any time with:
#   sudo update-alternatives --config java

set -euo pipefail

# --- Defaults ---
JDKS=()
DEFAULT_JDK=""

# --- Parse args ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        --jdk)
            JDKS+=("$2")
            shift 2
            ;;
        --default)
            DEFAULT_JDK="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: sudo $0 [--jdk VERSION]... [--default VERSION]"
            exit 1
            ;;
    esac
done

# If no JDKs specified, install 17 + 21
if [[ ${#JDKS[@]} -eq 0 ]]; then
    JDKS=(17 21)
fi

# Default to the first specified JDK if --default not given
if [[ -z "$DEFAULT_JDK" ]]; then
    DEFAULT_JDK="${JDKS[0]}"
fi

# --- Colors ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[OK]${NC} $1"; }
warn()  { echo -e "${YELLOW}[SKIP]${NC} $1"; }
err()   { echo -e "${RED}[ERR]${NC} $1"; }

echo "========================================"
echo " Java Setup — WSL"
echo "========================================"
echo ""

if [[ $EUID -ne 0 ]]; then
    err "This script must be run with sudo"
    exit 1
fi

# --- Install JDKs ---
for ver in "${JDKS[@]}"; do
    pkg="openjdk-${ver}-jdk"
    if dpkg -s "$pkg" &>/dev/null; then
        warn "JDK $ver already installed"
    else
        echo ">>> Installing JDK ${ver}..."
        apt install -y -qq "$pkg"
        info "JDK $ver installed"
    fi
done

# --- Set default via update-alternatives ---
JAVA_BIN="/usr/lib/jvm/java-${DEFAULT_JDK}-openjdk-amd64/bin/java"
JAVAC_BIN="/usr/lib/jvm/java-${DEFAULT_JDK}-openjdk-amd64/bin/javac"

if [[ -f "$JAVA_BIN" ]]; then
    update-alternatives --set java "$JAVA_BIN" 2>/dev/null || true
    update-alternatives --set javac "$JAVAC_BIN" 2>/dev/null || true
    info "Default Java set to JDK $DEFAULT_JDK"
else
    err "JDK $DEFAULT_JDK binary not found at $JAVA_BIN"
fi

# --- Configure JAVA_HOME in profile ---
JAVA_HOME_DIR="/usr/lib/jvm/java-${DEFAULT_JDK}-openjdk-amd64"
PROFILE_FILE="/etc/profile.d/java-home.sh"

cat > "$PROFILE_FILE" <<ENVEOF
# Set by devops-toolbox/wsl/setup-java.sh
export JAVA_HOME="${JAVA_HOME_DIR}"
export PATH="\$JAVA_HOME/bin:\$PATH"
ENVEOF

info "JAVA_HOME configured in $PROFILE_FILE"

# Also export for current shell session
export JAVA_HOME="$JAVA_HOME_DIR"

# --- Install Maven ---
if dpkg -s maven &>/dev/null; then
    warn "Maven already installed"
else
    echo ">>> Installing Maven..."
    apt install -y -qq maven
    info "Maven installed"
fi

# --- Verification ---
echo ""
echo "========================================"
echo " Verification"
echo "========================================"

echo ""
echo "Installed JDKs:"
for ver in "${JDKS[@]}"; do
    jvm_path="/usr/lib/jvm/java-${ver}-openjdk-amd64"
    if [[ -d "$jvm_path" ]]; then
        version_str=$("$jvm_path/bin/java" -version 2>&1 | head -1)
        info "JDK $ver — $version_str"
        echo "       Path: $jvm_path"
    fi
done

echo ""
echo "Active Java:"
java -version 2>&1 | head -1
echo "  JAVA_HOME=$JAVA_HOME_DIR"

echo ""
echo "Maven:"
mvn -version 2>&1 | head -1

echo ""
echo "Switch versions:"
echo "  sudo update-alternatives --config java"
echo "  sudo update-alternatives --config javac"
echo ""
echo "NOTE: Open a new terminal or run 'source $PROFILE_FILE'"
echo "      to pick up JAVA_HOME in your current session."
