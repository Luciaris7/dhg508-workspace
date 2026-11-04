# Presentation outline · 10 minutes

[Design Document](../design/design_doc.md) · [Bibliography](../references/bibliography.md)

**Thesis of the talk:** *The form outlives the observation.* In this game the daily
report is the last system to keep working: the player stops being able to see
honestly, and the institution's instrument still accepts a Yes.

**Three works:** Daston (2008) — observation as sustained ontology · Gitelman
(2014) — the document as medium · Fisher (2016) — the eerie.

**Live demo or screenshots:** the deck embeds the built game if the browser build
is available; otherwise the captured frames in `shots/`.

---

## 0 · Opening (0:00–0:40)

- One sentence: a seven-day game about filing a report on a sky that is changing
  under you.
- The question on screen: **what happens to a record when the thing it records
  stops being recordable?**
- Say what the talk will do: five parts of the design, three scholars, one claim.

## 1 · Plot — the seven-day loop (0:40–2:00)

**What it is.** The player is the new caretaker of a northern observation station.
Same five actions every day: generator → water → antenna → chart → report. The
lights go out; observation always happens after dark.

**What it lets you do.** Nothing dramatic. Hold to refuel, press to draw water,
rotate the dish to within three degrees, look at a chart, answer Yes or No.

**Implication.** The routine is the content. The game withholds spectacle so the
repetition can be felt as labour.

**Scholar:** Daston — observation as a sustained, collective achievement rather
than a moment of seeing ("ontologies created and sustained by observation",
abstract, p. 97).

**Transition:** if observation is maintained, what maintains it? The form.

## 2 · Mechanics — the report form (2:00–4:00)

**What it is.** One question, two buttons. Days 1–5 both answers advance, but `No`
opens extra work: Day 3 sends you outside to check the antenna; Day 4 makes you wipe
the screen and take a pill. From Day 6 the form refuses anything but `Yes`.

**Implication.** The form is an instrument with preferences, not a menu.

**Scholar:** Gitelman — documents as a media genre that decides what can count as
knowledge. *(Present as a lead: metadata verified, text not read. Say so.)*

**Contribution.** The form outlives the observation. This is the claim of the talk.
Contrast with the usual framing: not "the institution is blind" but "the
institution's instrument still works after its operator has stopped".

## 3 · Graphics — the chart as the only evidence (4:00–5:40)

**What it is.** The anomaly is never in the sky. It is a mark in the chart: 6 px on
Day 3, 10 px on Day 4, 28 px on Day 5, 60 px on Day 6, 160 px on Day 7. The player
draws it themselves as part of the job.

**Implication.** The record is the only apparatus that makes the thing visible.

**Scholar:** Daston again — the ontology is sustained by the observing practice; the
chart is that practice made visible. Point out that this started as a production
constraint (no sky art at 320×180) and became the argument.

## 4 · Environment — the eerie (5:40–7:00)

**What it is.** Snow, firs, a lake, a shack, a dish. One person. A predecessor who
left. A storm on Day 5. Flesh growing over the world on Days 6–7.

**Implication.** The horror is structural: absence where there should be presence.

**Scholar:** Fisher — the eerie as a presence where there should be nothing, or an
absence where there should be something. *(Lead: text not read; verify the wording
before quoting.)*

**Contribution.** The eerie is produced by routine rather than by a monster: the
player is frightened by a form that keeps working.

## 5 · Characters and the counter-form — *The Gift of X* (7:00–8:20)

**What it is.** On Day 2 a fourth desktop icon appears with no explanation: a
bloodstained goat skull. It opens a playable arcade game. It is the only thing in
the game that is not work, and the only interface that returns a number the player
wants.

**Implication.** Play is what the form cannot record. The one number the player
enjoys is the one the institution never asks for.

**Contribution.** The game-within-the-game is not an easter egg; it is the
counter-form against which the report is measured.

## 6 · Technical stack (8:20–9:20)

- **Godot 4.7.2 / GDScript** — why: free, scriptable, strong 2D, headless testing.
  Limits: loose typing at the edges.
- **Procedural pixel drawing** instead of assets — why: exact 320×180 grid, every
  element parameterised and testable. Limits: no shaders, so the Day 4 blur is a
  tear effect; detail is capped.
- **Fixed virtual resolution** 320×180 / desktop 640×360 — why: composition rules
  (player pinned to centre, fixed ground row) become guarantees.
- **Test gates** — 414 module checks and a 112-check full seven-day playthrough.
  Limits: pixel-reading tests need a window.
- **Missing:** audio. Say it plainly as a gap, not as a choice.

## 7 · Close (9:20–10:00)

- Restate: **the form outlives the observation.**
- What the design contributes to the three-way conversation: a mechanism, not a
  theme, for bureaucratic objectivity after the observer fails.
- Three honest open questions: Gitelman and Fisher still unread; silence untested;
  the forced Yes may read as a bug rather than as the argument.
- Invite the obvious challenge: "isn't that just a theme?" — answer with the
  mechanic.

---

## Timing budget

| Part | Minutes | Cumulative |
| --- | --- | --- |
| Opening | 0:40 | 0:40 |
| 1 Plot | 1:20 | 2:00 |
| 2 Mechanics + form | 2:00 | 4:00 |
| 3 Chart | 1:40 | 5:40 |
| 4 Environment | 1:20 | 7:00 |
| 5 Counter-form | 1:20 | 8:20 |
| 6 Stack | 1:00 | 9:20 |
| 7 Close | 0:40 | 10:00 |

## Rehearsal notes

- Rehearse with Presenter Mode (`/#/presenter/`) and keep the timer visible.
- If a demo fails, fall back to the captured frames — do not debug live.
- Do not claim Gitelman or Fisher as read. Say "this is a lead I am still
  checking" — it is stronger than being caught.
