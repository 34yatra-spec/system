#!/usr/bin/env bash
# System installer — idempotent. Called by opencode (never installs opencode).
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK="${WORK:-/kaggle/working}"

echo "[system] installing into $WORK"

if ! command -v opencode >/dev/null 2>&1 && [ ! -x "$WORK/opencode/opencode" ]; then
  echo "STOP: opencode not found. The human installs opencode manually; this script never does." >&2
  exit 1
fi

mkdir -p "$WORK/opencode" "$WORK/skills" "$WORK/tools"

cp -a "$REPO/opencode/." "$WORK/opencode/"
cp -a "$REPO/Onetime.md" "$REPO/Firststartup.md" "$REPO/Toolchain.md" \
      "$REPO/Emergency.md" "$REPO/AGENTS.md" "$REPO/GeminiAPI.md" \
      "$REPO/verify.sh" "$WORK/"

if [ ! -d "$WORK/Transient" ]; then
  cp -a "$REPO/Transient" "$WORK/"
fi

cp -a "$REPO/skills/." "$WORK/skills/"
cp -a "$REPO/tools/." "$WORK/tools/"

if [ -f "$WORK/Transient/setup.sh" ]; then
  bash "$WORK/Transient/setup.sh" >/dev/null 2>&1 || true
fi

bash "$WORK/opencode/Firststartup-relink.sh"

if [ -x "$WORK/tools/node22/bin/node" ] && [ -d "$WORK/tools/hf/node_modules" ]; then
  source "$WORK/tools/bootstrap.sh"
else
  echo "[system] toolchain blank -> full install"
  bash "$WORK/tools/toolchain-install.sh"
  source "$WORK/tools/bootstrap.sh"
fi

bash "$REPO/verify.sh"
echo "[system] OK"
