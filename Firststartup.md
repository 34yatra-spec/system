# Firststartup — checklist after every Kaggle restart

Read this at the start of every new opencode session after a restart, in order.
Do not skip step 1.

Kaggle erases `/root` on restart. Persistent data lives in `/kaggle/working/`.
Canonical opencode config: `/kaggle/working/opencode/`.

## 1. Relink opencode config (required)

```bash
bash /kaggle/working/opencode/Firststartup-relink.sh
```

Verify the links point into `/kaggle/working/opencode/`:

```bash
ls -l ~/.config/opencode/opencode.jsonc ~/.config/opencode/AGENTS.md
```

Expected targets:

- `~/.config/opencode/opencode.jsonc` → `/kaggle/working/opencode/opencode.jsonc`
- `~/.config/opencode/AGENTS.md` → `/kaggle/working/opencode/AGENTS.md`

If `opencode` is not on `PATH`, run `/kaggle/working/opencode/opencode`.

## 2. Transient rules (rules only, no UI)

Transient is at `/kaggle/working/Transient`.

- Routine work: read `Transient/AGENTS.snippet.md`.
- Before substantial work: read `Transient/transient.md`.
- Keep records in `decisions.md`, `goals.md`, `blockers.md`, `checkpoints.md`.
- **Do not start the voice UI** (`Transient/ui/start.sh`) unless explicitly asked.

If `Transient/` is missing, it is in this repo: re-run `Onetime-setup.sh`.

## 3. Toolchain (setup only, no rebuild/render)

```bash
source /kaggle/working/tools/bootstrap.sh
```

Expected:

```text
[hf] node v22.14.0 | hyperframes 0.8.214 | chrome /kaggle/working/tools/chrome/.../chrome-headless-shell
```

Verify:

```bash
node -v; hyperframes --version
ldd "$HYPERFRAMES_BROWSER_PATH" | grep 'not found' || echo "chrome libs OK"
```

- Do **not** rebuild, check or render unless explicitly asked.
- If `/kaggle/working/tools` has no `node22/`, `hf/`, `chrome/`, do the cold
  install in `Toolchain.md`.

## 4. Gemini Gateway

- Read `/kaggle/working/GeminiAPI.md` before calling it.
- Base URL: `https://gemini-gateway.31yatra.workers.dev`
- Bearer token: Kaggle Secret `WORKER_TOKEN`. Never print or log it.
- Voice: `POST /v1/tts` `{"text":"...","voice":"Charon"}` → save `.wav`; report
  `x-gw-model` and `x-gw-project`.
- Captions: `POST /v1/stt` with the audio file.
- Text: `POST /v1/llm` with `prompt` or `messages`.
- On `503 all_exhausted`, read `error.attempts`; retry another model or wait.

## 5. Verify and proceed

```bash
bash /kaggle/working/system/verify.sh
```

Must print `[verify] OK` (checks links, Transient bind, skills, Node, HyperFrames,
Chrome, ffmpeg, Python libs). Then report one line:

```text
Ready: config links OK, Transient rules ON (no UI), tools toolchain OK, Gemini API read.
```

Then continue. Do not print secrets. Transient is already installed/bound —
restart only verifies, never reinstalls.
