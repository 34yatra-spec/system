# Craft

The directing craft applied to a HyperFrames build: rhythm, sound, camera and performance. Anything here that touches the render contract is restated, never contradicted.

## 1. Rhythm: numbers first

- The cue map is written before animating (`treatment.md` §6); a scene file's `data-start` and `data-duration` quote its rows.
- Reads that must hold on screen:
  - a subtitle or line: at least 1.8 s, and never shorter than the spoken line + 0.6 s;
  - after a line finishes animating in, hold it roughly letters ÷ 15 + 1.5 s in English, characters ÷ 4.5 + 1.5 s in Chinese (numbers from `story.md` §6 win where they are stricter);
  - a title card: at least 4 s;
  - a failure or a gag: long enough to be understood at first glance — a thumbnail-readable gag beats three the viewer misses.
- Fast is fine; make it fast with fewer words per screen, never by cutting before people finish reading. `npx hyperframes check` measures this (`line_unread`, `dead_stretch`): a warning is a question — fix it, or keep it on purpose with a `data-hold` and a reason in `REVIEW.md`.
- Vary the pace: one acceleration or deceleration, one breath. Everything at one speed reads as generated.

## 2. Sound: half the film

Planned in the sound-design table (`treatment.md` §7); sourced through `/media-use`.

- **Three layers**, mixed in this order of importance: ambience (room, wind, city), foley tied to actions, music. Music ducks under voice and key foley.
- **Every visible action has a sound** on the beat sheet: landings, page turns, clicks, drips, cloth — matched to the material (paper, wood, metal and glass sound different). No orphan actions.
- **Two real silences** before the turn or the emotional peak; the first sound after one carries weight.
- **Sound as a transition**, at least twice: the next scene's sound enters early (J-cut) or the last scene's sound runs over the cut (L-cut). The contract times media by `data-start`/`data-duration` on the `<audio>`; an early-out J-cut is just a negative lead planned in the cue map.
- **Score in the palette of the film's material or world** (its instruments, its era, its textures), never generic piano-and-strings. Say the palette in one line in the sound table and keep it.
- One kind per track: graphics on scene hosts, the one host for all captions, and audio elements with an `id` or left out of the mix — the contract decides the wiring; this skill decides what each element is for.

## 3. Camera: every shot needs a reason

2D HTML has a camera too. What follows is rendered with transform tweens on wrappers inside the scene, never on the `.clip` itself, never layout properties:

- **Push / pull**: scale on a wrapper toward or away from the subject; hold parallax between foreground and background layers.
- **Pan / track**: translate with an eased follow; a follow-cam effect (spotlight, iris, callout) is driven from the subject's position each frame — one world → screen mapping, never hand-typed coordinates.
- **Focus pull**: blur interpolating between layers, putting the eye where the story is.
- **Frames within frames**: a doorway, a screen, a magnifier that stages the next shot inside the current one.
- At least four different moves across the film, real changes of framing between the acts.
- **One signature shot**: a oner, a scale reveal, a transition made from the medium itself — placed at the emotional peak.
- Subject at least a third of frame height at key moments; nothing important pressed against the frame edge; content inside the 90% action-safe box (captions and key text inside 80%).
- Transitions inside the medium, one consistent grammar: a fold, a wipe drawn from the world's own shapes, a match cut (one shape holds while everything around it changes). Handled fades are the default and go on the BANNED line.

## 4. Performance: acting, not sliding

For any character, mascot or anthropomorphised object (with `/hyperframes` `references/types/character.md`):

- **Anticipation → action → follow-through** on every meaningful move: a crouch before the jump, an over-shoot and settle after the land. A move that starts and stops with the same easing is a slide, and a slide is a default.
- **Poses are blended, never switched**: interpolate between keyframes with easing; never swap a pose inside an `if` at a timeline time. The only exception is a deliberate one-frame comic pop, marked in the treatment.
- **Expressions change**, and they are checked at final render size: "worried" and "angry" are one eyebrow direction apart.
- **Props are held between the palms** at a depth between the two arms; a hand-over interpolates palm to palm; a rolling object turns distance ÷ radius.
- Step through every key action at 0.2 s intervals in snapshots before replaying the section.
- An idle breath or float is **acting** only when the beat calls for it; as a stand-in for motion it is a generated-film tell (`story.md` §8).

**Default motion library** (the numbers the director writes unless the beat overrides — speeds are authored, never improvised at the build):

| Move | Duration | Easing |
| --- | --- | --- |
| Anticipation lift / crouch | 0.12–0.18 s | `sine.inOut` |
| Slam / press impact | 3 frames down + 1–2 frame squash-back | `power3.in`, then `back.out(2)` |
| Settle after a landing | 0.2–0.4 s | `power2.out` |
| Human take / flinch | 0.15 s down (in), 0.25 s recover | `power2.inOut` |
| Run / sprint exit | 0.5–0.8 s across the frame, lean 10–25° into the blur | `power3.in` |
| Punch-in (camera) | 0.25–0.35 s | `power2.out` |
| Pull-out (camera) | 0.8–1.2 s, dead stop | `power3.inOut` |
| Overlay slam (text) | 0.2 s, no overshoot before b3 plays | `power4.in` |
| Type exit / strike | 0.3–0.5 s | `power2.in` |
| Speed ramp (audience time) | to 30–35% over 12–15 frames, hold 10–20, ramp back (`visual-moves.md` §1) | custom curve, pre-declared |

Anything outside this table is a named choice in the scene sheet; anything the storyboard omits is a build default from this table, recorded in the review note.

## 5. Connecting to the build

`data-beat` rule: every cue-map hit point lands as `data-beat` on the scene host it belongs to, and `check --json` plus `snapshot --review` are read against the treatment (each beat frame compared with its shot-list row in `review.md` order). Where the build cannot realise a treatment line, the treatment is reopened with a note — the plan, not the edit, is corrected.
