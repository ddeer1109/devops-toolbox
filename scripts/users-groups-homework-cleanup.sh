#!/usr/bin/env bash
# =============================================================================
# Cleanup for Users & Groups Homework
#
# Removes users, groups, and directories created by users-groups-homework.sh
# Run with: sudo bash users-groups-homework-cleanup.sh
# =============================================================================

set -e

if [ "$(id -u)" -ne 0 ]; then
    echo "Please run with sudo: sudo bash $0"
    exit 1
fi

CALLER="${SUDO_USER:-$USER}"

echo ""
echo "--- Removing users ---"

userdel -r testuser1 2>/dev/null && echo "Removed testuser1" || echo "testuser1 not found"
userdel -r testuser2 2>/dev/null && echo "Removed testuser2" || echo "testuser2 not found"
userdel -r testuser3 2>/dev/null && echo "Removed testuser3" || echo "testuser3 not found"


echo ""
echo "--- Removing groups ---"

groupdel team-alpha 2>/dev/null && echo "Removed team-alpha" || echo "team-alpha not found"
groupdel team-beta  2>/dev/null && echo "Removed team-beta"  || echo "team-beta not found"


echo ""
echo "--- Removing directories ---"

rm -rf /home/$CALLER/team-alpha-dir && echo "Removed team-alpha-dir" || echo "team-alpha-dir not found"
rm -rf /home/$CALLER/team-beta-dir  && echo "Removed team-beta-dir"  || echo "team-beta-dir not found"

echo ""
echo "Cleanup done!"
