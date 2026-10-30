#!/usr/bin/env bash
# Cold install of the HyperFrames toolchain (blank machine only).
set -euo pipefail

export PATH=/usr/bin:/bin:$PATH
WORK="${WORK:-/kaggle/working}"
T="$WORK/tools"

mkdir -p "$T"
cd "$T"

if [ ! -x "$T/node22/bin/node" ]; then
  echo "[toolchain] Node 22.14.0"
  curl -fsSLo node22.tar.xz https://nodejs.org/dist/v22.14.0/node-v22.14.0-linux-x64.tar.xz
  tar -xf node22.tar.xz
  rm -rf "$T/node22"
  mv node-v22.14.0-linux-x64 "$T/node22"
  rm -f node22.tar.xz
fi
export PATH="$T/node22/bin:$PATH"

if [ ! -d "$T/hf/node_modules" ]; then
  echo "[toolchain] HyperFrames 0.8.214"
  mkdir -p "$T/hf"
  npm install --prefix "$T/hf" hyperframes@0.8.214
fi
export PATH="$T/hf/node_modules/.bin:$PATH"

if [ -z "$(find "$T/chrome" -type f -name chrome-headless-shell 2>/dev/null | head -n1)" ]; then
  echo "[toolchain] Chrome Headless Shell"
  hyperframes browser ensure
  rm -rf "$T/chrome"
  cp -a /root/.cache/hyperframes/chrome "$T/chrome"
fi

echo "[toolchain] Chrome shared libraries"
apt-get update -qq >/dev/null 2>&1 || true
apt-get install -y -qq libatk1.0-0 libatk-bridge2.0-0 libatspi2.0-0 libxcomposite1 >/dev/null 2>&1 || true

bash "$T/bootstrap.sh"
echo "[toolchain] OK"
