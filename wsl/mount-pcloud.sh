#!/usr/bin/env bash
# mount-pcloud.sh — Mount pCloud virtual drive (P:) in WSL
# Usage: sudo ./mount-pcloud.sh [DRIVE_LETTER]
#
# pCloud on Windows maps as a virtual drive (default P:).
# WSL doesn't auto-mount virtual drives — only physical ones (C:, D:).
# This script mounts it manually and optionally persists via /etc/fstab.
#
# Prerequisites:
#   - pCloud Desktop installed on Windows and running
#   - pCloud mapped to a drive letter (default: P)

set -euo pipefail

DRIVE_LETTER="${1:-P}"
DRIVE_UPPER="${DRIVE_LETTER^^}"
MOUNT_POINT="/mnt/${DRIVE_LETTER,,}"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[OK]${NC} $1"; }
warn()  { echo -e "${YELLOW}[SKIP]${NC} $1"; }
err()   { echo -e "${RED}[ERR]${NC} $1"; }

echo "========================================"
echo " pCloud Mount — WSL"
echo "========================================"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    err "This script must be run with sudo"
    echo "  Usage: sudo $0 [DRIVE_LETTER]"
    exit 1
fi

# Create mount point if needed
if [[ -d "$MOUNT_POINT" ]]; then
    warn "Mount point $MOUNT_POINT already exists"
else
    mkdir -p "$MOUNT_POINT"
    info "Created mount point $MOUNT_POINT"
fi

# Check if already mounted
if mount | grep -q "$MOUNT_POINT"; then
    warn "Something is already mounted at $MOUNT_POINT"
    echo "  Currently mounted:"
    mount | grep "$MOUNT_POINT"
    echo ""
    echo "  To remount, first unmount: sudo umount $MOUNT_POINT"
    exit 0
fi

# Mount the drive
echo ">>> Mounting ${DRIVE_UPPER}: at $MOUNT_POINT..."
if mount -t drvfs "${DRIVE_UPPER}:" "$MOUNT_POINT" 2>/dev/null; then
    info "Mounted ${DRIVE_UPPER}: at $MOUNT_POINT"
else
    err "Failed to mount ${DRIVE_UPPER}: — is pCloud running on Windows?"
    echo "  Make sure pCloud Desktop is open and the drive letter is ${DRIVE_UPPER}:"
    exit 1
fi

# Verify
echo ""
echo ">>> pCloud contents:"
ls "$MOUNT_POINT" 2>/dev/null | head -20
echo ""

# Offer fstab persistence
FSTAB_ENTRY="${DRIVE_UPPER}:\\ ${MOUNT_POINT} drvfs defaults 0 0"
if grep -q "$MOUNT_POINT" /etc/fstab 2>/dev/null; then
    warn "fstab entry already exists for $MOUNT_POINT"
else
    echo "----------------------------------------------"
    echo "To auto-mount on WSL startup, add to /etc/fstab:"
    echo ""
    echo "  $FSTAB_ENTRY"
    echo ""
    echo "NOTE: This only works if pCloud is already running"
    echo "when WSL starts. If pCloud starts later, you'll"
    echo "need to run this script again or: sudo mount -a"
    echo "----------------------------------------------"
fi

echo ""
info "Done. Access pCloud at: $MOUNT_POINT"
