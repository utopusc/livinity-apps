#!/bin/bash
# Clean up Chrome state for reliable restart
# Runs via linuxserver's /custom-cont-init.d/ mechanism before Chrome launches
# Supports both Google Chrome and Chromium profile paths

# Detect profile directory (Chrome vs Chromium)
if [ -d "/config/.config/google-chrome" ]; then
  BROWSER_DIR="/config/.config/google-chrome"
elif [ -d "/config/.config/chromium" ]; then
  BROWSER_DIR="/config/.config/chromium"
else
  echo "[startup-cleanup] No browser profile found yet (first run)"
  exit 0
fi

PROFILE_DIR="$BROWSER_DIR/Default"

# Remove stale lock files that prevent startup after crashes
for lockfile in SingletonLock SingletonSocket SingletonCookie; do
  if [ -e "$BROWSER_DIR/$lockfile" ]; then
    rm -f "$BROWSER_DIR/$lockfile"
    echo "[startup-cleanup] Removed stale $lockfile"
  fi
done

# Patch Preferences to prevent "didn't shut down correctly" bar
# and force session restore so tabs always come back.
if [ -f "$PROFILE_DIR/Preferences" ]; then
  python3 -c "
import json, sys

PROFILE = '$PROFILE_DIR'

def patch_prefs(path):
    with open(path) as f:
        p = json.load(f)
    p.setdefault('session', {})['restore_on_startup'] = 1
    p.setdefault('profile', {}).update({'exit_type': 'Normal', 'exited_cleanly': True})
    with open(path, 'w') as f:
        json.dump(p, f, separators=(',', ':'))

try:
    patch_prefs(PROFILE + '/Preferences')
    print('[startup-cleanup] Preferences patched: session restore + clean exit')
except Exception as e:
    print(f'[startup-cleanup] Warning: {e}', file=sys.stderr)
" 2>&1
fi

echo "[startup-cleanup] Browser startup cleanup complete"
