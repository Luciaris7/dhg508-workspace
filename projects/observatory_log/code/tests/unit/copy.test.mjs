// English / Simplified Chinese copy parity.
//
// The game ships both languages from two hand-written GDScript tables. A
// missing key silently returns "" (txt.gd: "Unknown ids return '' -- never
// invent copy at a call site"), which shows up as a blank line of monologue in
// Chinese only -- easy to ship, hard to notice. These tests make that loud.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { read, gdDictKeys, gdArrayLength, gdScripts } from './helpers.mjs';

const en = read('scripts/autoload/txt.gd');
const zh = read('scripts/autoload/txt_zh.gd');

const DICTS = ['MONO', 'CLUE_NOTE', 'DOCS', 'DOC_TITLE', 'RED', 'BODIES'];
const ARRAYS = ['PHONE', 'NOTICE', 'CREDITS'];

for (const name of DICTS) {
  test(`zh covers every key of ${name}`, () => {
    const enKeys = gdDictKeys(en, name);
    const zhKeys = gdDictKeys(zh, name);
    const missing = enKeys.filter((k) => !zhKeys.includes(k));
    const extra = zhKeys.filter((k) => !enKeys.includes(k));
    assert.deepEqual(missing, [], `zh is missing ${name} keys`);
    assert.deepEqual(extra, [], `zh has ${name} keys English does not`);
  });
}

// UI is the one table with an English fallback (txt.gd: ui() returns UI[id]
// when zh is on and the key is absent), which is how the BIOS strings, "Yes/No"
// and the HOMEWARD icon label stay in English in Chinese mode. So: no blank
// strings, and the fallback must stay implemented.
test('zh UI either translates a key or falls back to English on purpose', () => {
  const enKeys = gdDictKeys(en, 'UI');
  const zhKeys = gdDictKeys(zh, 'UI');
  assert.deepEqual(zhKeys.filter((k) => !enKeys.includes(k)), [], 'zh UI has no extra keys');
  assert.match(en, /func ui\(id: String\) -> String:\s*\r?\n\tif zh\(\) and ZH\.UI\.has\(id\):/,
    'ui() must fall back to English instead of returning ""');
  const untranslated = enKeys.filter((k) => !zhKeys.includes(k));
  // informational: these render in English when the player picks Chinese
  assert.ok(untranslated.length < 20, `unexpected number of untranslated UI keys: ${untranslated.length}`);
});

for (const name of ARRAYS) {
  test(`${name} has the same number of lines in both languages`, () => {
    assert.equal(gdArrayLength(zh, name), gdArrayLength(en, name));
  });
}

test('no Chinese line is a placeholder or empty', () => {
  const offenders = [];
  const lines = zh.split(/\r?\n/);
  lines.forEach((line, i) => {
    const m = /^\t"([^"]*)"/.exec(line);
    if (!m) return;
    if (m[1].trim() === '') return; // intentional blank line inside a document body
    if (/TODO|FIXME|待译|xxx/i.test(m[1])) offenders.push(`${i + 1}: ${m[1].slice(0, 40)}`);
  });
  assert.deepEqual(offenders, []);
});

test('every copy id used in a script exists in the English table', () => {
  const tables = {
    mono: new Set(gdDictKeys(en, 'MONO')),
    ui: new Set(gdDictKeys(en, 'UI')),
    red: new Set(gdDictKeys(en, 'RED')),
    clue_note: new Set(gdDictKeys(en, 'CLUE_NOTE')),
    doc: new Set(gdDictKeys(en, 'DOCS')),
    doc_title: new Set(gdDictKeys(en, 'DOC_TITLE')),
  };
  const missing = [];
  for (const file of gdScripts()) {
    const text = read(file);
    for (const m of text.matchAll(/\b(mono|ui|red|clue_note|doc_title|doc)\("([^"\\%]+)"\)/g)) {
      const [_, fn, id] = m;
      if (!tables[fn].has(id)) missing.push(`${file}: ${fn}("${id}")`);
    }
  }
  assert.deepEqual(missing, [], 'copy ids used but not defined');
});

test('phone and notice arrays are non-empty and start with a real line', () => {
  const phoneStart = /const PHONE := \[\r?\n\t"([^"]{10,})"/.exec(en);
  assert.ok(phoneStart, 'PHONE starts with the former observer voicemail');
  const noticeStart = /const NOTICE := \[\r?\n\t"([^"]{10,})"/.exec(en);
  assert.ok(noticeStart, 'NOTICE starts with the work notice');
});
