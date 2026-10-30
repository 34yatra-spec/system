# Decisions

Status: 3 decisions recorded.

- Date: — decision: — reason: — status: confirmed/proposed/superseded — evidence:
- Core file. Use dates for facts that can change.

## Reel 02 voice and timing

- Date: 2026-10-29
- Decision: use Gemini Gateway TTS voice `Charon` (male Hindi), one full-script request.
- Reason: user asked for male Hindi audio; Charon is the calm male voice.
- Status: confirmed
- Evidence: `renders/shani-ka-daur-final.mp4`, 56.17 s.

## Reel 02 word timing

- Date: 2026-10-29
- Decision: use Gemini chunk-STT + script-word alignment, not Whisper.
- Reason: Whisper small failed on Hindi; chunk-STT gave clean line boundaries.
- Status: confirmed
- Evidence: `beats.json`, `lessons learnt.md` section 3.

## Toolchain self-heal

- Date: 2026-10-29
- Decision: `tools/bootstrap.sh` restores execute bits and `.bin` symlinks on every source.
- Reason: Kaggle save/restore drops them; this caused `node v20` and an empty `hyperframes` version.
- Status: confirmed
- Evidence: bootstrap tested from a broken state; printed `node v22.14.0 | hyperframes 0.8.214`.

## Named reel pipeline RP-1

- Date: 2026-10-29
- Decision: name the reel procedure **RP-1** and store it at
  `/kaggle/working/reels/ReelProcedure.md`.
- Reason: the user wants a repeatable, named procedure that the agent remembers.
- Status: confirmed
- Evidence: `REEL-PROCEDURE.md`, `MASTERPROMPT.md`, `Transient/rules.md`.
