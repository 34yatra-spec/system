# First Setup / Restart Guide — HyperFrames Reel Toolchain

**For opencode:** After a Kaggle restart, read this file and follow the **"After restart"** section. Do not run `npx hyperframes` (it re-downloads); use the persisted wrapper instead.

**The reel is already completed and rendered.** Setup only restores the toolchain for future use. Do not rebuild, check, or render unless the user explicitly asks.

---

## 1. What this folder contains

```
/kaggle/working/tools/
├── firstsetup.md          # this file
├── bootstrap.sh           # sets PATH, Chrome path, cache; installs missing libs
├── hf.sh                  # wrapper: bootstraps, then runs hyperframes
├── node22/                # Node v22.14.0 (192 MB)
├── chrome/                # Chrome Headless Shell 152.0.7977.30 (261 MB)
└── hf/node_modules/       # hyperframes 0.8.214 + dependencies (118 MB)
```

Total ~571 MB. Versions are pinned; do not upgrade unless the project needs it.

Project:
```
/kaggle/working/productions/reels/planet-sabotage/
├── index.html
├── compositions/scene-01.html ... scene-32.html
├── assets/fonts/NotoSansDevanagari-800.woff2
├── assets/hi-voice.wav
├── tools/build.py               # generates all scenes + index + cues
├── tools/render.sh              # bootstrap + build + render
├── tools/full-run.sh            # bootstrap + build + check + render
└── renders/planet-sabotage-v2.mp4
```

Input source (persistent dataset): `/kaggle/input/datasets/yatra1/audiok/hi-voice.wav`

---

## 2. After restart — setup only (~10 s; render optional)

Run once per session:

```bash
source /kaggle/working/tools/bootstrap.sh
```

Expected output:

```
[hf] node v22.14.0 | hyperframes 0.8.214 | chrome /kaggle/working/tools/chrome/.../chrome-headless-shell
```

`bootstrap.sh` also restores execute bits on Node and Chrome, and recreates the
`.bin/hyperframes` symlink if a Kaggle save/restore dropped them. If the version
prints empty or Node prints v20, re-run `source /kaggle/working/tools/bootstrap.sh`.

Then verify:

```bash
which node            # /kaggle/working/tools/node22/bin/node
which hyperframes     # /kaggle/working/tools/hf/node_modules/.bin/hyperframes
hyperframes --version # 0.8.214
ldd "$HYPERFRAMES_BROWSER_PATH" | grep 'not found' || echo "chrome libs OK"
```

If `chrome libs OK`, nothing else is needed. If libraries are missing, `bootstrap.sh` already tried `apt-get`; check network and re-run it.

**Setup time only (no build/render):** ~10 seconds on a warm image; ~40–60 seconds if the Chrome `.so` packages must be installed. No downloads are needed because Node, HyperFrames, and Chrome are already in `/kaggle/working/tools`.

### Render

Fast path (build + render, ~3 min):

```bash
cd /kaggle/working/productions/reels/planet-sabotage
bash tools/render.sh
```

With QA check (build + check + render, ~6 min):

```bash
cd /kaggle/working/productions/reels/planet-sabotage
bash tools/full-run.sh
```

Output: `renders/planet-sabotage-final.mp4`

### No manual bootstrap

The wrapper bootstraps itself:

```bash
/kaggle/working/tools/hf.sh render -o renders/final.mp4 -q delivery -w 4
/kaggle/working/tools/hf.sh check --json
```

Important: `/kaggle/working/tools/hf` is a **directory** (node_modules), so the executable wrapper is **`hf.sh`**, not `hf`.

---

## 3. If `/kaggle/working/tools` is missing

That means the session did not restore `/kaggle/working`. Either:

1. Re-open the **committed (Save Version)** notebook that contains this output, or
2. Attach the tools as a **Kaggle Dataset** and use:

```bash
export HF_TOOLS=/kaggle/input/<your-dataset>/tools
source "$HF_TOOLS/bootstrap.sh"
```

If neither exists, do the cold install below (~20 min).

---

## 4. Cold install from scratch (only if tools are gone)

