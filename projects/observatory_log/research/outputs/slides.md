---
framework: react
theme: exhibit
title: "Observatory Log — The Form Outlives the Observation"
routerMode: hash
layout: cover
kicker: DAIHUM · Week 9 · Situate and Explain Your AI Design
meta: 10-Minute Talk
duration: 10min
timer: countdown
---

# Observatory Log

The form outlives the observation.

::by::

A seven-day pixel horror game about filing a report on a sky that is changing under you.

<!--
000–00:40 · 40 seconds

One sentence, then move on. Do not read the slide.

"My project is a seven-day game. You are the caretaker of a remote observation
station. Every day you refuel, draw water, aim the antenna, record the star chart,
and answer a report form. The sky is changing. The form is not."

Ask the question out loud before showing anything: what happens to a record when the
thing it records stops being recordable?
-->

---
kicker: The question
---

# What happens to a bureaucratic record when the thing it is supposed to record stops being recordable?

<div class="body col">
<div class="frame hot"><span class="label">The claim I will defend</span><div class="text">The form outlives the observation. The player stops being able to see honestly — and the institution's instrument still accepts a <mark>Yes</mark>, the day still advances, and the record still looks complete.</div></div>
</div>

::foot::

Five parts of the design · three scholarly works · one claim · the technical stack.

<!--
00:40–01:00 · 20 seconds

This is the thesis. Everything after this is evidence for it.
Flag the structure so the audience knows where you are going.
-->

---
kicker: 1 · Plot — the seven-day loop
---

# The routine is the content.

<div class="body col">
<div class="route">
<div class="step"><span class="yr">01</span><p class="what">Generator</p><p class="how">hold to refuel · light turns to dusk</p></div><div class="arrow">→</div>
<div class="step"><span class="yr">02</span><p class="what">Water</p><p class="how">one press · 15-second sunset</p></div><div class="arrow">→</div>
<div class="step"><span class="yr">03</span><p class="what">Antenna</p><p class="how">rotate to ±3° · SEARCHING / LOCKED</p></div><div class="arrow">→</div>
<div class="step red"><span class="yr">04</span><p class="what">Chart → Report</p><p class="how">record the sky · answer Yes or No</p></div>
</div>
<img src="/obs/antenna.png" alt="Aiming the antenna" style="height: 210px; width: auto; align-self: center; image-rendering: pixelated; border: 1px solid #333;" />
</div>

::foot::

Same five nodes every day, gated in order. **Observation always happens after dark.**

<!--
01:00–02:00 · 60 seconds

What it is: the new caretaker of a northern station. Snow, firs, a lake, a dish, a
shack, one person.

What it lets you do: almost nothing dramatic. Hold to refuel. Press to draw water.
Rotate the dish until it says LOCKED. Look at a chart. Answer a form.

Why: spectacle is withheld on purpose so the repetition can be felt as labour. The
anomaly is not an event, it is a drift in a document.

Point at the screenshot: three degrees of tolerance and a readout that never tells you
the answer, only whether you are closer.
-->

---
kicker: 2 · Mechanics — the form
---

# The form is not a menu. It is an instrument with preferences.

<div class="body">
<img src="/obs/report.png" alt="The report form" style="height: 400px; width: auto; align-self: center; image-rendering: pixelated; border: 1px solid #333;" />
<div class="rows" style="flex: 1; gap: 34px; align-self: center;">
<div class="frame hot"><span class="label">Days 1–5</span><div class="text">Yes and No both advance — but No opens extra work. Day 3: go outside and inspect the antenna. Day 4: wipe the screen, take a sleeping pill.</div></div>
<div class="frame"><span class="label red">Days 6–7</span><div class="text">The field refuses anything that is not Yes. It prints <mark>Type Yes</mark> in red, and leaves your rejected answer in the box.</div></div>
</div>
</div>

<!--
02:00–04:00 · 2 minutes — the longest and most important part.

This is the design I care most about and where the argument lives.

Days 1–5: both answers work, but they are not the same day. No costs you work.
Days 6–7: the form has preferences. It will not take No. It keeps your rejected text
in the box, so you have to delete it before answering again.

Scholar: Gitelman — documents as a media genre that decides what can count as
knowledge. SAY CLEARLY: "This is a lead. I verified the record, I have not read the
book." Then give the claim being tested: the form is not a window onto the anomaly, it
is the thing that decides what an anomaly can be.

