# Toolchain — HyperFrames reel toolchain

Full detail lives in `tools/firstsetup.md`. This file is the short version.

Pinned versions (see `versions.env`):

- Node 22.14.0
- HyperFrames 0.8.214
- Chrome Headless Shell 152.0.7977.30

Toolchain root: `/kaggle/working/tools` (binaries are **not** in git).

## After restart (setup only, ~10 s)

```bash
source /kaggle/working/tools/bootstrap.sh
```

Expected:

```text
[hf] node v22.14.0 | hyperframes 0.8.214 | chrome /kaggle/working/tools/chrome/.../chrome-headless-shell
```

`bootstrap.sh` self-heals the lost execute bits and the `hyperframes` symlink
that Kaggle save/restore can drop.

## Cold install (only if `/kaggle/working/tools` is missing)

```bash
mkdir -p /kaggle/working/tools
cd /kaggle/working/tools

curl -fsSLo node22.tar.xz https://nodejs.org/dist/v22.14.0/node-v22.14.0-linux-x64.tar.xz
tar -xf node22.tar.xz && mv node-v22.14.0-linux-x64 node22

export PATH="/kaggle/working/tools/node22/bin:$PATH"
npm install --prefix /kaggle/working/tools/hf hyperframes@0.8.214

npx --prefix /kaggle/working/tools/hf @puppeteer/browsers install \
  chrome-headless-shell@152.0.7977.30 --path /kaggle/working/tools/chrome/.cache
cp -a /kaggle/working/tools/chrome/.cache/* /kaggle/working/tools/chrome/
```

Then `source /kaggle/working/tools/bootstrap.sh`. See `tools/firstsetup.md` §4
for the exact Chrome download/copy steps and shared-library install
(`libatk1.0-0 libatk-bridge2.0-0 libatspi2.0-0 libxcomposite1`).

## Verify

```bash
node -v                          # v22.14.0
hyperframes --version            # 0.8.214
ldd "$HYPERFRAMES_BROWSER_PATH" | grep 'not found' || echo "chrome libs OK"
```

## Troubleshooting

| Symptom | Fix |
|---|---|
| `hyperframes --version` empty | re-source `bootstrap.sh` (it recreates `.bin/hyperframes`) |
| `node` is v20 | toolchain not sourced; `source /kaggle/working/tools/bootstrap.sh` |
| Chrome libs missing | `bootstrap.sh` talks to `apt-get`; see §4 of `firstsetup.md` |
| `tools/` empty after restore | cold install above |

## Persistence rule

`tools/` must live under `/kaggle/working` (persistent). Never rebuild/render
unless asked. Replaces nothing in `reels`; the reels repo consumes this toolchain.
