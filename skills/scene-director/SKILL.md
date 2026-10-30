---
name: scene-director
description: Direct a HyperFrames video before building it. Use when making a film, explainer, promo, music video, data story or character piece of about 15 s or longer. Writes the story layer the person approves (STORYLINES.md → TREATMENT.md → SPEC.md) and holds the directing craft (benchmark, shot list, cue map, sound design, camera grammar, performance) until hyperframes check and review pass. Building, rendering and lint happen through /hyperframes; media and voice come from /media-use. Not for edits to an existing project's timing, captions or overlays.
---

# Scene Director

Directing only: the story, the shots, the rhythm, the sound plan and the checks. The picture is built by `/hyperframes` (render contract, `npx hyperframes`) from media found through `/media-use`. Skill mode: when this skill and the hyperframes skill are both present, follow this one for what happens **before** the first scene file is written, then hand over to `/hyperframes` for the build.

A film is judged in this order: **sound, rhythm, camera, directing**. Good-looking frames are only the starting point. Every timed element still obeys the HyperFrames contract (`class="clip"`, `data-start`, `data-duration`, registered timelines); nothing here changes it.

## The style is a decision, not a constant

No fixed style. For every film the director picks **one** preset from the 13 built-in frame presets (`/hyperframes` `assets/frame-presets/`), chosen by the speed-and-look rule: **what the code can build fastest that still looks finished**. The pick is recorded in one line in the spec, and the film never leaves that preset's laws — the moves (`craft.md`, `visual-moves.md`) vary between scenes, the style does not.

The pick weighs:

1. **Treatment coverage** — each preset ships 6 ready frame treatments (cover, stat grid, quote, timeline, closing…); choose the one whose treatments match the film's scene types best, so the most scenes come straight out of the showcase markup.
2. **Pure CSS wins** — every preset is CSS-only with no external imagery; prefer the ones that are fully CSS (borders, shadows, clip-paths, dot grids). Anything shader-, canvas- or 3D-flavoured costs build time and is chosen only when the script calls for it.
3. **Fonts** — a preset's display ramp sets its fonts; all are Google Fonts wired through `@font-face` in the build. Never swap preset fonts; that breaks the preset's fit-to-measure rules.
4. **Look on squint** — the preset's frame-showcase.html is rendered once early as the style proof: if it does not look good before any script content goes in, it never will with content; pick another. (This replaces the lemo-opuscar "prove the look" step — the preset's showcase is the style frame.)

Blueprint and lemo-opuscar styles are reference only, never defaults.

## Inputs

| The person gives | The spine |
| --- | --- |
| A finished script (text) | Direct the script: scenes are derived line by line (`/references/script-to-scenes.md`); nothing overrules the words, only how they are seen |
| A finished script plus a radio-mode audio (voice recording) | The audio is the timeline: its duration is the film's length, sentences are scenes, beats land on spoken words; the script supplies on-screen copy and the cue map |
| Only a topic or idea | Direct from scratch: storylines first (`story.md` §2), then the treatment; write the script as part of the treatment before any scene |
| A reference film or storyboard as well | Follow theirs; direct the craft around it, never its shots |

In every mode a top-tier immersive bar applies (`/references/script-to-scenes.md` §4): depth on every frame, the camera always in motion with a reason, sound locking the picture — no flat card slides, no surface-level narration with floating text.

## Workflow

0. **Text pass.** Before anything else, proofread the script and correct typos, number formats and units silently; fix the words, never the timings — an audio narration is never retimed or re-recorded to match a correction. Captions and on-screen text burn the corrected script only.
1. **Brief.** One round of questions, one message, everything HyperFrames' story step does not already fix: facts only they know, must-have shots, material they own (voice recording, music, logos, photos, data), length as a range, and every paid item with the free option beside it. Defaults: length 30–60 s for a film that tells something, 1920×1080 at 30 fps, language of their message. Skip what the request already answers; then no more questions — fill the rest with a stated assumption line.
2. **Actors.** The cast is a decision per script, never a fixed pattern (`/references/actors.md` §1): a hero actor, hero + supporting actor, or none — stamps and type carry it alone; cast whatever the script demands. Every cast actor gets choreography: **entry / action / exit written for every scene it touches**, word-locked to the cue map, exit velocity carrying into the next scene's cut (`actors.md` §2), presence-while-absence decided where it does not appear (§3).
2b. **Storylines, idea-only films only.** When no script exists, three different films, words only, per `/hyperframes` `references/story.md` §2; saved as `STORYLINES.md`, recommendation first, shown once. Script and reference-film modes skip this step entirely.
3. **Treatment.** Write `TREATMENT.md` before drawing or coding anything (`/references/treatment.md`): benchmark, logline and arc, shot list with a reason per shot, beat sheet, cue map, sound-design table. In script mode the "storyline" is the incoming script itself; its treatment records the *direction* of those words. A reference work is opened only to learn grammar, never to copy shots.
4. **Spec.** Fold every number into `SPEC.md` per `/hyperframes` `references/spec.md`: hard numbers, BANNED-by-default list, shots by frame. The treatment's shot list and the spec's numbers must agree; where they disagree, the spec wins.
5. **Storyboard: the build's source of truth.** From the scene sheet, the director writes the storyboard (`/hyperframes` `references/storyboard.md`): for every scene, **how it is rendered** (which preset treatments, which blocks, the layout) and **how the actions are performed** (the tween, the camera move from `/references/visual-moves.md`, the transition, the beat it lands on). The director shows it on request; for fast-cut reels a 4-frame phone sheet is the light version.
6. **Build** — the builder's job, execution only: + `npx hyperframes init`; scenes wired straight from the storyboard with `data-beat` marks on the cue-map hit points; hand-written code limited to what the storyboard's action notes name. Voice and music come from `/media-use`. The builder decides nothing about story, rhythm, look or motion: changes go back to the storyboard.
7. **Direct the review:** `npx hyperframes check --json`, then `references/review.md`, with the extra questions in `/references/checks.md` and the pacing log of `/references/visual-moves.md` §1. Fix in one round, re-check, write `REVIEW.md`.
8. **Deliver** (`/references/checks.md` §6): the film, `TREATMENT.md`, storyboard and spec kept in the project, `REVIEW.md`, and `CREDITS` when any outside asset was used.

## What to read

| The question | Read |
| --- | --- |
| Writing scenes from a script or radio audio, fast | `/references/script-to-scenes.md` |
| The visual moves cookbook (pacing numbers, hooks, objects, transitions) | `/references/visual-moves.md` |
| The actor layer: cast decision, entry/action/exit choreography | `/references/actors.md` |
| Sound, rhythm, camera, performance | `/references/craft.md` |
| Story, storylines (idea-only films), hook, beats | `/hyperframes` `references/story.md` |
| The failures to check for, anti-copy, credits | `/references/checks.md` |
| Storyboard format | `/hyperframes` `references/storyboard.md` |
| Building, rendering, the contract | `/hyperframes` `SKILL.md` and `references/format.md` |
| Captions, overlays, media and voice | `/hyperframes` `references/captions.md`, `overlays.md`; `/media-use` |

## Boundaries

- Directing decisions are made here and recorded in `TREATMENT.md`; the build changes nothing about story or rhythm without a treatment line saying so.
- Never strip or rename the upstream files in `/hyperframes`; this skill sits beside them.
- References teach grammar only: no shots, characters, melodies, logos or type designs copied from any work or from another skill's styles.
