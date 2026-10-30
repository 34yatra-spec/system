#!/usr/bin/env bash
# Transient installer — fetch from URL and turn ON.
# Project (default): installs Transient/ into current project, wires ./AGENTS.md,
#   then starts the voice companion UI (mic page + QR + session select) unless --no-ui.
# Global (--global): installs to ~/.config/opencode/Transient, wires global AGENTS.md,
#   then starts the UI unless --no-ui.
# Traditional only (no UI server): pass --no-ui.
#
# Usage:
#   curl -fsSL <BASE>/install.sh | bash -s -- --url <BASE>/transient.tar.gz
#   curl -fsSL <BASE>/install.sh | bash -s -- --url <BASE>/transient.tar.gz --no-ui
#   curl -fsSL <BASE>/install.sh | bash -s -- --url <BASE>/transient.tar.gz --global --ui-port 17874
#   bash Transient/install.sh --url ./transient.tar.gz --dir /tmp/demo-proj --no-ui
#
# Env:
#   TRANSIENT_URL  tarball URL (or local path). Flag --url wins.
#   TRANSIENT_DIR_NAME  default: Transient
#   TRANSIENT_UI_PORT   default: 17874. Flag --ui-port wins.
set -euo pipefail

URL="${TRANSIENT_URL:-}"
DIR="."
GLOBAL=0
YES=0
NO_UI=0
UI_PORT="${TRANSIENT_UI_PORT:-17874}"
DIR_NAME="${TRANSIENT_DIR_NAME:-Transient}"

while [ $# -gt 0 ]; do
  case "$1" in
    --url) URL="${2:-}"; shift 2;;
    --url=*) URL="${1#--url=}"; shift;;
    --dir) DIR="${2:-.}"; shift 2;;
    --dir=*) DIR="${1#--dir=}"; shift;;
    --global) GLOBAL=1; shift;;
    --no-ui) NO_UI=1; shift;;
    --ui-port) UI_PORT="${2:-17874}"; shift 2;;
    --ui-port=*) UI_PORT="${1#--ui-port=}"; shift;;
    --yes|-y) YES=1; shift;;
    --help|-h)
      sed -n '1,20p' "$0"
      exit 0;;
    *) echo "unknown arg: $1 (see --help)" >&2; exit 1;;
  esac
done

if [ -z "$URL" ]; then
  echo "ERROR: set tarball URL via --url <url> or TRANSIENT_URL=<url>" >&2
  echo "Example: curl -fsSL https://get-transient.netlify.app/install.sh | bash -s -- --url https://get-transient.netlify.app/transient.tar.gz" >&2
  exit 1
fi

need() { command -v "$1" >/dev/null 2>&1 || { echo "ERROR: need $1" >&2; exit 1; }; }
need curl; need tar; need bash

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
TARBALL="$TMP/transient.tar.gz"

echo "fetch: $URL"
if [ -f "$URL" ]; then
  cp "$URL" "$TARBALL"
else
  curl -fsSL --retry 3 --max-time 60 "$URL" -o "$TARBALL"
fi

if ! tar tzf "$TARBALL" >/dev/null 2>&1; then
  echo "ERROR: not a valid gzip tarball: $URL" >&2
  exit 1
fi

start_ui() {
  # $1 = Transient dir holding ui/start.sh (project root uses relative, global uses absolute DEST)
  local tdir="$1"
  if [ "$NO_UI" -eq 1 ]; then
    echo "UI skipped (--no-ui). Traditional install only."
    return 0
  fi
  need python3
  if [ -f "$tdir/ui/start.sh" ]; then
    TRANSIENT_UI_PORT="$UI_PORT" bash "$tdir/ui/start.sh" || {
      echo "WARN: UI failed to start. Rules still ON. Retry: TRANSIENT_UI_PORT=$UI_PORT bash $tdir/ui/start.sh" >&2
    }
  else
    echo "WARN: no ui/start.sh in tarball — rules ON, voice UI unavailable." >&2
  fi
}

