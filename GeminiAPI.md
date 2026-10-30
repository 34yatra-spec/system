# Gemini API — How to use (RP-1)

> Read this before calling the gateway. Reel procedure uses three endpoints:
> `/v1/llm` (stage 2 script + stage 5 scene cards), `/v1/tts` (stage 3 voice),
> `/v1/stt` (stage 4 transcription).

The gateway is **already deployed**:

```
BASE = https://gemini-gateway.31yatra.workers.dev
TOKEN = <WORKER_TOKEN>   # Kaggle Secret WORKER_TOKEN se aata hai
```

Header on every call except health:

```
Authorization: Bearer $TOKEN
content-type: application/json
```

---

## 1. LLM — POST /v1/llm

Body (either `prompt` or `messages`):

```json
{
  "prompt": "...",
  "system": "...",
  "maxTokens": 200,
  "temperature": 0.7,
  "model": "auto"
}
```

Success:

```json
{ "text": "...", "usage": {...}, "model": "...", "project": "...", "tier": 2 }
```

RP-1 uses this for stage 2 (script) and stage 5 (scene cards via `ReelMasterprompt.md`).

---

## 2. TTS — POST /v1/tts

```json
{
  "text": "...",
  "voice": "Charon",
  "style": "<delivery direction>"
}
```

Response: raw WAV bytes (`audio/wav`). Save as `assets/hi-voice.wav`.

Rules (RP-1): one request for whole script; 2 takes; duration 56.0–59.5 s; 48 kHz mono; first word within 0.1 s.

---

## 3. STT — POST /v1/stt

```bash
curl -s -X POST "$BASE/v1/stt?lang=hi" \
  -H "Authorization: Bearer $TOKEN" \
  -H "content-type: audio/wav" \
  --data-binary @audio/source.wav
```

Audio ≤ 20 MB. Response: `{ "text": "..." }`. RP-1 does chunk-STT + script alignment (not Whisper).

---

## 4. Discovery and status

```bash
curl -s -H "Authorization: Bearer $TOKEN" "$BASE/v1/capabilities"
curl -s -H "Authorization: Bearer $TOKEN" "$BASE/v1/status"
curl -s -H "Authorization: Bearer $TOKEN" "$BASE/v1/health"
```

---

## 5. Error format

```json
{ "error": { "code": "...", "message": "...", "attempts": [...] } }
```

Common: `401 unauthorized` (token galat), `503 all_exhausted` (quota/cooldown — wait or pin another model), `413 too_large` (audio > 20 MB).

---

**Not in this doc:** Worker deploy/secrets config (that lives in the `gemini-gateway` repo). This file is usage-only for reel making.
