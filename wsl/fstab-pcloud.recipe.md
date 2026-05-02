# Auto-mount pCloud (or any Windows drvfs drive) at WSL boot

## Why fstab over per-shell mount

WSL2 with `systemd=true` in `/etc/wsl.conf` honors `/etc/fstab` during boot. That makes the mount happen *before any user shell opens* — no sudo password prompt in the normal flow, no race between hidden and visible shells, no fragile orchestration.

`mount-pcloud.sh` is still useful for first-time setup (confirms pCloud is reachable, suggests the fstab entry, provides a manual remount fallback), but should not be the day-to-day mount mechanism.

## One-line setup

```bash
# Replace P with whatever drive letter your Windows app uses
echo 'P:\ /mnt/p drvfs defaults 0 0' | sudo tee -a /etc/fstab
sudo mount -a   # syntax check + mount now
mountpoint /mnt/p && echo "fstab works ✓"
```

## Prerequisites

- The Windows-side app (pCloud Drive, OneDrive, Google Drive Stream, etc.) **must be running before WSL starts**. Configure it to autostart at Windows login.
- `/etc/wsl.conf` should contain `[boot] systemd=true` (otherwise fstab handling is partial; varies by WSL build).

## Failure modes and recovery

| Symptom | Cause | Recovery |
|---|---|---|
| `/mnt/p` empty after WSL boot | Windows app not running yet | Start the app, then `sudo mount -a` (or rely on `bashrc-snippet.sh` fallback) |
| `mount: P:\ is not a block device` | Drive letter not assigned on Windows side | Re-check the app's drive letter setting; `gpedit` if needed |
| Mount unmounts after Docker Desktop init | Rare drvfs flake during heavy WSL re-init | Re-run `sudo mount -a` |

The fallback in `bashrc-snippet.sh` runs a one-shot `sudo mount` per shell if the mountpoint is missing — so the only time you ever see a sudo password prompt is when the Windows app wasn't ready at WSL boot. Edge case in normal usage.

## Pairing with `bashrc-snippet.sh`

Once the fstab entry is in place, the `bashrc-snippet.sh` block becomes:
- **Mount fallback** (rarely fires, only on edge cases)
- **Lock'd background bootstrap** (the actual orchestration value: kafka, digest, whatever your project needs)

That separation is the key: mount uses Linux's proven boot-time mechanism (fstab); orchestration uses our shell-level lock. No collision, no race, no architecture fragility.
