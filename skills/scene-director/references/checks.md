# Checks

The failures we saw most, the anti-copy rule, and what a delivery must contain. Run after `npx hyperframes check --json` and the `/hyperframes` `references/review.md` pass; these are the questions `review.md` does not already ask.

## 1. The failures seen most

Walk the sheets once for each line:

- Subject too small, too far away, or pressed against the frame edge.
- Too dark to read, or a colour laid on the same colour (red on red).
- A subtitle or caption covering the subject of its own shot.
- A gag or a failure shown too fast to be understood.
- Blank frames inside a transition.
- A timed effect (iris, zoom, spotlight, follow cam) that stops tracking its subject after the camera move (one world → screen mapping, `craft.md` §3).
- Every row of the sound-design table actually present in the final mix: ambience, foley, music state, the two silences.

Each note is written in `review.md` format: `t=4.2s · where · problem → exact change · what stays`, ranked P0 (breaks the read), P1 (weakens the film), P2 (polish). Fix every P0 and the P1s worth their time in **one round**, then check once more; small finds of that second check belong to the same round.

## 2. Not the reference again

After the treatment is written, open the benchmark's own work (`treatment.md` §3) and compare, six axes: structure, opening, signature shot, camera path, score shape, ending. **At least four of the six must differ** from the reference; rethink the ones that match. The purpose is grammar, not imitation: a film that tracks its reference frame for frame is plagiarism with extra steps.

## 3. Red lines

- References teach grammar only. No characters, designs, melodies, shots, logos or type designs copied from any work.
- No existing works, brands or events appear in the film unless the person owns or has rights to them. Material the person hands over: use it when they say they have the right, otherwise draw fictional stand-ins.
- A third party's name, mark or character never crosses from a reference into the person's film, in picture, score or copy.
- Every third-party asset actually used is listed in `CREDITS` with source and licence (§5).

## 4. Voice and facts

- Voice (when the film has one) is checked by transcription where `/media-use` provides it, or by the person; every line comes back correct, or the line is fixed.
- A film that states facts keeps `FACTS.md` in the project: each claim with its source and the quoted wording, or the measurement that produced it. `story.md` §1's rule made a file.

## 5. Materials and credits

`CREDITS` at the project root lists every outside asset in the film — footage, music, samples, fonts, imagery, the voice source — each with its source and licence. Prefer properly licensed or CC0/OFL material; anything whose licence requires attribution, naming or agreement is noted to the person in one line before use. The person's own material needs no line beyond its owner.

## 6. Delivery

In the project folder, the complete set:

- the film itself (rendered by `/hyperframes` on approval of the preview), at the aspect and rate the spec chose;
- `TREATMENT.md`, `FACTS.md` (when the film states facts), `REVIEW.md`;
- `CREDITS`, when any third-party asset was used;
- the storyline files (`STORYLINES.md` or `SPEC.md`) left in the project, so a later turn can change the film without re-deriving it.

Say where the folder and the film are, that `CREDITS` lists outside assets and licences, and that they are responsible for the materials they provided.
