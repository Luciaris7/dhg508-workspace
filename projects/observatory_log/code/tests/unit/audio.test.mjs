// The audio buses must exist *before* the audio driver starts.
//
// Why this file exists: the game used to create Music / SFX / Amb at runtime in
// Sfx._ready. The web export initialises its AudioContext with nothing but the
// Master bus, and buses appended afterwards never reach the output, so the whole
// game was silent in the browser while the desktop build was fine (2026-11-17).
// The fix was to ship the layout as a project resource; these tests keep it shipped.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { read, exists } from './helpers.mjs';

const LAYOUT = 'default_bus_layout.tres';
const REQUIRED = ['Master', 'Music', 'SFX', 'Amb'];

function layoutBuses() {
  const text = read(LAYOUT);
  return [...text.matchAll(/bus\/(\d+)\/name = &"([^"]+)"/g)]
    .map((m) => ({ index: Number(m[1]), name: m[2] }))
    .sort((a, b) => a.index - b.index);
}

test('the project ships an audio bus layout', () => {
  assert.ok(exists(LAYOUT), `${LAYOUT} must exist`);
  const project = read('project.godot');
  assert.match(project, /default_bus_layout\s*=\s*"res:\/\/default_bus_layout\.tres"/,
    'project.godot must point at the layout');
});

test('the layout defines every bus the game plays through', () => {
  const names = layoutBuses().map((b) => b.name);
  assert.deepEqual(names, REQUIRED, `bus order/name drift: ${names.join(', ')}`);
});

test('every non-master bus sends to Master', () => {
  const text = read(LAYOUT);
  for (const { index, name } of layoutBuses()) {
    if (name === 'Master') continue;
    const re = new RegExp(`bus/${index}/send = &"Master"`);
    assert.match(text, re, `bus "${name}" must send to Master`);
  }
});

test('no script invents a bus that the layout does not define', () => {
  const defined = new Set(layoutBuses().map((b) => b.name));
  const used = new Set();
  for (const file of ['scripts/autoload/sfx.gd']) {
    const text = read(file);
    for (const m of text.matchAll(/"(Master|Music|SFX|Amb)"/g)) used.add(m[1]);
  }
  const missing = [...used].filter((b) => !defined.has(b));
  assert.deepEqual(missing, [], 'script references buses missing from the layout');
});

test('Sfx may still create missing buses as a desktop fallback', () => {
  // Runtime creation stays as a safety net on platforms where the layout is not
  // loaded, but it must not be the only way the buses come into existence.
  const sfx = read('scripts/autoload/sfx.gd');
  assert.match(sfx, /if AudioServer\.get_bus_index\(b\) == -1:/);
});
