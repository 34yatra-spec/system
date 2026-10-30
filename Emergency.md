# Emergency — full system rebuild (interactive)

**Use when:** brand-new Kaggle account, `/kaggle/working` lost/broken, or a full
reinstall. For a normal restart, use `Firststartup.md` instead.

> opencode is the operator and runs this file. It must **never install/reinstall
> opencode**, and must **never clone `gemini-rotation-gateway`** (that repo is a
> backup only; the Worker is already deployed).

Canonical root: `/kaggle/working`. Result must match the known-good system here:
opencode config + Transient bound + skills + Node 22.14.0 + HyperFrames 0.8.214 +
Chrome + libs + ffmpeg + Python libs, and (if requested) reels.

## HARD STOP — ask first, install later

Before cloning or installing anything, ask the human **all at once** and wait:

1. Is opencode already installed/running? (if no → human installs manually; stop)
2. Is `GITHUB_TOKEN` set in Kaggle Secrets? (private clone needs it)
3. Clone **reels**? (`system` is already present — this file lives there)
4. Is the toolchain blank (no `/kaggle/working/tools/node22`)? A cold install is
   ~20 min — proceed now or skip?
5. Does this reel need link download (`yt-dlp`) and gateway voice (`WORKER_TOKEN`)?

Do not proceed until answered. Never print or log secrets.

## 1. Verify prerequisites

```bash
test -d /kaggle/working/system || echo "system repo missing"
export GH_TOKEN="$GITHUB_TOKEN"   # read Kaggle Secret; never echo
gh auth status >/dev/null 2>&1 || echo "gh not authenticated"
```

## 2. Clone (only with permission)

```bash
# system is already here; clone only if missing
[ -d /kaggle/working/system ] || gh repo clone 34yatra-spec/system /kaggle/working/system

# reels only if approved
[ -d /kaggle/working/reels ] || gh repo clone 34yatra-spec/reels /kaggle/working/reels
```

**Never clone `gemini-rotation-gateway`.**

## 3. Install system

```bash
bash /kaggle/working/system/install.sh
```

This copies `opencode/`, `Transient/` (+ AGENTS bind), `skills/`, `tools/`,
docs and `GeminiAPI.md` into `/kaggle/working`, relinks the opencode config, and
ensures the toolchain (cold install if blank, else `source bootstrap.sh`).
It must end with `[system] OK`.

## 4. Install reels (only if cloned)

```bash
bash /kaggle/working/reels/install.sh
```

Sources the toolchain, installs `yt-dlp` if missing, and checks the template,
fonts and gateway. Must end with `[reels] OK`.

## 5. Final readiness gate

```bash
bash /kaggle/working/system/verify.sh
```

Must print `[verify] OK`. It covers: config links, Transient bind, skills,
Node 22.14.0, HyperFrames 0.8.214, Chrome + shared libs, ffmpeg/ffprobe, Python
libs. If anything says `MISS`, report it and stop — do not claim ready.

## 6. Report

```text
Ready: system installed, toolchain OK, Transient bound, skills OK, reels OK, gateway reachable.
```

Then follow `reels/ReelProcedure.md`.

## Adding a future repo

Each repo ships its own idempotent `install.sh` that ends with `[<name>] OK`.
Add exactly one line here, in dependency order:

```bash
bash /kaggle/working/<repo>/install.sh
```

No other change to Emergency is needed.
