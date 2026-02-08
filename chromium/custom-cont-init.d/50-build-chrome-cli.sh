#!/bin/bash
# Dynamically assemble CHROME_CLI from base flags + optional proxy
# Runs via linuxserver's /custom-cont-init.d/ mechanism

# --- Profile migration ---
# Chrome 144+ requires a non-default --user-data-dir for remote debugging.
# Default is $HOME/.config/google-chrome (/config/.config/google-chrome).
# We use /config/chrome-data instead.
CHROME_DATA="/config/chrome-data"

if [ -d "/config/.config/google-chrome" ] && [ ! -d "$CHROME_DATA" ]; then
  mv /config/.config/google-chrome "$CHROME_DATA"
  echo "[chrome-cli] Migrated profile to $CHROME_DATA"
fi
mkdir -p "$CHROME_DATA"
chown -R abc:abc "$CHROME_DATA"

# --- Patch wrapped-chrome to use non-default user-data-dir ---
# The base image's wrapped-chrome uses --user-data-dir (empty = default),
# which blocks remote debugging in Chrome 144+.
cat > /usr/bin/wrapped-chrome << 'WRAPPER'
#!/bin/bash
BIN=/usr/bin/google-chrome
CHROME_DATA="/config/chrome-data"
if which pgrep > /dev/null 2>&1 && pgrep chrome > /dev/null 2>&1; then
  rm -f "$CHROME_DATA"/Singleton*
fi
${BIN} \
  --no-first-run \
  --no-sandbox \
  --password-store=basic \
  --simulate-outdated-no-au='Tue, 31 Dec 2099 23:59:59 GMT' \
  --start-maximized \
  --test-type \
  --user-data-dir="$CHROME_DATA" \
   "$@" > /dev/null 2>&1
WRAPPER
chmod +x /usr/bin/wrapped-chrome
echo "[chrome-cli] Patched wrapped-chrome with user-data-dir=$CHROME_DATA"

# --- Fix autostart for Chrome (migrating from Chromium) ---
AUTOSTART="/config/.config/openbox/autostart"
if [ -f "$AUTOSTART" ] && grep -q 'wrapped-chromium' "$AUTOSTART"; then
  sed -i 's/wrapped-chromium/wrapped-chrome/g' "$AUTOSTART"
  echo "[chrome-cli] Fixed autostart: wrapped-chromium -> wrapped-chrome"
fi

# --- Assemble CHROME_CLI flags ---
BASE_FLAGS="--remote-debugging-port=9222 --remote-allow-origins=* --restore-last-session --disable-dev-shm-usage"

FINAL_FLAGS="$BASE_FLAGS"

if [ -n "$PROXY_URL" ]; then
  FINAL_FLAGS="$FINAL_FLAGS --proxy-server=$PROXY_URL"
  FINAL_FLAGS="$FINAL_FLAGS --proxy-bypass-list=localhost;127.0.0.1;*.local"

  # For SOCKS5, prevent DNS leaks
  if echo "$PROXY_URL" | grep -qi "^socks5://"; then
    PROXY_HOST=$(echo "$PROXY_URL" | sed 's|socks5://||i' | cut -d: -f1)
    FINAL_FLAGS="$FINAL_FLAGS --host-resolver-rules=MAP * ~NOTFOUND , EXCLUDE $PROXY_HOST"
  fi

  echo "[chrome-cli] Proxy enabled: $PROXY_URL"
else
  echo "[chrome-cli] No proxy configured"
fi

# Write assembled CHROME_CLI for s6-overlay to pick up
printf "%s" "$FINAL_FLAGS" > /run/s6/container_environment/CHROME_CLI
echo "[chrome-cli] CHROME_CLI assembled: $FINAL_FLAGS"
