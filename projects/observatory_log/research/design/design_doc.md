# Design Document · Observatory Log (《观测站日志》)

> Week 9 · Situate and Explain Your AI Design. This is the **current design**.
> Reasoning, searches and source checks live in the
> [research journal](../journal/research_journal.md); the sourced list of works
> is the [bibliography](../references/bibliography.md).

**Project files**

- [Research journal](../journal/research_journal.md)
- [Bibliography](../references/bibliography.md)
- [Presentation outline](../outputs/presentation_outline.md)

**Scope:** a seven-day, single-ending, single-player game of roughly sixty
minutes; no combat, no fail state in the work routine, no save system enabled.

## 1. Idea and question

*Observatory Log* is a 2D side-scrolling pixel horror game played across seven
in-game days. The player is the new caretaker of a remote observation station in
northern Canada. The job is narrow and explicit: keep the generator running, draw
water, aim the antenna, record the star chart, and submit a daily report. Nothing
else is asked.

The question the project is built around:

> **What happens to a bureaucratic record when the thing it is supposed to record
> stops being recordable?**

The game answers this as a design problem rather than as a theme. The player's
only channel to the institution is a form with two buttons, **Yes** and **No**.
As an anomaly grows in the sky, that form does not break. It becomes *more*
insistent: from Day 6 it rejects every answer except Yes. The player keeps filing
after they have stopped being able to see honestly, and the paperwork keeps
accepting them.

## 2. Design

### 2.1 The daily loop (mechanics)

Each day runs the same five nodes, gated in order: refuel the generator → draw
water at the lake → aim the antenna → record the star chart → submit the report.
Completing the first flow turns the outdoor light to dusk; completing the second
runs a fifteen-second sunset into night. **Observation always happens after
dark.** The player cannot skip a node, and cannot do them out of order.

The loop is deliberately *undramatic*. Refuelling is hold-to-fill; drawing water
is a single press; aiming the antenna is a small rotation puzzle with a tolerance
of three degrees and a readout that says only `SEARCHING`, `GETTING CLOSER`,
`LOCKED`. There is no fail state in the routine. The only thing the player can do
wrong is file a report the form does not want.

### 2.2 The form (the central mechanic)

The report window asks one question and offers `Yes` / `No`. On Days 1–5 both
answers advance the day, but they are not the same day: on Day 3, `No` sends the
player outside to inspect the antenna before bed; on Day 4, `No` triggers wiping
the screen and taking a sleeping pill. From Day 6 the field rejects anything that
is not `Yes`, prints `Type Yes` in red, and leaves the rejected text in the box.

This is the part of the design I care most about. The form is not a menu; it is an
instrument the player operates, and it has its own preferences.

### 2.3 The chart (graphics as evidence)

The star chart is drawn procedurally: a fixed field of stars, a horizon, and one
small body that changes between days. On Day 3 it is six pixels across and sits
near the edge; by Day 6 it is sixty pixels and has moved inward. The player is
never shown the object directly in the sky; they see it **as a difference in a
chart they drew themselves**. The only visual record of the anomaly is the record
the job asks them to make.

### 2.4 The desktop (environment, and the counter-form)

The station computer is a Windows-XP-like desktop with three documents. On Day 2
a fourth icon appears — a blood-stained goat skull labelled *The Gift of X* —
with no installation step and no explanation. It is a playable arcade game: a
boat, reefs, a score. It is the only thing on the desktop that is not work, and
the only thing that gives the player a number that goes up.

The desktop is also where the ending happens: on Day 7 the report is filed, the
desktop blacks out, and a line appears in red — `BEHOLD HER THRONE, LAMB` — before
the player is walked, without control, to the lake.

### 2.5 Sound and silence

There is no audio. This began as a limitation and has become a decision I have to
either own or fix: the storm, the generator and the wind are all silent, and the
only voice in the game is the predecessor's voicemail at the start. I record it as
a **known gap**, not as an artistic choice, because I have not yet tested whether
silence helps or merely reads as unfinished.

## 3. Evidence and scholarly conversation

I am working with three works, cited in full with locators in the
[bibliography](../references/bibliography.md). What follows distinguishes what I
have actually read (an abstract, in full) from what is still a lead.

### 3.1 Observation is a sustained, collective achievement — Daston

Lorraine Daston argues that scientific observation should be treated as an
*ontology-making* practice rather than as a problem of perception. Her abstract
proposes "a turn toward ontology — more specifically, toward ontologies created
and sustained by observation", and frames the older debate as the "interaction of
subjective and objective factors in scientific inquiry" (Daston 2008, abstract,
p. 97).

