# Transient — Portable Setup

Fetch this folder, drop it in any project, run setup. No overwrite.

## Install from URL (ship-ready)

Host two files at one base URL: `transient.tar.gz` + `install.sh`.
Then on any studio:

```bash
# full: rules ON + voice companion UI (mic page + QR + session select)
curl -fsSL <BASE>/install.sh | bash -s -- --url <BASE>/transient.tar.gz

# traditional only: rules ON, no UI server
curl -fsSL <BASE>/install.sh | bash -s -- --url <BASE>/transient.tar.gz --no-ui

# system-wide ON (every opencode session on this box)
curl -fsSL <BASE>/install.sh | bash -s -- --url <BASE>/transient.tar.gz --global
```

Live base: `https://get-transient.netlify.app`.

## Voice companion UI

After install (without `--no-ui`), the UI is already running:

- Desktop: `http://127.0.0.1:17874/` — Cloudflare + client setup (collapses once
  saved), QR of the mobile URL, opencode session select, conversation log.
- Mobile (same Wi-Fi): scan the QR — big mic button, tap to talk, tap to stop.
  Voice goes STT → opencode session → answer returns on page and speaks via TTS.
- No Cloudflare creds? Works anyway: STT falls back to on-device browser voice,
  replies speak via built-in speech. Add creds later to use Workers AI
  (`@cf/openai/whisper-large-v3-turbo` STT, `@cf/deepgram/aura-1` TTS).
- Manual control: `bash Transient/ui/start.sh [--port N]`, `bash Transient/ui/stop.sh`.
- Creds file: `~/.config/transient/config.json` (0600). The API never returns the token.

Examples once hosted on GitHub raw:

```bash
curl -fsSL https://raw.githubusercontent.com/YOU/transient/main/install.sh \
  | bash -s -- --url https://github.com/YOU/transient/releases/download/v1/transient.tar.gz
```

What happens:
- Project: extracts `Transient/` into `.`, runs `Transient/setup.sh`. Wires
  `./AGENTS.md` with one marked block. Never touches other lines. Backup on change.
- Global: copies code to `~/.config/opencode/Transient/`, keeps your existing
  records, wires `~/.config/opencode/AGENTS.md`. OpenCode loads that file for
  every session (Rules > Global). That is the system ON switch.

Verify ON:
```bash
cat AGENTS.md                              # project
cat ~/.config/opencode/AGENTS.md           # global
ls Transient/ && bash Transient/setup.sh   # idempotent re-run is safe
```

Remove the wire (keep records): delete the `TRANSIENT-INCLUDE` block.

## Host it (where)

Pick one. GitHub is best for shipping.

1. **GitHub repo + release (recommended).** Free, stable URLs, versioned.
   ```bash
   cd <project-root>
   tar czf transient.tar.gz Transient/
   cp Transient/install.sh ./install.sh   # host a copy at repo root too
   gh repo create YOU/transient --public --source=. --push
   gh release create v1 transient.tar.gz install.sh --title v1 --notes "transient v1"
   # BASE = https://github.com/YOU/transient/releases/download/v1
   # or raw: https://raw.githubusercontent.com/YOU/transient/main/install.sh
   ```
2. **Cloudflare R2 public bucket.** Good if you already live on Cloudflare
   (you run transit workers). Upload both files, enable public read, use the
   `https://pub-xxx.r2.dev` base. Cheap, fast, no version UI.
3. **VPS / tunnel / workers static.** Works but avoid `trycloudflare.com`
   quick tunnels for shipping — the URL dies on reboot. Use a fixed
   `workers.dev` or custom domain.

Do not ship session exports. `Transient/full-sessions/FULL-*.md` stays local.
`.gitkeep` files keep empty dirs in git.

## Build the tarball

From the project root that holds `Transient/`:

```bash
tar czf transient.tar.gz Transient/
tar tzf transient.tar.gz | head
```

Paths stay relative. No absolute `/kaggle/` or `/teamspace/` paths.