if [ "$GLOBAL" -eq 1 ]; then
  # System ON: Transient lives in global config, global AGENTS.md points at it.
  # OpenCode loads ~/.config/opencode/AGENTS.md for every session (docs: Rules > Global).
  CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
  DEST="$CONFIG_HOME/opencode/$DIR_NAME"
  mkdir -p "$DEST"
  tar xzf "$TARBALL" -C "$TMP"
  # tarball holds top-level Transient/; sync contents into DEST without wiping user notes
  if [ -d "$TMP/$DIR_NAME" ]; then SRC="$TMP/$DIR_NAME"; else SRC="$TMP"; fi
  # copy missing only for records; always refresh code (setup.sh, tools, ui, snippet, docs)
  mkdir -p "$DEST/full-sessions" "$DEST/refined-sessions" "$DEST/away-sessions" "$DEST/consult"
  cp -f "$SRC/transient.md" "$SRC/AGENTS.snippet.md" "$SRC/setup.sh" "$SRC/install.sh" "$SRC/README.md" "$SRC/opencode-export-full-session.md" "$DEST/" 2>/dev/null || true
  if [ -d "$SRC/tools" ]; then mkdir -p "$DEST/tools"; cp -f "$SRC/tools/"* "$DEST/tools/" 2>/dev/null || true; fi
  if [ -d "$SRC/ui" ]; then mkdir -p "$DEST/ui"; cp -rf "$SRC/ui/." "$DEST/ui/" 2>/dev/null || true; fi
  for f in rules.md dictionary.md desires.md goals.md decisions.md project-timeline.md blockers.md checkpoints.md super-refined.md; do
    [ -f "$DEST/$f" ] || cp "$SRC/$f" "$DEST/" 2>/dev/null || true
  done
  chmod +x "$DEST/setup.sh" "$DEST/install.sh" "$DEST/ui/start.sh" "$DEST/ui/stop.sh" "$DEST/ui/server.py" 2>/dev/null || true
  AGENTS_FILE="$CONFIG_HOME/opencode/AGENTS.md"
  MARK="TRANSIENT-INCLUDE-START"
  mkdir -p "$(dirname "$AGENTS_FILE")"
  if [ ! -f "$AGENTS_FILE" ]; then
    printf "# AGENTS (global)\n\n<!-- %s -->\nTransient is ON system-wide. Read %s/transient.md before substantial work. Short entry: %s/AGENTS.snippet.md.\n<!-- TRANSIENT-INCLUDE-END -->\n" "$MARK" "$DEST" "$DEST" > "$AGENTS_FILE"
    echo "created $AGENTS_FILE"
  elif grep -q "$MARK" "$AGENTS_FILE"; then
    echo "global AGENTS.md already wired. No change."
  else
    cp "$AGENTS_FILE" "$AGENTS_FILE.bak-$(date +%Y%m%d-%H%M%S)"
    {
      echo ""
      echo "<!-- $MARK -->"
      echo "Transient is ON system-wide. Read $DEST/transient.md before substantial work. Short entry: $DEST/AGENTS.snippet.md."
      echo "<!-- TRANSIENT-INCLUDE-END -->"
    } >> "$AGENTS_FILE"
    echo "wired $AGENTS_FILE (backup made)."
  fi
  echo "ON (global). Transient at: $DEST"
  start_ui "$DEST"
  echo "Verify: cat $AGENTS_FILE"
  exit 0
fi

# Project mode
mkdir -p "$DIR"
tar xzf "$TARBALL" -C "$DIR"
echo "extracted to $DIR/$DIR_NAME"
if [ -f "$DIR/$DIR_NAME/setup.sh" ]; then
  (cd "$DIR" && bash "$DIR_NAME/setup.sh")
else
  echo "WARN: $DIR/$DIR_NAME/setup.sh missing. Tarball layout must hold top-level $DIR_NAME/." >&2
  exit 1
fi
echo "ON (project). Root: $DIR"
# Voice UI autostart (skip with --no-ui):
if [ "$NO_UI" -eq 1 ]; then
  echo "UI skipped (--no-ui). Traditional install only."
else
  (cd "$DIR" && TRANSIENT_UI_PORT="$UI_PORT" bash "$DIR_NAME/ui/start.sh") || {
    echo "WARN: UI failed to start. Rules still ON. Retry: (cd $DIR && TRANSIENT_UI_PORT=$UI_PORT bash $DIR_NAME/ui/start.sh)" >&2
  }
fi