This is the argument my chart mechanic is built on. The player does not observe an
object; they sustain an ontology — a small, repeated, conventional set of marks
that makes an object *count* as observed. When the anomaly grows, nothing in the
sky changes for the player, because the sky is not the interface. The chart is.

**What I take:** observation is maintained, not received; a game can model the
maintenance.
**Where I diverge:** Daston describes how a community trains and stabilises
seeing. My station has a community of one, and the training manual is a text file.

### 3.2 The document is the genre that makes knowledge administrable — Gitelman

Lisa Gitelman treats documents not as containers of knowledge but as a media genre
with its own history, arguing that paperwork is where knowing and showing are made
to coincide.

*Reading status: metadata verified (Duke University Press, 2014, DOI
10.1215/9780822376767); the book itself is not yet read — this is currently a
**lead**, and the sentence above is my expectation of it, not a finding.*

**What I expect to take:** the report form is not a neutral window onto the
anomaly; it is the thing that decides what an anomaly can be. That is exactly the
behaviour I implemented when the form starts refusing `No`.
**What I must check before presenting:** whether Gitelman makes this claim about
forms specifically, and where.

### 3.3 The eerie is an absence that should not be there — Fisher

Mark Fisher separates the *weird* (a thing that should not exist) from the *eerie*
(a presence where there should be nothing, or an absence where there should be
something). The northern station is built almost entirely out of the second
category: no other people, a predecessor who left, a job whose whole content is
waiting, and an instrument that reports a difference.

*Reading status: metadata verified (Repeater, 2016; OpenAlex W2799136475 gives
2017 for the deposited manuscript); the book is not yet read — also a **lead**. I
know the distinction by reputation and must locate the passage before quoting it.*

**What I expect to take:** the horror should come from the routine rather than
from a monster; the player's fear is produced by a form that keeps working.

### 3.4 My contribution

The three works give me: observation as sustained practice (Daston), the document
as the genre that makes observation administrable (Gitelman), and the eerie as a
structural absence (Fisher). My design's contribution puts pressure on the seam
between them:

> **The form outlives the observation.** In *Observatory Log* the report is the
> last system to fail. The player can no longer see honestly, the chart is
> dominated by the anomaly, the antenna is overgrown — and the form still accepts
> a Yes, and the day still advances, and the record still looks complete.

That is a claim about bureaucratic objectivity that I have not seen made as a
*playable* mechanism: not "the institution is blind", which is a theme, but "the
institution's instrument still works after its operator has stopped", which the
player experiences as a button that will not take No for an answer.

The secondary contribution is the counter-form: *The Gift of X* is the only
interface in the game that returns a number the player wants. Play is what the
form cannot record.

## 4. Technical stack

| Technology | Role | Why | Limits |
| --- | --- | --- | --- |
| **Godot 4.7.2 / GDScript** | engine and all game logic | free, scriptable, strong 2D, exports to web and desktop; headless mode makes automated testing possible | GDScript is loosely typed at the edges; some errors surface only at runtime |
| **Procedural drawing** (`CanvasItem` calls) | almost all art: terrain, trees, station, chart, ending | keeps the pixel grid exact at 320×180, no asset pipeline, no filtering artefacts, and every element is parameterised so it can be tested | no shader pipeline, so the Day 4 "blur" is a tear effect rather than a real blur; procedural art caps scene detail |
| **Fixed virtual resolution** 320×180 world / 640×360 desktop, integer scaling | composition | guarantees the player stays on the horizontal centre and the ground row is fixed, which is a stated design rule | text below ~10 px is unreadable; the desktop has to switch the viewport to avoid half-scale text |
| **Headless test gates** (414 module checks, a 112-check full seven-day playthrough, a pixel-level movement test) | correctness | the day loop, the gating order and the movement rule are verified by machine rather than by eye | gates that read back rendered pixels cannot run headless, so two of them need a window |
| **Built-in `draw_string` + one font** | all text | one font keeps the interface coherent | the day-title font atlases exist but are not wired in yet |

No audio subsystem, no save system enabled, no network component. The web build
and the desktop build share one source tree.

## 5. Open questions and next steps

1. **Read Gitelman and Fisher properly.** Both are currently leads. I need at
   least one located passage from each before the presentation, or I must present
   them explicitly as expectations rather than as findings.
2. **Test the silence.** Is the absence of audio an atmosphere or an unfinished
   build? Not answerable from this document.
3. **Decide whether the forced Yes is legible.** A player may read it as a bug
   rather than as the argument. Needs one playtest with someone who has not read
   this document.
4. **Name the game.** *Observatory Log* is a working title; *THE AUDIENCE* is the
   alternative, and the ending currently prints the latter.
5. **Wire the day-title font atlases** so the seven days look like seven days.
