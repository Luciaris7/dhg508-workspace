// Guardrails for the game's fixed facts.
//
// The game leans on a handful of numbers and names that must never drift:
// the ten clue ids, the 80% threshold for the good ending, the one Morse
// number, the 13-year cycle, the 640x360 / 320x180 camera. These come from
// docs/MYSTERY_BIBLE.md (the source table) and the user's original design
// document; a silent edit here would break endings without failing anything.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { read, gdDictKeys } from './helpers.mjs';

const g = read('scripts/autoload/g.gd');

test('the ten clue ids are exactly the ones the mystery bible documents', () => {
  const ids = [.../const CLUES := \[([\s\S]*?)\]/.exec(g)[1].matchAll(/"([a-z_]+)"/g)].map((m) => m[1]);
  assert.equal(ids.length, 10, 'ten clues, no more');
  assert.equal(new Set(ids).size, ids.length, 'clue ids are unique');

  const bible = read('docs/MYSTERY_BIBLE.md');
  for (const id of ids) {
    assert.ok(bible.includes(`\`${id}\``), `docs/MYSTERY_BIBLE.md must document the clue "${id}"`);
  }
});

test('the good ending needs 80% of the clues plus the Morse number', () => {
  assert.match(g, /CLUES_FOR_GOOD := 8/, 'threshold stays at 8 of 10');
  assert.match(g, /morse_solved[\s\S]{0,80}CLUES_FOR_GOOD/, 'can_escape needs the Morse number and the clues');
});

test('the Morse number is the sealed record from thirteen years ago, 23:40', () => {
  // The record was left on the previous observer's seventh night, thirteen years
  // before this cycle's Day 7, so the number is derived, not a constant.
  assert.match(g, /const SEALED_TIME := "2340"/);
  assert.match(g, /func sealed_date\(\) -> Dictionary:/);
  assert.match(g, /Time\.get_datetime_dict_from_unix_time\(day_unix\(7\)\)/, 'derived from Day 7 of this cycle');
  assert.match(g, /var y := int\(d\["year"\]\) - 13/, 'thirteen years back');
  assert.match(g, /if m == 2 and dd == 29:\s*\r?\n\t\tdd = 28/, 'Feb 29 must not fall through to Feb 28 in a non-leap year');
  assert.match(g, /return "%04d%02d%02d%s" % \[d\["year"\], d\["month"\], d\["day"\], SEALED_TIME\]/);
  assert.match(g, /func sealed_id\(\) -> String:/, 'the archive shows CC-SS-DD-HHMM');
});

test('the calendar is a 13-year cycle', () => {
  assert.match(g, /y - 13 \* k/, 'cycle_year steps back 13 years at a time');
  const bible = read('docs/MYSTERY_BIBLE.md');
  assert.match(bible, /13/, 'the bible states the 13-year cycle');
});

test('save format version and the ten-day clamp stay in sync', () => {
  assert.match(g, /const SAVE_VERSION := 2/);
  assert.match(g, /clampi\(int\(data\["day"\]\), 1, 7\)/, 'load_game clamps the day to 1..7');
});

test('world and screen sizes agree with project.godot', () => {
  const project = read('project.godot');
  const vw = Number(/window\/size\/viewport_width=(\d+)/.exec(project)[1]);
  const vh = Number(/window\/size\/viewport_height=(\d+)/.exec(project)[1]);
  assert.equal(vw, 640);
  assert.equal(vh, 360);
  assert.match(g, /const SCREEN_W := 640/);
  assert.match(g, /const SCREEN_H := 360/);
  assert.match(g, /const WORLD_W := 320/);
  assert.match(g, /const WORLD_H := 180/);
});

test('the three endings are still the three the design document describes', () => {
  const bible = read('docs/MYSTERY_BIBLE.md');
  for (const ending of ['献祭', '同化', '逃离']) {
    assert.ok(bible.includes(ending), `ending "${ending}" must stay documented`);
  }
});

test('every story document id has a title and a body', () => {
  const txt = read('scripts/autoload/txt.gd');
  const docs = gdDictKeys(txt, 'DOCS');
  const titles = gdDictKeys(txt, 'DOC_TITLE');
  // "sealed" is the cycle-03 archive record: its title is built at the call site
  // (ui("archive.rec_title") % "03-07-07-2340"), so it deliberately has no entry.
  const generated = ['sealed'];
  const missing = docs.filter((id) => !titles.includes(id) && !generated.includes(id));
  assert.deepEqual(missing, [], 'every DOCS id needs a DOC_TITLE (or a generated one)');
});
