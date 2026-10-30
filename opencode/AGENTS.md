# Persistent OpenCode Rules (Kaggle)

## Transient (rules only, no UI)

- Transient is installed at `/kaggle/working/Transient`.
- Read `/kaggle/working/Transient/AGENTS.snippet.md` for routine work.
- Read `/kaggle/working/Transient/transient.md` before substantial work.
- Rules-only install: do not start the voice UI (`ui/start.sh`) unless the user asks.
- Keep records in `Transient/decisions.md`, `goals.md`, `blockers.md`, `checkpoints.md`.

## Gemini Gateway

- For all LLM / TTS / STT / Live work, use the Gemini Gateway.
- Read `/kaggle/working/GeminiAPI.md` before calling it.
- Base URL: `https://gemini-gateway.31yatra.workers.dev`
- Bearer token: Kaggle Secret `WORKER_TOKEN`. Never print or log the token.
- Reel narration / voiceover: `POST /v1/tts` with `{"text":"...","voice":"Charon"}`, save response as `.wav`; report `x-gw-model` and `x-gw-project`.
- Captions / transcription: `POST /v1/stt` with the audio file.
- Scripts / text: `POST /v1/llm` with `prompt` or `messages`.
- On `503 all_exhausted`, read `error.attempts` and retry with another model or wait.
