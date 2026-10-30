# Visual Moves

The director's cookbook index: the visual techniques a top-tier short reel uses, with the numbers pulled from current creator practice, each wired to what the HyperFrames stack supplies (the catalog, the frame presets, the house style). The scene sheet names the move; `script-to-scenes.md` §3 supplies how it is built.

## 1. Pacing numbers

- **A visible change every 1.5–2.5 s**: a cut, a punch-in, a headline flip, a prop, a caption emphasis shift. More than ~2.5 s between changes is a retention leak. Fast-cut plan: 1–3 s cuts on punchy lines; 0.3–0.5 s micro-pauses only where a complex idea is being processed.
- **Cut on the audio event**: the beat, the hard consonant, the word landing — never mid-word. The cut is felt as momentum.
- **Speed ramps in frames**: classic editorial ramp = to 30–35% speed over 12–15 frames, hold 10–20, ramp back out. Impact freeze (on a hit, a landing, a reveal) = fast ramp down to 10–15%, hold 3–5 frames, fast ramp back. A matched slow section across the cut gives flow with no transition effect. In the build these are eased `timeScale` curves on the scene's timeline, never real-time effects.
- **Never bleed energy across a cut wrongly**: no hard cut from a high-energy hook into a slow wide shot. Bridge with a pattern interrupt — a snap zoom, a headline flip, a flash-forward of what is coming.
- Zoom punches land on the line that matters, not at random: time them to the tip-off phrase as a conductor cues an accent, or to the peak of a gesture.
- **Log the change plan**: after the scene sheet, count the time between every visual change; an average gap over 2.5 s means the plan is retimed — or the payoff earns the one long hold on purpose.

## 2. The hook is three layers, one promise (≤3 s)

1. **Visual hook (frame 0)**: one focal subject, clutter out of frame, movement already in the motion in that frame; high contrast; a face if the film has one, otherwise the object doing its act.
2. **Verbal hook**: the first spoken sentence lands inside ~3 s, immediate and punchy.
3. **Text hook**: on-screen text names the same promise in few words.

All three agree on one promise or the viewer feels the lie. Suspense in the opening adds watch time; most recall has happened by six seconds. The frame-0 image is designed first, and at runtime the composition opening is the strongest thumbnail candidate.

## 3. Object language

Objects carry the story when a presenter is not present. Each object gets a **verb arc**: introduce → use → transform → pay off. An object that appears and does nothing is cut.

- **Match cut on shape**: its silhouette carries across the edit — a circle becomes a lens, a plate, a wheel, a logo; cut when the shapes echo.
- **Object-to-object chain**: every shot ends on the thing that opens the next.
- **Object as hook**: the object in motion at frame 0 (dropped, snapped, flipping into place).
- **Object under the voice**: what the narrator names appears at the instant it is named; the object fills at least a third of frame height at its key moment.

## 4. Transition grammar (inside the medium)

| Move | The craft rule | In our stack |
| --- | --- | --- |
| Whip pan | Outgoing shot **accelerates into** the frame edge; incoming **begins at identical speed, same direction**; directional motion blur hides the seam. Reversing direction breaks it | `npx hyperframes catalog --query "whip pan"` → `whip-pan` block exists; tween off-screen transforms with matching easing |
| Action match | Cut mid-motion so the movement continues across the edit (a hand reaching is caught by the next shot's landing) | tween A ends in motion, tween B starts from the same velocity point; on the beat |
| Match on shape | One shape holds while everything around it changes | kept element with a stable id; everything else swarms anew |
| Kinetic type | Oversized, edge-cropped, fast horizontal shifts, sharp clean landings; motion blur only inside transitions | display type ≥ one preset's display ramp; the tween eases hard into rest, never a float |
| Impact freeze | Everything freezes for 3–5 frames at the hit, then releases | one timeline with a hold; the frozen frames are exactly the reveal's payoff |

Fades and cross-dissolves are the default; each one gets a name in the spec's BANNED line unless it is the film's one deliberate grammar.

## 5. Retention structure

- **Open loops**: stack two or three unresolved threads ("and the last one is the killer") and converge them at the end.
- **The callback**: end by answering the opening question with the new context earned; the ending echoes the opening.
- **Bridges over cliffs**: any line that could end the film early gets a flash-forward of what is still coming.
- The last 20% may slope gently: most viewers have already had their value; never fade out — end on the answer or the button.

## 6. Choosing the move (per scene)

The scene sheet's "camera move" cell names one item from §2–5 plus one from `craft.md` §3 (push, pull, parallax, focus pull, frames-within-frames). Rules of selection:

- Fast-cut lines get a change, not always a camera move: a caption emphasis, a punch-in, a prop swap is a legal "cut".
- At least four real camera moves across the film and one signature moment (`craft.md` §3).
- Adjacent scenes never repeat the same move twice in a row.
- Every named move passes the "what does it cost" test: blocks from the catalog cost ~1–2 minutes, preset treatments cost ~1 minute, hand-written tweens cost minutes each and are rationed to the signature moments.
