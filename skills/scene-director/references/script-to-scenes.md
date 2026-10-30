# Script to Scenes

How a finished script (with or without a radio-mode voice audio) becomes directed scenes, written fast by reusing what HyperFrames already ships. The person's words are the material; directing decides only how they are seen and heard. Examples of the finished pattern live in a built project (an `<audio>` with `data-duration`, a `cues.json`) — mirror its wiring shape.

## 1. The audio is the timeline

When a radio-mode audio is in hand, the film is built around it, never around an invented length:

- The audio element is the clock: `<audio id="voice" class="clip" src="assets/voice.wav" data-start="0" data-duration="<measured>">`. Measure the file's real duration once and use it everywhere; the root's `data-duration` covers the full audio plus the end card's hold. Never trim, speed up or pad the voice.
- One sentence (or sense-group) of the script is one scene: a line spoken is a picture acting out its meaning in the same seconds. Scene boundaries are the sentence boundaries, not arbitrary half-filled times.
- Word timings come from the Cloudflare Workers AI whisper API access the person provides (`word_timestamps: true`): word starts and ends feed the cue map — every cut, reveal and key action lands on the word that causes it, and `cues.json` records them; aim for 0 ms drift between what is said and what is seen. The returned transcript doubles as a sync check: where it disagrees with the script, the audio is the truth and the script is flagged back. Fallbacks in order: `/media-use` transcribe, then reading the script at the audio's pace. Captions are the script's own words, verbatim, timed to the voice (hold rules in `craft.md` §1); on-screen titles quote the script, never paraphrase it into marketing copy.
- A sentence with no visual in the script (an abstract claim) gets its picture from the subject's own material — the product's screen, real data, the brand's shapes — never a generic floating-text default (`story.md` §8).

When there is a script but no audio yet, the treatment and cue map still come first; the voice recording or TTS plan is then made to fit the grid, not the reverse.

## 2. Deriving the scenes

For each script line, in order, write one row before writing any markup:

| # | Script line | What the viewer sees while they hear it | Camera move | Blocks / preset used | Other assets |

- **What they see** performs the line: the metaphor made literal, the number earned on screen, the before failing, the after arriving. Directing bar: a stranger watching with the sound off still gets the line.
- **Camera moves** come from `craft.md` §3 (at least four across the film; one signature shot).
- **Blocks / preset** is filled in step 3 below — a named preset treatment or a catalog item, not "custom", whenever one fits.
- The treatment holds all of this as its shot list; the cue map marks which beat of which section each scene starts on.

## 3. How to write each scene (so it does not take forever)

Never hand-write from a blank page what HyperFrames already ships. Work down this ladder; write markup only at the last rung.

1. **Search the catalog for the move the shot needs** (`/hyperframes-registry`):
   - `npx hyperframes catalog --query "reveal a headline one line at a time"` — always describe the move in English, whatever the video's language is; with `--json` to see which tier ranked.
   - Nothing fits — report the miss (`npx hyperframes feedback --search-miss` or the `report_gap` line the command prints) and only then go on.
   - Install what fits: `npx hyperframes add <name>`; tighten path and timing to the cue map (root-relative `assets/…` paths, `data-start`/`data-duration` from the treatment).
2. **Ride a frame preset for the look.** `assets/frame-presets/<name>/` (inside the hyperframes skill) ships 13+ design systems; each preset's `FRAME.md` defines the palette, type ramp (in `cqw`), components and frame treatments (cover, stat grid, quote, timeline, closing…), and its folder has `caption-skin.html` and a `frame-showcase.html` with working markup to copy from. Pick one preset for the whole film and stay inside its laws (its borders, shadows, type ramp, palette); make the ground cycle across scenes its rhythm. The script supplies the numbers — a preset never invents figures: empty slots stay `{metric}` until the script gives the value.
3. **Compose from the preset's components + the installed blocks.** Wire them into the scene file: styles, markup and script inside `<template>`, root as `#root`, one scene per sub-composition, timed elements written in the HTML each with a stable `id`, `data-track-kind="graphics"` on scene hosts. `data-beat` marks the cue-map hit each scene lands on.
4. **Hand-write only the glue**: the tweens that make the scene's own camera move, the transitions inside the medium (`craft.md` §3–4), and whatever no block or preset supplies. This is the only genuinely authored code in the film, and the treatment's shot list says what each tween must do.
5. **Check** (`npx hyperframes check --json`) and snapshot (`npx hyperframes snapshot --review`) per `/hyperframes`; the review compares each beat frame to its shot-list row (`checks.md` §1).

Scene-writing time stays short because rungs 1–2 are reusable, typed compositions; the per-scene cost is choosing and timing them, not typing CSS from nothing.

## 4. The immersive bar (directing like the top tier)

A scene that merely illustrates its line is surface level. The bar:

- **Depth on every frame**: a foreground, a subject plane and a ground layer, moving at different rates (parallax); shadows and scale that place things in space, not flat cards on a void. The subject fills at least a third of the frame at key moments.
- **The camera is always working with a reason**: pushes that carry focus, pulls that reveal scale, match cuts between worlds (`craft.md` §3). A static frame with sliding text is a default, on the BANNED line.
- **Sound locks the picture**: every action on screen has its foley on the beat (`treatment.md` §7); the picture starts on the voice's inflection, not after it.
- **One native move** the medium can only do here — an object that becomes the next scene, text that turns into the mechanism it names — placed at the line that matters most.
- **No thin defaults anywhere**: no centered paragraph over gradient, no glowing headline, no icons-and-cards row, no stage of untouched catalog blocks stuck in three slots in a row (`story.md` §8). If two adjacent scenes both come straight out of a preset's showcase, one of them gets an authored twist from the subject.