```bash
export PATH=/usr/bin:/bin:$PATH
mkdir -p /kaggle/working/tools
cd /kaggle/working/tools

# Node 22
curl -fsSLo node22.tar.xz https://nodejs.org/dist/v22.14.0/node-v22.14.0-linux-x64.tar.xz
tar -xf node22.tar.xz
mv node-v22.14.0-linux-x64 node22
export PATH=/kaggle/working/tools/node22/bin:$PATH
node -v    # v22.14.0

# HyperFrames CLI (local, pinned)
mkdir -p hf
npm install --prefix /kaggle/working/tools/hf hyperframes@0.8.214
export PATH=/kaggle/working/tools/hf/node_modules/.bin:$PATH
hyperframes --version    # 0.8.214

# Chrome Headless Shell (downloads to /root/.cache, then copy into tools)
hyperframes browser ensure
cp -a /root/.cache/hyperframes/chrome /kaggle/working/tools/chrome
export HYPERFRAMES_BROWSER_PATH="$(find /kaggle/working/tools/chrome -type f -name chrome-headless-shell | head -n1)"

# Chrome shared libraries
apt-get update -qq
apt-get install -y -qq libatk1.0-0 libatk-bridge2.0-0 libatspi2.0-0 libxcomposite1

ldd "$HYPERFRAMES_BROWSER_PATH" | grep 'not found' || echo "chrome libs OK"
```

Then re-create the wrapper files (`bootstrap.sh`, `hf.sh`) — copy them from the committed notebook/dataset, or from section 5 below.

Cold install time: ~20 minutes.

---

## 5. Wrapper contents (for recovery)

`bootstrap.sh`:

```bash
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
```

`hf.sh`:

```bash
#!/usr/bin/env bash
set -e
source /kaggle/working/tools/bootstrap.sh >/dev/null 2>&1
exec hyperframes "$@"
```

---

## 6. Rebuild the reel (project-specific)

```bash
cd /kaggle/working/productions/reels/planet-sabotage
source /kaggle/working/tools/bootstrap.sh
python3 tools/build.py          # regenerates index.html + 32 scenes + cues.json
hyperframes check --json        # expect ok: true
hyperframes render -o renders/planet-sabotage-final.mp4 -q delivery -w 4
```

Verified output spec: 1080x1920, 30 fps, 48.5 s, H.264 + AAC stereo, ~10 MB.

If `assets/hi-voice.wav` or the fonts are missing:

```bash
cp /kaggle/input/datasets/yatra1/audiok/hi-voice.wav assets/hi-voice.wav
```

Fonts are already in `assets/fonts/` (persist with the project).

---

## 7. Timings

| Task | Time |
|---|---|
| Bootstrap (warm image) | ~10 s |
| Bootstrap + apt libs (fresh image) | ~40–60 s |
| Build (32 scenes) | <1 s |
| Check | ~2–3 min |
| Snapshot (15 frames) | ~1–2 min |
| Render 48.5 s reel | 2 min 21 s |
| **Restart → final video (render only)** | **~3 min** |
| **Restart → final video (check + render)** | **~6 min** |
| Cold install (tools missing) | ~20 min |

---

## 8. Persistence rules

- `/kaggle/working` survives a **kernel restart in the same session**.
- It does **not** survive a new notebook / Factory reset unless you **Save Version** (commit) or store tools as a **Kaggle Dataset**.
- `/tmp`, `/root`, `/usr`, and exported shell variables are always lost.
- Do not install anything into `/tmp` or `/root` for reuse.
- Keep the final MP4 in `renders/`; it is only ~10 MB.

---

## 9. Troubleshooting

| Symptom | Fix |
|---|---|
| `hyperframes: command not found` | `source /kaggle/working/tools/bootstrap.sh` |
| `node: Permission denied` or `chrome-headless-shell: Permission denied` | re-run `source /kaggle/working/tools/bootstrap.sh`; it restores execute bits |
| `hyperframes --version` prints empty | `.bin/hyperframes` is missing or not executable; re-run `bootstrap.sh` to recreate the symlink |
| `chrome-headless-shell: cannot open shared object file` | `apt-get install -y libatk1.0-0 libatk-bridge2.0-0 libatspi2.0-0 libxcomposite1` |
| `Target closed` / Chrome crash | verify `HYPERFRAMES_BROWSER_PATH` points to an executable; run `ldd ... | grep 'not found'` |
| `GSAP target not found` | scene HTML IDs changed; rebuild with `python3 tools/build.py` |
| `content_overlap` error | check `tools/build.py` positions for that scene; re-run `hyperframes check` |
| Devanagari shows boxes | ensure `assets/fonts/*.woff2` exists and scene CSS points to it |
| Render hangs | use `-w 4` (4 CPUs); software GPU is expected |
| `npx hyperframes` slow | use `/kaggle/working/tools/hf.sh` instead |
| `/kaggle/working/tools/hf` is a directory | use `hf.sh` |

---

## 10. One-line instruction to give opencode after restart (setup only)

> Read `/kaggle/working/tools/firstsetup.md` and follow only the "After restart" setup steps. Do not rebuild, check, or render — the reel is already completed.