Give the contribution in one sentence: the form outlives the observation. Not "the
institution is blind" — that is a theme. "The instrument still works after its
operator has stopped" — that is a mechanism the player operates.
-->

---
kicker: 3 · Graphics — the chart is the only evidence
---

# You never see it in the sky. Only in the chart.

<div class="body">
<img src="/obs/starchart.png" alt="The star chart" style="height: 400px; width: auto; align-self: center; image-rendering: pixelated; border: 1px solid #333;" />
<div class="frame" style="flex: 1; align-self: center;"><span class="label">The anomaly, day by day</span><div class="text">6 px on Day 3 · 10 px on Day 4 · 28 px on Day 5 · 60 px on Day 6 · <mark>160 px on Day 7</mark>. It is never rendered in the sky itself.</div></div>
</div>

::foot::

Daston 2008, abstract, p. 97: "ontologies created and sustained by observation".

<!--
04:00–05:40 · 100 seconds

Admit where it came from: I could not draw a convincing sky object at 320×180, so the
anomaly went into the chart. Then the shortcut turned out to be the better design.

The player does see the anomaly — as a difference in a chart they made themselves, as
part of the job. What they cannot do is see it anywhere else.

Daston: observation is sustained, not received. The chart is that sustaining made
visible. Quote the line and give the locator out loud — p. 97.

Diverge: Daston describes a community training a collective eye. My station has a
community of one, and the training manual is a text file.
-->

---
kicker: 4 · Environment — the eerie
---

# The horror is structural, not monstrous.

<div class="body col">
<div class="route">
<div class="step"><span class="yr">A</span><p class="what">Absence</p><p class="how">no other people · a predecessor who left · a job that is waiting</p></div>
<div class="arrow">→</div>
<div class="step"><span class="yr">B</span><p class="what">Weather</p><p class="how">snow, then a storm on Day 5</p></div><div class="arrow">→</div>
<div class="step red"><span class="yr">C</span><p class="what">Growth</p><p class="how">flesh over the world, Days 6–7</p></div>
</div>
<img src="/obs/flesh.png" alt="Day 6" style="height: 200px; width: auto; align-self: center; image-rendering: pixelated; border: 1px solid #333;" />
</div>

::foot::

Fisher 2016 — the eerie: a presence where there should be nothing, or an absence where there should be something. *(Lead — wording not yet checked against the page.)*

<!--
05:40–07:00 · 80 seconds

The station is built almost entirely out of absence. That is Fisher's eerie, not his
weird: no monster that should not exist — a place where a person should be, and is not.

SAY the reading status out loud: "Fisher is still a lead for me." Better than being
caught.

Contribution: the eerie here is produced by routine rather than by a creature. What
frightens the player is a form that keeps working.
-->

---
kicker: 5 · Characters — the counter-form
---

# Play is the one thing the form cannot record.

<div class="body col">
<div class="route">
<div class="step"><span class="yr">Day 1</span><p class="what">Three icons</p><p class="how">notice · star chart · report</p></div>
<div class="arrow">→</div>
<div class="step red"><span class="yr">Day 2</span><p class="what">A fourth appears</p><p class="how">a blood-stained goat skull · no install step · no explanation</p></div>
</div>
<div style="display: flex; gap: 56px; flex: 1; min-height: 0; align-items: center;">
<img src="/obs/gift.png" alt="The Gift of X running inside the desktop" style="height: 300px; width: auto; image-rendering: pixelated; border: 1px solid #333;" />
<div class="frame" style="flex: 1;"><span class="label">The Gift of X</span><div class="text">A playable arcade game inside the station computer. The only interface in the game that returns a number the player <mark>wants</mark>.</div></div>
</div>
</div>

<!--
07:00–08:20 · 80 seconds

On Day 2 an icon appears with no installation, no explanation, no comment. It is a
playable arcade game — a boat, reefs, a score.

Every other number in this game is a record for someone else: litres of fuel, the
angle of a dish, a chart. This one is for the player.

Contribution: the game-within-the-game is not an easter egg, it is the counter-form
against which the report is measured. The one number you enjoy is the one the
institution never asks for.

If asked whether it is diegetic: yes — it runs inside the desktop, in a window, scaled
into the OS chrome.
-->

---
kicker: The scholarly conversation
---

# Three works, and what each one gives the design.

