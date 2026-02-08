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

# Patch Preferences AND Secure Preferences to prevent "didn't shut down
# correctly" bar. Chrome writes exit_type=Crashed on start and Normal on
# clean shutdown. Container stops via SIGKILL leave it as Crashed.
# We also force restore_on_startup=1 so tabs always come back.
if [ -f "$PROFILE_DIR/Preferences" ]; then
  python3 -c "
import json, sys, hashlib, hmac

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

echo "[startup-cleanup] Chromium startup cleanup complete"
