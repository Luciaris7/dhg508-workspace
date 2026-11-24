# OBSERVATION LOG · 《观测日志》

Final deliverable for **DHG508 Critical Digital History**, Lingnan University.
Liu Runze 刘润泽 · 3140631 · hand-in 25 November 2026.

A 2D pixel horror game in Godot 4.7.2. The player is the new keeper of a watching
post on a lake in northern Canada and files a nightly report for seven nights.
There is no combat, no chase and no jump scare: the horror comes from the form you
are required to fill in.

| | |
| --- | --- |
| **Play it** | <https://observation-log-9t9.pages.dev> (keyboard; desktop browser) |
| **Design paper** | [`paper/design-paper.pdf`](paper/design-paper.pdf) · source [`paper/main.tex`](paper/main.tex) |
| **Evidence table** | [`paper/evidence.csv`](paper/evidence.csv) → [`paper/evidence-table.tex`](paper/evidence-table.tex) |
| **Game source** | [`code/`](code/) — the whole Godot project, plus its own docs and tests |
| **Scope** | frozen at 1.0.1 on 2026-11-24 · [`code/docs/plan.md`](code/docs/plan.md) §0 |

## Run it

```bash
cd code
npm install            # vitest, playwright, wrangler
npm run build:web      # Godot 4.7.2 -> dist/ (needs the engine and the Web export template)
npm run serve          # http://127.0.0.1:8788
npm run deploy         # npx wrangler login once, then -> https://<project>.pages.dev
```

Desktop instead of web: double-click `code/play.bat` with Godot 4.6+ installed, or
`godot --path . --import && godot --path .`.

## Test it

```bash
cd code
npm run check:static   # < 1 s     52 checks over 62 source files
npm test               # < 1 s     33 unit assertions (vitest, or node --test)
npm run test:game      # 8-12 min  headless Godot: ephemeris, endings, menu, walk, 3 playthroughs
npm run test:e2e       # ~1.5 min  Playwright against dist/, or the live URL
```

All four were run on **25 November 2026** against the build that is now live:
52/52 static, 33/33 unit (both runners), `TEST RUN PASS` (44 scripts, ephemeris
0.006°, 24 motion cases, playthroughs at 277 / 270 / 296 assertions), and 4/4
Playwright cases against <https://observation-log-9t9.pages.dev>.

`npm run check:static` is the gate that runs first: a broken `res://` path fails in
under a second, long before a twelve-minute playthrough would notice it.

## Layout

```text
projects/observatory_log/
├── README.md              this file
├── paper/
│   ├── main.tex           6 sections, biblatex-chicago, XeLaTeX
│   ├── references.bib     3 scholarly works + 7 games + the live build
│   ├── evidence.csv       claim,evidence,locator,level,limit  (据 / 推断 / 设)
│   ├── make_evidence_table.py
│   ├── evidence-table.tex generated from the CSV, never typed by hand
│   └── design-paper.pdf   compiled paper
├── docs/
│   ├── plan.md            week-11 delivery plan and scope freeze
│   ├── user-feedback.md   the two outside testers, and fix -> regression test
│   ├── schematic.png      architecture figure used by the paper
│   └── make_schematic.py  rebuilds schematic.png
├── research/              week-09 research: design doc, journal, bibliography
├── sources/               primary material (PDFs stay out of git; see MANIFEST.md)
└── code/                  the Godot project: scripts/, scenes/, shaders/,
                           assets/, tools/, tests/, docs/, web/
```

The game keeps its own documentation in `code/docs/` (`plan.md` for the creative
plan, `user-feedback.md` for the full feedback log, `architecture.md`,
`MYSTERY_BIBLE.md`, `REPAIR_LOG.md`). Those are the single source of truth; the
copies under `docs/` here are the course-facing digest and never contradict them.

## What is documented, inferred, invented

The game is fiction. The paper keeps three tiers apart and the About panel on the
live page says the same three things:

| Tier | Examples |
| --- | --- |
| **据** documented | planet positions from real ephemerides (36 dates, error 0.006°); the Morse alphabet; the 2001–2006 desktop conventions; the bilingual copy parity |
| **推断** inferred | the daily routine of a remote post; the thirteen-year aurora legend; the reasons a mechanic should work |
| **设** invented | Birch Lake and Site 7; the flesh god and the submerged church; the unknown body on the chart; all three endings |

## AI tools

Claude Opus 5.5 (opencode) wrote the first build. GLM 5.3 Flash, DeepSeek V4.1
Flash and ChatGPT 6.1 Sol revised it. Every design decision, every rejection and
every line of canon came from the author; anything an AI filled in on its own is
still listed in `code/docs/DESIGN.md` §9 as pending review rather than quietly
closed.

---

## 中文摘要

《观测日志》是一款 Godot 4.7.2 的 2D 像素恐怖游戏：玩家是加拿大北部白桦湖畔第七站的新任观测员，
连续七夜按工作须知完成天线、回声测绘、星图与汇报。没有战斗、没有追逐、没有跳吓——恐怖来自那份
你必须填完的表格。课程论文在 [`paper/design-paper.pdf`](paper/design-paper.pdf)，
证据分级表在 [`paper/evidence.csv`](paper/evidence.csv)。
游戏源码在 [`code/`](code/)，运行与测试命令见上。
