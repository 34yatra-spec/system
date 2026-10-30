#!/usr/bin/env bash
set -euo pipefail

SRC="/kaggle/working/opencode"
DEST="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"

mkdir -p "$DEST"

link_one() {
  local name="$1"
  local target="$SRC/$name"
  local path="$DEST/$name"

  if [ ! -e "$target" ]; then
    echo "ERROR: missing persistent file: $target" >&2
    exit 1
  fi

  if [ -L "$path" ]; then
    rm -f "$path"
  elif [ -e "$path" ]; then
    local backup="${path}.bak.$(date +%s)"
    cp -a "$path" "$backup"
    rm -f "$path"
    echo "backed up: $path -> $backup"
  fi

  ln -s "$target" "$path"
  echo "linked: $path -> $target"
}

link_one opencode.jsonc
link_one AGENTS.md

if [ -e "$DEST/opencode.json" ] && [ ! -L "$DEST/opencode.json" ]; then
  backup="$DEST/opencode.json.bak.$(date +%s)"
  mv "$DEST/opencode.json" "$backup"
  echo "moved conflicting opencode.json -> $backup"
fi

echo "done. restart opencode to load the links."
