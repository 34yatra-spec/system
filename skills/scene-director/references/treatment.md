# Treatment

Write `TREATMENT.md` in the project folder after the storyline is picked and before any drawing, style frame or scene file. It is the director's page: every creative call is made here, in words and numbers, so the build is only execution. Everything it says traces to the storyline already approved; a call that contradicts it reopens the storyline, not the treatment.

Eight sections, in this order:

## 1. Three candidate structures

Write three ways the picked storyline could be structured, a few lines each (a single journey, a before/after, a countdown, a list that turns, a question answered, a machine toured). Then name the one chosen and, in one clause, why it beats the other two. The first idea that comes to mind for a topic is usually its cliché: check each candidate against the BANNED list in `SPEC.md`-to-be before choosing.

## 2. Logline and arc

One sentence: who or what wants something, what changes, how it ends differently from how it began. Then the arc in three words each: setup → turn → ending. The ending echoes the opening (a bookend, a scale reveal, the task done right the second time).

## 3. Benchmark

One or two reference works (films, title sequences, ads, games) that set the bar for **this style and this topic**. Write two columns for each:

- **Learn**: composition grammar, pacing, camera semantics, colour logic, score structure, how it earns attention.
- **Do not take**: characters, designs, melodies, specific shots, logos, fonts, names.

A work the benchmark shares recognisable elements with never appears in the film unless the person owns it (`checks.md` §5).

## 4. Shot list

One row per shot, numbered, in order. Columns:

| Shot | Framing | Angle | Camera move | Duration (s) | Why |
| --- | --- | --- | --- | --- | --- |

Framing: wide, full, medium, close, insert. Camera move: push, pull, pan, track, crane, zoom — or "held". Every row has a **why**: what the shot causes, proves or makes the viewer feel. In an HTML/HyperFrames build, "camera" means what renders differently over the shot's span: a scale or translate tween on a wrapper, a parallax between layers, a focus pull on a blurring layer. Every move must survive the contract: tween transforms, not layout; animate a child, never the `.clip` itself.

Plans that must show in the build:

- At least **four different camera moves** across the film; a film where every shot enters the same way is a default, and goes on the BANNED line.
- **One signature shot** the viewer remembers: a oner, a scale reveal, a transition made from the medium itself.
- At key moments the subject fills at least a third of the frame height, with a readable silhouette and clear staging.
- Transitions are designed **inside the medium** (a page turn, a line growing, a shape that becomes the next shot) as one consistent grammar. Default fades and hard cuts are defaults: name them on the BANNED line or justify each.

## 5. Beat sheet

The beats of the picked storyline (`story.md` §4) marked second by second: `0.0–2.4 hook`, `2.4–6.8 tension`, … with the one action of each beat written in verbs. Nothing in the shot list may fall between two beats without a beat line claiming it.

## 6. Cue map

The music grid, written **before** animating; the picture locks to it.

- Sections: `id, start, bpm, bars` per section of the score.
- Hit points: each of them `section + beat` — every cut, every key action, every reveal, at least one per 3 s in a fast section. During the build these become `data-beat` marks and the audio's landings; the aim is 0 ms drift between the picture and the grid.
- Pace grammar: alternate fast and slow; include one clear acceleration or deceleration; give the audience one breath (a long take or a held pause). A film at one even speed has failed.
- One action, one sound, one cut — but not a cut on every beat; leave time to see.

## 7. Sound-design table

One row per section of the cue map:

| Section | Ambience bed | Foley (which action → which sound) | Music state | Silence |

Rules the table obeys (`craft.md` §2):

- Every visible action on the beat sheet has a sound in the Foley column.
- At least two real silences (or near-silences), the first before the turn or the emotional peak; the sound that breaks a silence is one of the most important sounds in the film.
- Music registered as its own `<audio>` mixes under voice and key foley; "music as dialogue" ducking is planned here, not fixed at render.

## 8. Title, subtitle and copy design

- What each on-screen line says, at most 6 words a line (about 10 for an explainer), no trailing periods; hold times follow `story.md` §6 and `craft.md` §1.
- Where the type sits: caption-safe zones (80% title-safe for key text), never over the subject of the shot it belongs to.
- The language and voice: whose words the film uses verbatim (the person's copy, the product's text) and which lines are the director's.

## Keeping it honest

- Every claim in the treatment traces to a source (the site, the PR, the person's words, a named measurement). What no source says stays unsaid; illustrative numbers are marked as such.
- Facts stated as facts in a data or evidence film get a `FACTS.md` with source and quoted wording (`checks.md` §5).
- The treatment is a contract with the review: every `REVIEW.md` note about timing, rhythm or framing cites the shot list, the cue map or the sound table; the notes correct build mistakes against it, or reopen this file when the plan itself was wrong.
