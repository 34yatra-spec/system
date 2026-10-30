# Blockers

Status: 1 blocker recorded.

- Date: — issue: — cause: — recovery: — avoid-repeat:
- Core file. Record useful failures only.

## Whisper small for Hindi word timing

- Date: 2026-10-29
- Issue: `hyperframes transcribe -l hi -m small` took 8m43 and returned corrupted word times (one word spanned 27 s).
- Cause: Whisper `small` Hindi accuracy and JSON output were not reliable for this clip.
- Recovery: silence-split with ffmpeg, then Gemini `/v1/stt?lang=hi` per chunk; align script words to chunks.
- Avoid-repeat: do not use Whisper for Hindi timing. Use the chunk-STT method.
