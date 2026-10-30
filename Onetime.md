# Onetime — first-time setup

Use this once per Kaggle account (or after a total reset). After that, read
`Firststartup.md` at the start of every session following a restart.

Canonical root: `/kaggle/working`. Everything installs into that root.
opencode is the operator: it runs the steps below. It must **never install
opencode** (the human does that) and **never clone `gemini-rotation-gateway`**.

## 0. Prerequisites (human)

- **opencode installed manually** (your step). Keep it at
  `/kaggle/working/opencode/opencode` or on `PATH`.
- **Kaggle Secrets** (Add-ons → Secrets):

  | Secret | Used for |
  |---|---|
  | `GITHUB_TOKEN` | clone/push private repos (**required** for clone) |
  | `WORKER_TOKEN` | Gemini Gateway auth |
  | `CLOUDFLARE_ACCOUNT_ID` | gateway deploy only (optional) |
  | `CLOUDFLARE_API_TOKEN` | gateway deploy only (optional) |
  | `GEMINI_KEY_PROJ_A` | gateway worker secret (optional) |
  | `GEMINI_KEY_PROJ_B` | gateway worker secret (optional) |

  Never commit `.env` or any token.

## 1. Clone this repo (private → token)

```bash
export GH_TOKEN="$GITHUB_TOKEN"        # Kaggle Secret; never echo
gh repo clone 34yatra-spec/system /kaggle/working/system
```

## 2. Install the system

```bash
bash /kaggle/working/system/install.sh
```

Copies `opencode/`, `Transient/` (+ AGENTS bind), `skills/`, `tools/`, docs and
`GeminiAPI.md` into `/kaggle/working`; relinks the opencode config; ensures the
toolchain (cold install if blank, else `source bootstrap.sh`); runs the verify
gate. Must end with `[system] OK`.

## 3. Transient (rules only)

`install.sh` copies `Transient/` and binds `AGENTS.md`. Confirm:

```bash
grep -n "TRANSIENT-INCLUDE" /kaggle/working/AGENTS.md
```

If `/kaggle/working/Transient` is missing, install rules-only from the official URL:

```bash
cd /kaggle/working && \
curl -fsSL https://get-transient.netlify.app/install.sh | bash -s -- \
  --url https://get-transient.netlify.app/transient.tar.gz \
  --dir /kaggle/working --no-ui
```

Then re-bind: `bash /kaggle/working/Transient/setup.sh`.
Do **not** start the voice UI (`Transient/ui/start.sh`) unless asked.

## 4. Toolchain

`install.sh` already did this. Full detail is in `Toolchain.md`
(first time = cold install; later restarts = only `source bootstrap.sh`).

## 5. Gateway

Read `GeminiAPI.md` (usage only). The Worker is already deployed; do not redeploy.
Token = Kaggle Secret `WORKER_TOKEN`.
The `gemini-rotation-gateway` repo is a **backup only** — do not clone it.

## 6. Reels (optional, separate repo)

```bash
export GH_TOKEN="$GITHUB_TOKEN"
gh repo clone 34yatra-spec/reels /kaggle/working/reels
bash /kaggle/working/reels/install.sh
```

## 7. Verify

```bash
bash /kaggle/working/system/verify.sh
```

Must print `[verify] OK`. Expected final line:

```text
Ready: system installed, toolchain OK, Transient bound, skills OK, reels OK, gateway reachable.
```

## Repos

- `system` — this repo (opencode, Transient, skills, toolchain, docs).
- `reels` — RP-1 reel production (cloned only when making reels).
- `gemini-rotation-gateway` — Worker source **backup only, never cloned**.
