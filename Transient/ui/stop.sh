#!/usr/bin/env bash
# Stop the Transient voice companion UI.
set -euo pipefail
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
PIDFILE="$CONFIG_HOME/transient/ui.pid"
if [ -f "$PIDFILE" ]; then
  PID="$(cat "$PIDFILE")"
  if kill "$PID" 2>/dev/null; then echo "stopped pid $PID"; else echo "not running (pid $PID dead)"; fi
  rm -f "$PIDFILE"
else
  echo "no pid file — nothing to stop"
fi
