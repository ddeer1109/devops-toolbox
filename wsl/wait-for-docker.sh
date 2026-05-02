#!/usr/bin/env bash
# Block until Docker engine is reachable, or fail after a timeout.
# On WSL2 the engine usually comes from Docker Desktop on Windows side, which
# may not be running yet when WSL boots — hence the wait+retry loop.
#
# Usage: ./wait-for-docker.sh
#
# Env overrides:
#   MAX_WAIT_S   total seconds to wait before giving up (default 300)
#   INTERVAL_S   poll interval (default 5)

set -u

MAX_WAIT_S="${MAX_WAIT_S:-300}"
INTERVAL_S="${INTERVAL_S:-5}"

elapsed=0
while ! docker info >/dev/null 2>&1; do
    if [ "$elapsed" -ge "$MAX_WAIT_S" ]; then
        echo "wait-for-docker: timeout after ${MAX_WAIT_S}s — Docker engine not reachable" >&2
        echo "  hint: open Docker Desktop on Windows, or check 'docker context ls'" >&2
        exit 1
    fi
    if [ "$elapsed" -eq 0 ]; then
        echo "wait-for-docker: docker not ready yet, polling every ${INTERVAL_S}s (max ${MAX_WAIT_S}s)..."
    fi
    sleep "$INTERVAL_S"
    elapsed=$((elapsed + INTERVAL_S))
done

echo "wait-for-docker: docker is up (waited ${elapsed}s)"
