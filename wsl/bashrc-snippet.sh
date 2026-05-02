#!/usr/bin/env bash
# WSL bootstrap snippet — source from ~/.bashrc.
#
# Two responsibilities:
#   1. Inline mount of a Windows drive to /mnt/<letter> (e.g., pCloud at P: → /mnt/p).
#      Idempotent. Hidden shells without TTY fail sudo silently and exit fast,
#      so the user-visible terminal always gets the password prompt.
#      Recommendation: also add the same mount as an /etc/fstab entry. With
#      systemd=true in /etc/wsl.conf the mount happens at boot and this block
#      becomes a fallback for edge cases (e.g., the Windows app providing the
#      drive wasn't running when WSL booted).
#
#   2. Lock'd, background-detached invocation of a project-specific bootstrap
#      command. Runs once per WSL session, gated on the mount existing.
#      Uses /proc/1 mtime to detect stale locks from a previous WSL session
#      (since /tmp on WSL is ext4 by default, locks survive shutdown).
#
# Required env vars (set BEFORE sourcing):
#   WSL_BOOTSTRAP_VAULT_MOUNT  — mountpoint to gate bootstrap on (e.g., /mnt/p)
#   WSL_BOOTSTRAP_PROJECT_CMD  — command to run in background after mount confirmed
#
# Optional env vars:
#   WSL_BOOTSTRAP_DRIVE_LETTER — drive letter on Windows side (default: P)
#   WSL_BOOTSTRAP_LOG_HINT     — string included in the "starting in background"
#                                line so the user knows where logs land
#
# Example .bashrc usage:
#
#   export WSL_BOOTSTRAP_VAULT_MOUNT=/mnt/p
#   export WSL_BOOTSTRAP_PROJECT_CMD=~/work/my-pipeline/scripts/wsl_bootstrap.sh
#   export WSL_BOOTSTRAP_LOG_HINT="~/.local/state/wsl-bootstrap.log"
#   source ~/work/devops-toolbox/wsl/bashrc-snippet.sh
#   alias wsl-up='rm -rf /tmp/.wsl-bootstrap.lock; unset WSL_BOOTSTRAP_FIRED; eval "$WSL_BOOTSTRAP_PROJECT_CMD" &'

: "${WSL_BOOTSTRAP_VAULT_MOUNT:?must be set before sourcing bashrc-snippet.sh}"
: "${WSL_BOOTSTRAP_DRIVE_LETTER:=P}"

# 1. Mount fallback (fstab is the recommended primary; this catches edge cases).
if [ -d "$WSL_BOOTSTRAP_VAULT_MOUNT" ] && ! mountpoint -q "$WSL_BOOTSTRAP_VAULT_MOUNT" 2>/dev/null; then
    sudo mount -t drvfs "${WSL_BOOTSTRAP_DRIVE_LETTER}:" "$WSL_BOOTSTRAP_VAULT_MOUNT" 2>/dev/null && \
        echo "[wsl-bootstrap] mounted ${WSL_BOOTSTRAP_DRIVE_LETTER}: at $WSL_BOOTSTRAP_VAULT_MOUNT"
fi

# 2. Background project bootstrap (once per WSL session, gated on mount).
if [[ $- == *i* && -z "${WSL_BOOTSTRAP_FIRED:-}" ]] && \
   mountpoint -q "$WSL_BOOTSTRAP_VAULT_MOUNT" 2>/dev/null && \
   [[ -n "${WSL_BOOTSTRAP_PROJECT_CMD:-}" ]]; then
    _wsl_lock=/tmp/.wsl-bootstrap.lock
    if [[ -e "$_wsl_lock" ]] && \
       (( $(stat -c %Y "$_wsl_lock" 2>/dev/null || echo 0) < $(stat -c %Y /proc/1) )); then
        rm -rf "$_wsl_lock"
    fi
    if mkdir "$_wsl_lock" 2>/dev/null; then
        export WSL_BOOTSTRAP_FIRED=1
        nohup bash -c "$WSL_BOOTSTRAP_PROJECT_CMD" >/dev/null 2>&1 &
        disown
        echo "[wsl-bootstrap] project bootstrap starting in background${WSL_BOOTSTRAP_LOG_HINT:+ (log: $WSL_BOOTSTRAP_LOG_HINT)}"
    fi
    unset _wsl_lock
fi
