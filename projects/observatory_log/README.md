# Observatory Log (《观测站日志》)

Week 9 project: situating and explaining the design. A seven-day, single-ending 2D
pixel horror game about maintaining an observation station alone, and filing a daily
report on a sky that is changing under you.

**The claim of the talk:** *the form outlives the observation.*

## Where things are

| What | Where |
| --- | --- |
| Current design, reading and contribution | [research/design/design_doc.md](research/design/design_doc.md) |
| Chronological record, searches, decisions | [research/journal/research_journal.md](research/journal/research_journal.md) |
| Bibliography with search log and reading status | [research/references/bibliography.md](research/references/bibliography.md) |
| Ten-minute outline and timing | [research/outputs/presentation_outline.md](research/outputs/presentation_outline.md) |
| The deck source (copy) | [research/outputs/slides.md](research/outputs/slides.md) |

## The deck

The deck is a [DAIHUM Reslides](https://github.com/boan-anbo/reslides) presentation.
It lives in the Reslides repository, not here:

- Source: `reslides/examples/starter/slides.md` (a copy is kept at
  `research/outputs/slides.md`)
- Images: `reslides/examples/starter/public/obs/`
- Run it:

```bash
cd reslides
npm run setup      # first time only: installs and builds the packages
npm run dev        # opens the deck
```

Presenter Mode is at `/#/presenter/` — it shows these presenter notes, the next
slide and a countdown timer.

Run `npm run build:starter` to produce a static build in
`reslides/examples/starter/dist/`.

## The game

The built game is outside this repository (Godot 4 project). The screenshots used in
the deck were captured from it and are copied into the deck's `public/obs/` folder.

## Evidence standard used here

Three scholarly works are engaged in total. Each one is marked with its reading
status in the bibliography:

- **Daston (2008)** — abstract read in full, article body paywalled.
- **Gitelman (2014)** — record verified, text **not** read. A lead.
- **Fisher (2016)** — record verified, text **not** read. A lead.

No quotation is attributed to a work that has not been read at the stated locator.
