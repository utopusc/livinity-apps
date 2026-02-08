#!/bin/bash
# Remove stale Chromium lock files that prevent startup after crashes
# Runs via linuxserver's /custom-cont-init.d/ mechanism before Chromium launches

CHROMIUM_DIR="/config/.config/chromium/Default"

if [ -d "$CHROMIUM_DIR" ]; then
  for lockfile in SingletonLock SingletonSocket SingletonCookie; do
    if [ -e "$CHROMIUM_DIR/../$lockfile" ]; then
      rm -f "$CHROMIUM_DIR/../$lockfile"
      echo "[clean-singletonlock] Removed stale $lockfile"
    fi
  done
fi

echo "[clean-singletonlock] Chromium lock cleanup complete"
