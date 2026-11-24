// Small helpers shared by the unit suites (run by node:test or vitest).
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, '..', '..');

function read(rel) {
  return fs.readFileSync(path.join(root, rel), 'utf8');
}

function exists(rel) {
  return fs.existsSync(path.join(root, rel));
}

/** Top-level keys of a `const NAME := { ... }` dictionary literal in GDScript. */
function gdDictKeys(text, name) {
  const lines = text.split(/\r?\n/);
  const start = lines.findIndex((l) => l.startsWith(`const ${name}`));
  if (start < 0) throw new Error(`dictionary ${name} not found`);
  const keys = [];
  for (let i = start + 1; i < lines.length; i++) {
    const line = lines[i];
    if (line === '}') break;
    const m = /^\t"([^"]+)"\s*:/.exec(line);
    if (m) keys.push(m[1]);
  }
  return keys;
}

/** Number of top-level string items in a `const NAME := [ ... ]` array literal. */
function gdArrayLength(text, name) {
  const lines = text.split(/\r?\n/);
  const start = lines.findIndex((l) => l.startsWith(`const ${name}`));
  if (start < 0) throw new Error(`array ${name} not found`);
  let count = 0;
  for (let i = start + 1; i < lines.length; i++) {
    const line = lines[i];
    if (line === ']') break;
    if (/^\t"/.test(line)) count++;
  }
  return count;
}

/** Scripts under scripts/ (recursively), used by the cross-file id checks. */
function gdScripts(dir = 'scripts', out = []) {
  for (const entry of fs.readdirSync(path.join(root, dir), { withFileTypes: true })) {
    const rel = path.posix.join(dir, entry.name);
    if (entry.isDirectory()) gdScripts(rel, out);
    else if (entry.name.endsWith('.gd')) out.push(rel);
  }
  return out;
}

export { root, read, exists, gdDictKeys, gdArrayLength, gdScripts };
