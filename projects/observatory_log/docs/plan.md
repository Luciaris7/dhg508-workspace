# plan.md — Week 11 delivery plan and scope freeze

Course-facing plan for the final hand-in (Wednesday 25 November 2026). The
*creative* plan — seven games, six mechanics, the creation red lines, the real
rejections and the 据/推断/设 table — is
[`code/docs/plan.md`](../code/docs/plan.md), and its §0 records the freeze. There
is one source of truth per question and this file does not restate the other one.

## 1. Scope frozen

Frozen at **1.0.1 (v1.7)** on **2026-11-24**. After that date the build accepts
only three kinds of change:

1. a broken state is repaired;
2. a `"TODO"` or a raw JSON dump that can reach the screen is removed;
3. a test that should have caught either is added.

No new modules, no fourth ending, no rewritten prose, no new art. Anything else
waits and is written into `code/questions.md` or `code/docs/DESIGN.md` §9.

Verified at freeze time: no `TODO`/`FIXME` anywhere under `code/scripts/`
(the single grep hit is a bitmap glyph row in `scripts/desktop/xp.gd`), and
`npm run check:static` passes 52 of 52 checks over 62 source files.

## 2. Non-goals

| Not doing | Why |
| --- | --- |
| A fourth ending, or a "true" ending | The three routes already cover refusal, surrender and escape; a fourth dilutes the report |
| Explaining the flesh god | The week-09 design decision was that it stays unexplained; the canon keeps it that way |
| Touch controls | The game is keyboard by design; a phone can watch, not play. Recorded as a limit instead of half-built |
| Splitting the 37.7 MB wasm | The worker already inflates it; there is no smaller engine |
| A second save slot | One slot is the point — the previous keeper's record is gone too |

## 3. The five hand-in items

| # | Requirement | Where it lives | State |
| --- | --- | --- | --- |
| 1 | Live `https://` build opens cleanly; About/footer note; keys ignored; redeploy; tests pass | `code/tools/patch_shell.js` (About note), `code/.gitignore`, live URL | About note added and guarded by a new build test · **v1.7 not yet redeployed** (needs Godot 4.7.2 + `wrangler login`) |
| 2 | `evidence-table.tex` generated from the CSV, never typed | `paper/evidence.csv` → `paper/evidence-table.tex` via `paper/make_evidence_table.py` | Done, 11 rows |
| 3 | `main.tex`, six sections, ~1,500–2,500 words, biblatex-chicago, ≥3 scholarly works | `paper/main.tex`, `paper/references.bib` | Done |
| 4 | Compile on Overleaf, save `paper/design-paper.pdf` | `paper/design-paper.pdf` | See §5 |
| 5 | Final repository checklist | this repo | Done except the two gaps in §5 |

## 4. What changed this week

- **Scope notice** written into `code/docs/plan.md` §0.
- **About note** injected into the exported shell by `code/tools/patch_shell.js`:
  four sentences on the historical context, the 据 / 推断 / 设 split and the AI
  tools. It sits in the shell rather than in a game scene precisely because the
  game content is frozen and the disclosure is not.
- **A regression test for that note** in `code/tests/unit/build.test.mjs`, plus a
  note that the About panel must stay collapsible rather than cover the canvas.
- **Both outside testers recorded**, with what each one changed and which test now
  guards it: `code/docs/user-feedback.md` §3 and [`user-feedback.md`](user-feedback.md).
- **The paper and its evidence table**, with the `schematic.png` figure generated
  by [`make_schematic.py`](make_schematic.py).
- **One drift corrected**: `code/AGENTS.md` claimed 51 static checks; the gate
  actually reports 52. The paper cites the number it can reproduce.

## 5. Known gaps at hand-in

1. **v1.7 is not on Cloudflare yet.** The live URL serves the previous build.
   Rebuilding the web bundle needs Godot 4.7.2 and its Web export template, and
   deploying needs `npx wrangler login` — neither exists on the machine this plan
   was written on. The exact sequence is in the project README.
2. **No stranger has played it.** Tester A is a friend of the author and tester B
   is the commissioning player. Both are outside the build, neither is unfamiliar.
   Whether the game still frightens someone who knows the trick is unanswered and
   is stated as a limit in the paper rather than glossed.
