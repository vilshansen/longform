#!/usr/bin/env bash
# Runs scripts/check-index.ps1. Works from Git-Bash on Windows and WSL.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PS1="$SCRIPT_DIR/check-index.ps1"

if command -v powershell.exe >/dev/null 2>&1; then
    # In WSL, /mnt/c/... paths must be translated to Windows paths.
    if [[ "$PS1" == /mnt/* ]] && command -v wslpath >/dev/null 2>&1; then
        PS1="$(wslpath -w "$PS1")"
    fi
    powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "$PS1"
else
    echo "pre-commit: powershell.exe not found; skipping index check" >&2
    exit 0
fi
