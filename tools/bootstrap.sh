#!/usr/bin/env bash
# Persistent HyperFrames toolchain bootstrap.
# Usage: source /kaggle/working/tools/bootstrap.sh
export HF_TOOLS="${HF_TOOLS:-/kaggle/working/tools}"
export PATH="$HF_TOOLS/node22/bin:$HF_TOOLS/hf/node_modules/.bin:$PATH"

# Kaggle save/restore can drop execute bits and .bin symlinks. Restore them first.
chmod +x "$HF_TOOLS/node22/bin/node" 2>/dev/null || true
if [ -z "${HYPERFRAMES_BROWSER_PATH:-}" ]; then
  HYPERFRAMES_BROWSER_PATH="$(find "$HF_TOOLS/chrome" -type f -name chrome-headless-shell 2>/dev/null | head -n1)"
  export HYPERFRAMES_BROWSER_PATH
fi
chmod +x "$HYPERFRAMES_BROWSER_PATH" 2>/dev/null || true
BIN="$HF_TOOLS/hf/node_modules/.bin"
HF_BIN="$HF_TOOLS/hf/node_modules/hyperframes/bin/hyperframes.mjs"
HF_FONT_BIN="$HF_TOOLS/hf/node_modules/hyperframes/bin/hyperframes-localize-fonts.mjs"
if [ -f "$HF_BIN" ]; then
  chmod +x "$HF_BIN" 2>/dev/null || true
  if [ ! -x "$BIN/hyperframes" ]; then
    mkdir -p "$BIN"
    ln -sf ../hyperframes/bin/hyperframes.mjs "$BIN/hyperframes"
  fi
fi
if [ -f "$HF_FONT_BIN" ]; then
  chmod +x "$HF_FONT_BIN" 2>/dev/null || true
  if [ ! -x "$BIN/hyperframes-localize-fonts" ]; then
    mkdir -p "$BIN"
    ln -sf ../hyperframes/bin/hyperframes-localize-fonts.mjs "$BIN/hyperframes-localize-fonts"
  fi
fi

export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HF_TOOLS/.cache}"
mkdir -p "$XDG_CACHE_HOME"

if [ -x "$HYPERFRAMES_BROWSER_PATH" ] && ldd "$HYPERFRAMES_BROWSER_PATH" 2>/dev/null | grep -q "not found"; then
  echo "[hf] installing missing Chrome shared libraries"
  apt-get update -qq >/dev/null 2>&1 || true
  apt-get install -y -qq libatk1.0-0 libatk-bridge2.0-0 libatspi2.0-0 libxcomposite1 >/dev/null 2>&1 || true
fi
hash -r
echo "[hf] node $(node -v 2>/dev/null) | hyperframes $(hyperframes --version 2>/dev/null) | chrome $HYPERFRAMES_BROWSER_PATH"
