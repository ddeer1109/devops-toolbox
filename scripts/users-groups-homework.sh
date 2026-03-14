#!/usr/bin/env bash
# =============================================================================
# Users & Groups Homework
#
# Creates 3 users, 2 groups, 2 directories and shows how to switch users.
# Run with: sudo bash users-groups-homework.sh
# =============================================================================

# Exit on any error
set -e

# Check we're running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "Please run with sudo: sudo bash $0"
    exit 1
fi

# Remember who called sudo (so directories are owned by us, not root)
CALLER="${SUDO_USER:-$USER}"


# ---- Step 1: Create 3 users ----
echo ""
echo "--- Creating users ---"

useradd -m testuser1 2>/dev/null && echo "Created testuser1" || echo "testuser1 already exists"
useradd -m testuser2 2>/dev/null && echo "Created testuser2" || echo "testuser2 already exists"
useradd -m testuser3 2>/dev/null && echo "Created testuser3" || echo "testuser3 already exists"


# ---- Step 2: Create 2 groups ----
echo ""
echo "--- Creating groups ---"

groupadd team-alpha 2>/dev/null && echo "Created team-alpha" || echo "team-alpha already exists"
groupadd team-beta  2>/dev/null && echo "Created team-beta"  || echo "team-beta already exists"


# ---- Step 3: Add users to groups ----
echo ""
echo "--- Assigning users to groups ---"

# team-alpha gets ALL 3 users
usermod -aG team-alpha testuser1
usermod -aG team-alpha testuser2
usermod -aG team-alpha testuser3
echo "team-alpha members: testuser1, testuser2, testuser3"

# team-beta gets only 2 users
usermod -aG team-beta testuser1
usermod -aG team-beta testuser2
echo "team-beta members:  testuser1, testuser2"


# ---- Step 4: Verify with id ----
echo ""
echo "--- Verifying membership (id USER) ---"

echo ""
echo "testuser1:"; id testuser1
echo ""
echo "testuser2:"; id testuser2
echo ""
echo "testuser3:"; id testuser3


# ---- Step 5: Create directories with group ownership ----
echo ""
echo "--- Creating directories ---"

mkdir -p /home/$CALLER/team-alpha-dir
mkdir -p /home/$CALLER/team-beta-dir

# We are the owner, group owner is the respective group
chown $CALLER:team-alpha /home/$CALLER/team-alpha-dir
chown $CALLER:team-beta  /home/$CALLER/team-beta-dir


# ---- Step 6: Set permissions 775 ----
echo ""
echo "--- Setting chmod 775 ---"

chmod 775 /home/$CALLER/team-alpha-dir
chmod 775 /home/$CALLER/team-beta-dir

echo "Result:"
ls -ld /home/$CALLER/team-alpha-dir /home/$CALLER/team-beta-dir


# ---- Step 7: How to switch users ----
echo ""
echo "--- Ways to log in as another user ---"
echo ""
echo "  su - testuser1              # switch user (needs testuser1's password)"
echo "  sudo su - testuser1         # switch user via root (needs your password)"
echo "  sudo -u testuser1 -i        # open login shell as testuser1"
echo "  sudo -u testuser1 whoami    # run single command as testuser1"
echo ""
echo "Done!"
