#!/bin/bash
# Clean up Chromium state for reliable restart
# Runs via linuxserver's /custom-cont-init.d/ mechanism before Chromium launches

CHROMIUM_DIR="/config/.config/chromium"
PROFILE_DIR="$CHROMIUM_DIR/Default"

# Remove stale lock files that prevent startup after crashes
if [ -d "$CHROMIUM_DIR" ]; then
  for lockfile in SingletonLock SingletonSocket SingletonCookie; do
    if [ -e "$CHROMIUM_DIR/$lockfile" ]; then
      rm -f "$CHROMIUM_DIR/$lockfile"
      echo "[startup-cleanup] Removed stale $lockfile"
    fi
  done
fi

# Force clean exit state + session restore so Chrome never shows
# "restore pages?" prompt or "didn't shut down correctly" bar
if [ -f "$PROFILE_DIR/Preferences" ]; then
  python3 -c "
import json, sys
try:
    with open('$PROFILE_DIR/Preferences') as f:
        p = json.load(f)
    p.setdefault('session', {})['restore_on_startup'] = 1
    p.setdefault('profile', {}).update({'exit_type': 'Normal', 'exited_cleanly': True})
    with open('$PROFILE_DIR/Preferences', 'w') as f:
        json.dump(p, f)
    print('[startup-cleanup] Session restore enabled, clean exit set')
except Exception as e:
    print(f'[startup-cleanup] Warning: could not patch Preferences: {e}', file=sys.stderr)
" 2>&1
fi

echo "[startup-cleanup] Chromium startup cleanup complete"
