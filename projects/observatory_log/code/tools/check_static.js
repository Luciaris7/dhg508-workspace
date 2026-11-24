#!/usr/bin/env node
// Fast static gate (<1s): every res:// reference resolves, the project boots
// from a real scene, data files parse, the web preset exists, and no local
// machine paths or API keys leaked into the repository.
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
let checks = 0;
const failures = [];

function ok(name) {
  checks++;
}

function fail(name, detail) {
  checks++;
  failures.push(`${name}: ${detail}`);
}

function read(rel) {
  return fs.readFileSync(path.join(root, rel), 'utf8');
}

function exists(rel) {
  return fs.existsSync(path.join(root, rel));
}

// ---------------------------------------------------------------- project.godot
const projectPath = 'project.godot';
if (!exists(projectPath)) {
  fail('project.godot', 'missing');
} else {
  const godot = read(projectPath);
  const main = /run\/main_scene="res:\/\/([^"]+)"/.exec(godot);
  main && exists(main[1]) ? ok('main_scene') : fail('main_scene', `not found: ${main ? main[1] : '(no main_scene)'}`);

  const autoloads = [...godot.matchAll(/^\w+="\*res:\/\/([^"]+)"/gm)].map((m) => m[1]);
  autoloads.length
    ? autoloads.forEach((a) => (exists(a) ? ok(`autoload ${a}`) : fail('autoload', `missing ${a}`)))
    : fail('autoload', 'no autoloads parsed');
}

// ------------------------------------------------------------- res:// references
const sourceFiles = [];
(function walk(dir) {
  for (const entry of fs.readdirSync(path.join(root, dir), { withFileTypes: true })) {
    const rel = path.posix.join(dir, entry.name);
    if (entry.isDirectory()) {
      if (['.godot', '.git', 'node_modules', 'builds', 'dist'].includes(entry.name)) continue;
      walk(rel);
    } else if (/\.(gd|tscn|tres|gdshader)$/.test(entry.name)) {
      sourceFiles.push(rel);
    }
  }
})('.');

const seen = new Set();
let refCount = 0;
// Only literals with a real file extension: paths built at runtime
// ("res://assets/art/desk/icon_" + name) end at the quote before the operator.
const STATIC_REF = /res:\/\/([\w./-]+?\.(?:png|jpg|jpeg|json|bin|gd|tscn|tres|gdshader|otf|ttf|wav|ogg|txt|cfg|import))(?=["')])/g;
for (const file of sourceFiles) {
  const text = fs.readFileSync(path.join(root, file), 'utf8');
  for (const m of text.matchAll(STATIC_REF)) {
    const target = m[1];
    if (target.startsWith('user://')) continue;
    refCount++;
    if (seen.has(target)) continue;
    seen.add(target);
    exists(target) ? ok(`res://${target}`) : fail('res://', `${target} (referenced by ${file})`);
  }
}
refCount ? ok('references scanned') : fail('references', 'none found');

// ------------------------------------------------------------------- data files
const dataFiles = [];
(function collect(dir) {
  if (!exists(dir)) return;
  for (const entry of fs.readdirSync(path.join(root, dir), { withFileTypes: true })) {
    const rel = path.posix.join(dir, entry.name);
    if (entry.isDirectory()) collect(rel);
    else if (entry.name.endsWith('.json')) dataFiles.push(rel);
  }
})('assets/data');

dataFiles.length ? ok('data files') : fail('data', 'no assets/data/*.json found');
for (const file of dataFiles) {
  try {
    JSON.parse(fs.readFileSync(path.join(root, file), 'utf8'));
    ok(file);
  } catch (err) {
    fail('json', `${file}: ${err.message}`);
  }
}

// ----------------------------------------------------------------- export presets
if (!exists('export_presets.cfg')) {
  fail('export_presets.cfg', 'missing');
} else {
  const presets = read('export_presets.cfg');
  /platform="Web"/.test(presets) ? ok('Web preset') : fail('Web preset', 'no platform="Web" preset');
  /variant\/thread_support=false/.test(presets)
    ? ok('web threads off')
    : fail('web threads', 'thread_support must stay false (no COOP/COEP headers)');
}

// ------------------------------------------------------- local paths and secrets
const textExtensions = /\.(gd|tscn|cfg|md|json|js|ps1|bat|txt|py|shader)$/i;
const skipDirs = /(^|[\\/])(\.godot|\.git|node_modules|builds|dist|\.wrangler|tests[\\/]_logs)([\\/]|$)/;
const leaks = [];
for (const file of (function all(dir) {
  const out = [];
  for (const entry of fs.readdirSync(path.join(root, dir), { withFileTypes: true })) {
    const rel = path.posix.join(dir, entry.name);
    if (skipDirs.test(rel)) continue;
    if (entry.isDirectory()) out.push(...all(rel));
    else if (textExtensions.test(entry.name)) out.push(rel);
  }
  return out;
})('.')) {
  // docs/sources/ holds the user's verbatim source documents (early script,
  // revision notes, the work list, the inspiration deck). They are archive
  // material and are deliberately not rewritten to hide machine paths.
  if (file.startsWith('docs/sources/')) continue;
  const text = fs.readFileSync(path.join(root, file), 'utf8');
  const localPath = /(?:[A-Za-z]:\\+Users\\+(?!<)[^\\\s"]+|D:\\+project 1)/.test(text);
  const secret = /\b(sk-[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{30,}|CF_API_TOKEN\s*=\s*\S+)/.test(text);
  if (localPath) leaks.push(`${file}: absolute local path`);
  if (secret) leaks.push(`${file}: looks like a credential`);
}
leaks.length ? leaks.forEach((l) => fail('leak', l)) : ok('no local paths or secrets');

// ------------------------------------------------------------------------ report
console.log(`CHECK: ${checks - failures.length} passed, ${failures.length} failed (${sourceFiles.length} source files)`);
for (const f of failures) console.log(`  FAIL ${f}`);
if (failures.length) process.exit(1);
