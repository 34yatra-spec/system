#!/usr/bin/env bash
# Start the Transient voice companion UI. Idempotent.
# Usage: bash Transient/ui/start.sh [--port N] [--host 0.0.0.0]
# Prints the desktop URL + mobile URL. Verifies with /api/health.
set -euo pipefail

PORT="${TRANSIENT_UI_PORT:-17874}"
HOST="0.0.0.0"
for a in "$@"; do
  case "$a" in
    --port) shift; PORT="${1:-17874}";;
    --port=*) PORT="${a#--port=}";;
    --host) shift; HOST="${1:-0.0.0.0}";;
    --host=*) HOST="${a#--host=}";;
  esac
  shift 2>/dev/null || true
done

if [ -d "Transient/ui" ]; then UI_DIR="Transient/ui"; ROOT="."
elif [ -f "server.py" ]; then UI_DIR="."; ROOT=".."; else
  echo "ERROR: run as: bash Transient/ui/start.sh" >&2; exit 1
fi

CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
mkdir -p "$CONFIG_HOME/transient"

free_port() {
  local p="$1"
  for _ in $(seq 0 20); do
    if ! (exec 3<>/dev/tcp/127.0.0.1/$p) 2>/dev/null; then echo "$p"; return; fi
    exec 3>&- 2>/dev/null || true
    p=$((p+1))
  done
  echo "$1"
}
PORT="$(free_port "$PORT")"

# already running on this port?
if curl -fsS --max-time 3 "http://127.0.0.1:$PORT/api/health" >/dev/null 2>&1; then
  echo "already running on $PORT"
else
  # server.py writes its own pidfile (shell $! is unreliable under nohup)
  nohup python3 "$UI_DIR/server.py" --host "$HOST" --port "$PORT" \
    --pidfile "$CONFIG_HOME/transient/ui.pid" >"$CONFIG_HOME/transient/ui.log" 2>&1 &
  sleep 1
fi

OK=0
for _ in $(seq 1 15); do
  if curl -fsS --max-time 3 "http://127.0.0.1:$PORT/api/health" >/dev/null 2>&1; then OK=1; break; fi
  sleep 1
done
if [ "$OK" -ne 1 ]; then
  echo "ERROR: UI did not answer on $PORT. See $CONFIG_HOME/transient/ui.log" >&2
  tail -n 20 "$CONFIG_HOME/transient/ui.log" >&2 || true
  exit 1
fi

LAN="$(python3 -c "import socket;s=socket.socket(socket.AF_INET,socket.SOCK_DGRAM);s.settimeout(2)
try:
 s.connect(('8.8.8.8',80));print(s.getsockname()[0])
except Exception:
 print('127.0.0.1')" 2>/dev/null || echo 127.0.0.1)"
CLIENT="$(python3 -c "import json,os;from pathlib import Path;p=Path(os.environ.get('XDG_CONFIG_HOME',str(Path.home()/'.config')))/'transient/config.json'
try: print(json.loads(p.read_text()).get('clientId',''))
except Exception: print('')" 2>/dev/null || true)"
MOB="http://$LAN:$PORT/?role=mobile"; [ -n "$CLIENT" ] && MOB="$MOB&client=$CLIENT"
printf '{"port":%s,"pid":%s,"url":"http://127.0.0.1:%s/","lan":"http://%s:%s/","mobile": "%s"}\n' \
  "$PORT" "$(cat "$CONFIG_HOME/transient/ui.pid" 2>/dev/null || echo 0)" "$PORT" "$LAN" "$PORT" "$MOB" > "$CONFIG_HOME/transient/ui.json"

echo "ON  desktop: http://127.0.0.1:$PORT/"
echo "ON  mobile:  $MOB"
echo "(same Wi-Fi; scan the QR on the desktop page)"
