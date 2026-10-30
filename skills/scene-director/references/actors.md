# Actors

The actor layer for HyperFrames films. The cast is a **decision made per script**, never a fixed pattern: some scripts want a hero actor and a supporting actor, some want a sole hero, some need only stamps, cards and type. Naming any fixed schema (always-actor, always-stamp) is a generated-film tell of its own.

## 1. The cast decision (made at the scene sheet)

Read the script first, then choose the smallest cast that can act it:

| Script calls for | Cast |
| --- | --- |
| A recurring device that *does* something across the film (stamps, seals, a carrier, a cursor, a tool) | **Hero actor** alone |
| A recurring device **plus** a living subject who experiences the story (a figure, a mascot, an object with intent) | **Hero + supporting actor** |
| A film that is pure argument (charts, manifestos, kinetic type a subject-less observer reads) | **No actor** — stamps, cards, panels and type are the performers |
| Whatever else the script demands (two rival objects, an ensemble of planets, a machine with parts) | cast it so — the method is flexible, the discipline is not |

Record the cast decision in one line at the top of the scene sheet (`SCENE-SHEET.md` § "The cast"), and with it the *why* — the same audit trail as every other directing call.

## 2. What every actor must have (whether hero or support)

An actor placed without choreography is scenery. For **every scene in which the actor appears**, the sheet writes three moments, each bound to a word or beat of the cue map:

- **Entry** — where it comes from (off-box edge, another scene's exit trajectory, emerging from a prop), how (falling, rolling ∝ distance ÷ radius, walking, revealed by a mask), and the exact time.
- **Action** — what it does while its word is spoken, with clean anticipation → action → follow-through (`craft.md` §4); poses blend with keyframes, never an `if` swap. Give the action to the *moment that causes it*, not evenly across the scene.
- **Exit** — how and where it leaves (frame edge with lean into motion blur, behind a card during a cut, staying on stage as a held image). Velocity continuity: an exit that flings into the frame edge at speed becomes the incoming edge speed of the next scene (the whip rule in `visual-moves.md` §4).

An actor may **exit as an image**: deliberately stay on stage, still, as the scene ends — allowed as a choice, named in the sheet, never an omission.

## 3. Being present while absent

Even where an actor does not appear, decide *why* it is not there: its fresh imprint remains smoking (the stamp's absence in our demo's scene 2), its footprint stays, a prop it left sits there. Absence with a trace keeps continuity; an unexplained vanish reads as a mistake at review.

## 4. Choreography fields (the sheet's per-scene block)

Per scene, one block per present actor, drafted like the demo's:

| Field | Content |
| --- | --- |
| Entry | edge + motion type + exact time (word-locked) |
| Action | the act, its beat, its acting beats (anticipation, flinch, settle) |
| Exit | edge + how + exact time, or "exit-as-image" + why |
| Camera pay | what the shot does around the actor's move |
| **Motion spec** | every moving moment carries: **duration (s or frames) + easing name**, e.g. `fall 0.35 s ease-in power3, land 1.68`; a lift (anticipation) 0.12–0.18 s; a settle 0.2–0.4 s; an exit clearTime stated explicitly |

Speeds follow the default library (`craft.md` §4 numbers) unless the beat demands otherwise; anything above a 4-frame impact freeze or a 2 s hold must be a named choice in the sheet. The storyboard's action column is this spec verbatim — the builder never invents a duration.

Props migrate: an actor may carry an object in one scene whose fate pays off later (the sack carried at पिता that is gone by रात भर) — continuity is a directing asset.

## 5. Cast cost (no new budget: same ladder)

- Catalog/preset first: any recurring move block;
- preset decoration atoms as props;
- bespoke vectors (a stamp, a simple figure) are the hand-tweened ration — each is deliberate, each named in the sheet, each simple enough to be pose-blendable;
- a figure with a face or complex rig escalates to `/hyperframes` `references/types/character.md` and its acting rules.

## 6. Review adds for actors

Every word-locked actor action gets a 0.2 s step-through strip in `snapshot --range` (`checks.md` §1): the review checks the **acting** — anticipation present, exit velocity true, silhouette readable at 360 px — not just the type read. Subject ≥⅓ frame height at its key moment, always inside the 90% action-safe box.
