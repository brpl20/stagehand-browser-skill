#!/usr/bin/env bash
# Dedicated, persistent Chrome profile for agent browsing.
# Log in once (headed), and every later session reuses the same cookies.
#   bash chrome-profile.sh start [--headless]   # launch (no-op if already running)
#   bash chrome-profile.sh stop | status | port | dir
# Then drive it with: browse <cmd> --cdp "$(bash chrome-profile.sh port)"
set -euo pipefail

PROFILE_DIR="${STAGEHAND_PROFILE_DIR:-$HOME/.local/share/stagehand-browser/profile}"
PORT="${STAGEHAND_CDP_PORT:-9333}"
PID_FILE="$PROFILE_DIR.pid"
LOG_FILE="$PROFILE_DIR.log"
STAGEHAND_EXT_ID="${STAGEHAND_EXT_ID:-ddoefcfipmeidbjoigecmohplkncjmni}"

find_chrome() {
  if [[ -n "${CHROME_PATH:-}" ]]; then echo "$CHROME_PATH"; return; fi
  local c
  for c in \
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
    "/Applications/Chromium.app/Contents/MacOS/Chromium" \
    "$(command -v google-chrome-stable 2>/dev/null || true)" \
    "$(command -v google-chrome 2>/dev/null || true)" \
    "$(command -v chromium 2>/dev/null || true)" \
    "$(command -v chromium-browser 2>/dev/null || true)"; do
    [[ -n "$c" && -x "$c" ]] && { echo "$c"; return; }
  done
  echo "Chrome not found; set CHROME_PATH" >&2; exit 1
}

running() { curl -fs "http://127.0.0.1:$PORT/json/version" >/dev/null 2>&1; }

case "${1:-status}" in
  start)
    if running; then echo "running on port $PORT ($PROFILE_DIR)"; exit 0; fi
    mkdir -p "$PROFILE_DIR"; chmod 700 "$PROFILE_DIR"
    headless=()
    [[ "${2:-}" == "--headless" ]] && headless=(--headless=new)
    # Stagehand loads its runtime extension over CDP (needs unsafe-extension-debugging),
    # and that extension dials back into CDP, so allow only its origin (never "*").
    detach=(nohup); command -v setsid >/dev/null && detach=(setsid nohup)
    "${detach[@]}" "$(find_chrome)" \
      --user-data-dir="$PROFILE_DIR" \
      --remote-debugging-port="$PORT" \
      --remote-debugging-address=127.0.0.1 \
      --enable-unsafe-extension-debugging \
      --remote-allow-origins="chrome-extension://$STAGEHAND_EXT_ID" \
      --no-first-run --no-default-browser-check \
      "${headless[@]}" about:blank >"$LOG_FILE" 2>&1 </dev/null &
    echo $! >"$PID_FILE"
    for _ in $(seq 1 40); do running && { echo "started on port $PORT ($PROFILE_DIR)"; exit 0; }; sleep 0.25; done
    echo "Chrome did not open port $PORT; see $LOG_FILE" >&2; exit 1 ;;
  stop)
    if [[ -f "$PID_FILE" ]]; then kill "$(cat "$PID_FILE")" 2>/dev/null || true; rm -f "$PID_FILE"; fi
    pkill -f -- "--user-data-dir=$PROFILE_DIR" 2>/dev/null || true
    echo "stopped" ;;
  status) running && echo "running on port $PORT" || { echo "not running"; exit 1; } ;;
  port) echo "$PORT" ;;
  dir) echo "$PROFILE_DIR" ;;
  *) echo "usage: $0 start [--headless] | stop | status | port | dir" >&2; exit 2 ;;
esac
