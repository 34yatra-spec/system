# AGENTS

## Transient (rules only, no UI)

<!-- TRANSIENT-INCLUDE-START -->
See Transient/AGENTS.snippet.md. Full rules in Transient/transient.md.
<!-- TRANSIENT-INCLUDE-END -->

- Transient lives at `/kaggle/working/Transient`.
- Read `Transient/AGENTS.snippet.md` for routine work.
- Read `Transient/transient.md` before substantial work.
- Do not start the voice UI (`Transient/ui/start.sh`) unless the user explicitly asks.
- Keep records in `Transient/decisions.md`, `goals.md`, `blockers.md`, `checkpoints.md`.

## Gemini Gateway

- For all LLM / TTS / STT / Live work, use the Gemini Gateway.
- Read `/kaggle/working/GeminiAPI.md` before calling it.
- Base URL: `https://gemini-gateway.31yatra.workers.dev`
- Bearer token: Kaggle Secret `WORKER_TOKEN` (never print or log it).
- Reel narration / voiceover: `POST /v1/tts` with `{"text":"...","voice":"Charon"}`, save response as `.wav`; report `x-gw-model` and `x-gw-project`.
- Captions / transcription: `POST /v1/stt` with the audio file.
- Scripts / text: `POST /v1/llm` with `prompt` or `messages`.
- On `503 all_exhausted`, read `error.attempts` and retry with another model or wait.
