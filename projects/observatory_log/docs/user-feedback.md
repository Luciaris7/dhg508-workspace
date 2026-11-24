# user-feedback.md — the two outside testers, and what each one changed

Digest of the feedback that produced changes in the build, for §5 of the paper.
The full log — internal QA, every issue with its evidence and its root cause — is
[`code/docs/user-feedback.md`](../code/docs/user-feedback.md). This file does not
add claims the full log does not contain; it points at them.

Both testers are outside the build (the code was written by AI agents). Neither is
a stranger: A is a friend of the author, B is the commissioning player. That is a
real weakness of this evidence and it is stated as such in the paper.

## Tester A — a friend, no knowledge of the setting — 17 November 2026

Material: a Word document of concrete suggestions, `修改建议和方案.docx`. The author
relayed it into `code/docs/plan.md` §6, which is why the creative plan lists those
requests under "user's own words". It is her document.

| Her point | What changed | Regression test |
| --- | --- | --- |
| No prompt to leave the ridge cut-scene | "click to exit" prompt at the ridge railing; closes on click / E / Esc and returns when you come back | asserted in `tests/playthrough.gd` |
| Boat-dock locker text should name the trap | text replaced; the bracketed keywords render as equal-length gibberish so the hint stays a puzzle | `tests/playthrough.gd` locker branch |
| The sealed record should be Joseph's own account | replaced with the 2013 keeper's statement (thirteen years, the tampered truck, the spare parts in the dock) | `tests/ending_test.gd` |
| Keep only three prior dates (2013 / 2000 / 1987) — "we are the fourth"; the archive is from thirteen years ago; the Morse number must follow | archive lists exactly three cycles; the sealed number is **derived** (13 years before this cycle's day 7 + 23:40) instead of hardcoded | `tests/ending_test.gd` derivation + save round-trip |
| The bed should work on any night; if tasks are undone, ask first; sleeping through ≥4 days ends in the UFO bonus ending | implemented: bed any night, confirm prompt, bonus ending with two illustrations | `tests/ufo_test.gd`, `tests/dream_test.gd` |

Her item 5 is missing from the document (the numbering jumps from 4 to 6). It is
recorded as missing rather than invented. She reported no crash and no error.

## Tester B — the commissioning player — 16 November 2026

Material: a 24-item play report, `游玩报告与改进`. Its four most consequential
items:

| Their point | What changed | Regression test |
| --- | --- | --- |
| The Yes/No semantics are inverted: the station wants **No**, and a **Yes** gets rewritten | the whole reporting arc was reversed — No is thanked, Yes is re-read and rewritten, and from Day 6 only No is accepted | `tests/unit/canon.test.mjs`, `tests/ending_test.gd` |
| Day 7 guidance is unclear | the forced walk accumulated position by speed and could overshoot and wedge forever; replaced with `move_toward` | `tests/motion_test.gd`, 24 cases across six frame intervals |
| Remove every "eye" motif, including the ending illustrations | all removed; the church redrawn front-on with a single central tower | visual review only — no assertion (known gap) |
| "Make it almost impossible to score 5000" | HOMEWARD retargeted to 2000 points; the 5000 line deleted | `tools/sim_minigame.py` balance simulation |

A separate report, not from either document: the live build had **no sound** at
all. The in-page analyser read 0.128 RMS while the operating system's audio meter
read 0.000, which localised the fault to audio buses created at runtime that the
browser's driver never connected. Fixed by moving the bus layout into
`default_bus_layout.tres`; five assertions in `tests/unit/audio.test.mjs` now pin
the layout, the bus names and the send relationships. Peak output afterwards:
0.306 locally, 0.334 on the live URL.

## The pattern worth noticing

Neither tester found a typo. A found a *missing affordance* (how do I leave this
screen), the shape of the archive, and a whole ending that did not exist yet. B
inverted the central mechanic of the game and caught a hard hang on the last day.
Every one of those is a class of defect the automated gates could not see, because
the gates assert that the build behaves as specified — and the specification was
what was wrong.

## What is still missing

- A tester who does not know the trick. Both people above are close to the project.
- A device log for tester A: no browser, no machine, no duration was recorded.
- Any measure of fright. The gates prove consistency, not effect.
