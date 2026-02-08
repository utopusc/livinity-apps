#!/bin/bash
# Dynamically assemble CHROME_CLI from base flags + optional proxy
# Runs via linuxserver's /custom-cont-init.d/ mechanism

BASE_FLAGS="--remote-debugging-port=9222 --remote-debugging-address=0.0.0.0 --remote-allow-origins=* --restore-last-session --disable-blink-features=AutomationControlled --disable-infobars --disable-dev-shm-usage"

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
