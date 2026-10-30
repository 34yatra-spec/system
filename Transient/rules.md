# Rules

Status: 1 rule set recorded (reel work).

- This file holds authoritative project rules.
- Master reference is `Transient/transient.md`.
- Update only on meaningful change.

## Reel work

- For any reel, follow `/kaggle/working/reels/ReelProcedure.md` (name: **RP-1**).
- Do not use `PIPELINE.md` (legacy) unless the user explicitly asks.
- If the user gives a link: download it, transcribe it, then write an improved script.
- Voice: Gemini Gateway TTS (default male `Charon`).
- Timing: silence-split + Gemini chunk-STT. Do not use Whisper for Hindi.
- If the user gives no scene cards: run the master prompt at
  `/kaggle/working/reels/ReelMasterprompt.md` with the extracted script.
- If the user gives scene cards or a storyboard: use them; do not rewrite the story.
- Report a timing table at the end.
