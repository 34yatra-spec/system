# Checkpoints

Status: checkpoint-1 recorded.

- Format: `checkpoint-N` (N = next sequence number).
- Entry: date, stable state, changed files, return path, verify result.
- Inspect existing entries before you create a new one.
- Do not invent a checkpoint that was not created or verified.

## checkpoint-1

- Date: 2026-10-29
- Stable state: Reel 02 "Shani ka daur" built and rendered.
- Files: `/kaggle/working/productions/reels/shani-ka-daur/` (23 scenes, `index.html`, `beats.json`, `assets/hi-voice.wav`, `renders/shani-ka-daur-final.mp4`), `/kaggle/working/productions/reels/shani-ka-daur/lessons learnt.md`.
- Return path: re-run `bash tools/render.sh` in the project folder.
- Verify: `hyperframes check --json` -> ok true; MP4 1080x1920, 30 fps, 56.17 s, H.264 + AAC stereo.

## checkpoint-2

- Date: 2026-10-29
- Stable state: named reel pipeline RP-1 documented.
- Files: `/kaggle/working/reels/ReelProcedure.md`,
  `/kaggle/working/reels/ReelMasterprompt.md`,
  `/kaggle/working/Transient/rules.md`.
- Return path: read `REEL-PROCEDURE.md` and run its stages.
- Verify: files exist; RP-1 names the stages, guardrails, and master-prompt path.

## checkpoint-3

- Date: 2026-10-30
- Stable state: Reel 03 v2 "वही इंसान" (paper-cut, 24 scenes) rendered and verified.
- Files: `/kaggle/working/productions/reels/wahi-insaan-papercut/renders/wahi-insaan-papercut-final.mp4`,
  `tools/build.py`, `tools/prep_assets.py`, `assets/ASSETS.md`.
- Fixes this round: S24 endplate hardcoded "हर" removed; endcard now holds the full
  closing line; final scene extended to root duration (no black tail); captions use a
  fixed balanced line split + `fitPlate()` so text never reflows as words appear;
  S22 camera pan removed (it exposed the frame edge); caption highlight softened.
- Return path: `python3 tools/build.py` then `hyperframes render . -f 30 -q delivery -o renders/wahi-insaan-papercut-final.mp4`.
- Verify: `hyperframes check` -> 0 errors; MP4 1080x1920, 30 fps, 58.4 s, H.264 High + AAC 48k stereo, no black segments.
