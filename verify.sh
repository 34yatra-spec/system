#!/usr/bin/env bash
# Readiness gate. Prints OK/MISS per check; exits non-zero if anything is missing.
set -uo pipefail

WORK="${WORK:-/kaggle/working}"
fail=0

if [ -f "$WORK/tools/bootstrap.sh" ]; then
  source "$WORK/tools/bootstrap.sh" >/dev/null 2>&1 || true
fi

chk() {
  local label="$1"; shift
  if "$@" >/dev/null 2>&1; then
    echo "  OK   $label"
  else
    echo "  MISS $label"
    fail=1
  fi
}

echo "[verify] system"
chk "opencode config jsonc" test -e "$WORK/opencode/opencode.jsonc"
chk "opencode rules"        test -e "$WORK/opencode/AGENTS.md"
chk "Transient bind"        grep -q "TRANSIENT-INCLUDE" "$WORK/AGENTS.md"
chk "skill scene-director"  test -f "$WORK/skills/scene-director/SKILL.md"
chk "skill hyperframes"     test -f "$WORK/skills/hyperframes/skills/hyperframes/SKILL.md"
chk "node 22.14.0"          bash -c 'node -v 2>/dev/null | grep -q v22.14.0'
chk "hyperframes 0.8.214"   bash -c 'hyperframes --version 2>/dev/null | grep -q 0.8.214'
chk "chrome browser"        bash -c 'test -n "${HYPERFRAMES_BROWSER_PATH:-}" && test -x "$HYPERFRAMES_BROWSER_PATH"'
chk "chrome libs"           bash -c '! ldd "$HYPERFRAMES_BROWSER_PATH" 2>/dev/null | grep -q "not found"'
chk "ffmpeg"                command -v ffmpeg
chk "ffprobe"               command -v ffprobe
chk "python libs"           python3 -c 'import numpy, PIL, scipy, requests, soundfile, soxr'

if [ "$fail" -ne 0 ]; then
  echo "[verify] MISSING items above"
  exit 1
fi
echo "[verify] OK"