| Work | What it argues | What it does for my design | Status |
|---|---|---|---|
| **Daston**, "On Scientific Observation", *Isis* 99:1 (2008), 97–110 | Observation sustains an ontology; the older debate was subjective vs objective factors in inquiry | The chart: observation as maintained practice, not reception | **Abstract read** (p. 97); body paywalled |
| **Gitelman**, *Paper Knowledge*, Duke UP (2014) | Documents are a media genre, not neutral containers | The report form decides what can count as an anomaly | **Lead** — record verified, text not read |
| **Fisher**, *The Weird and the Eerie*, Repeater (2016) | The eerie: presence where there should be nothing, or absence where there should be something | The station's horror comes from routine, not from a monster | **Lead** — record verified, text not read |

::foot::

OpenAlex API queries and reading status are recorded in `research/references/bibliography.md`.

<!--
08:20–09:00 · 40 seconds — this slide can carry the whole conversation if you run short.

Do not read the table. Point at the third column: one work gives me the practice, one
gives me the instrument, one gives me the mood — and my mechanism sits on the seam
between all three.

Be explicit about reading status. It is a strength: it shows the difference between a
search result and a finding.
-->

---
kicker: My contribution
---

# A mechanism, not a theme.

<div class="body col">
<div class="frame hot"><span class="label">What the three works do not yet explain</span><div class="text">Daston and Gitelman both describe observation and documentation as <em>collective</em> achievements. My station has a community of one. What happens to those practices when there is nobody left to maintain them but a form?</div></div>
<div class="frame"><span class="label red">What the design contributes</span><div class="text">The player experiences the answer as a button that will not take No. Not a statement that institutions are blind, but a demonstration that the instrument keeps working after the operator has stopped.</div></div>
</div>

<!--
09:00–09:20 · 20 seconds

The sentence to leave in the room: "The form outlives the observation."

If someone asks "isn't that just a theme?" — the answer is the mechanic. Themes are
stated; this one is operated. The player is holding the mouse when the Yes button
becomes the only button.
-->

---
kicker: Technical stack
---

# What it is made of, and where it stops.

| Technology | Role | Why | Limit |
|---|---|---|---|
| **Godot 4.7.2 / GDScript** | engine, all logic | free, scriptable, strong 2D, headless testing | loose typing at the edges; some errors only at runtime |
| **Procedural drawing** | almost all art | exact 320×180 pixel grid; every element parameterised and testable | no shader pipeline — the Day 4 blur is a tear effect |
| **Fixed virtual resolution** 320×180 / 640×360 desktop | composition | the player stays on centre and the ground row is fixed by construction | text under ~10 px is unreadable |
| **Test gates** | correctness | 414 module checks + a 112-check full seven-day playthrough | pixel-reading tests need a window |
| **Missing: audio** | — | — | no sound at all; a known gap, not a choice |

<!--
09:20–10:00 · 40 seconds

Explain the stack in your own words — do not read it.

Why Godot: free, scriptable, and headless mode lets me test the game without a screen.
That matters because the whole day loop is a state machine, and I can prove the order
cannot be broken.

Why procedural art: at 320×180 every element has to sit on the pixel grid. Drawing in
code means no asset pipeline and no filtering artefacts — and each element is a
function I can test.

Honest limits: no shaders, so the Day 4 "blur" is a tear effect, not a blur. And no
audio at all — recorded as a gap, not presented as a choice.
-->

---
kicker: Close
---

# The form outlives the observation.

<div class="body col">
<div class="frame"><span class="label">What I still owe this argument</span><div class="text">· Read Gitelman and Fisher, and locate one passage in each.<br />· Test whether the silence is atmosphere or just an unfinished build.<br />· Find out whether a player reads the forced Yes as <mark>the argument</mark> or as a bug.</div></div>
</div>

::foot::

Thank you — questions welcome.

<!--
09:40–10:00

Close on the sentence, then immediately name the three things you have not finished.
Owning the gaps is stronger than being asked about them.

Expected questions:
1. "Why a game and not a paper?" — because the claim is about an instrument being
   operated. A reader can be told the form refuses No; a player finds out.
2. "Is the minigame just a joke?" — no, it is the counter-form; the only number the
   player wants.
3. "Isn't the forced Yes just bad UX?" — possibly, and that is an open question in the
   design document. If it reads as a bug, the argument fails, and I would need to make
   the refusal legible without explaining it.
-->
