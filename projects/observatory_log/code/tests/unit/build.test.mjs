// Invariants of the deployable artifact (dist/), i.e. the contract with
// Cloudflare Pages. Skipped when dist/ has not been built yet (npm run build:web).
import { test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { root, exists } from './helpers.mjs';

const dist = path.join(root, 'dist');
const built = fs.existsSync(dist);
const skip = built ? false : 'dist/ not built (run npm run build:web)';

test('dist is smaller than the Pages per-asset limit and ships no raw wasm', { skip }, () => {
  assert.ok(!fs.existsSync(path.join(dist, 'index.wasm')), 'raw index.wasm must not be deployed');

  const files = [];
  for (const entry of fs.readdirSync(dist, { recursive: true, withFileTypes: true })) {
    if (entry.isFile()) files.push(path.join(entry.parentPath || entry.path, entry.name));
  }
  const largest = files.map((f) => ({ f, size: fs.statSync(f).size })).sort((a, b) => b.size - a.size)[0];
  assert.ok(largest.size <= 25 * 1024 * 1024, `largest asset ${path.basename(largest.f)} is ${(largest.size / 1048576).toFixed(1)} MiB > 25 MiB`);
});

test('the gzipped wasm is a real gzip stream', { skip }, () => {
  const gz = fs.readFileSync(path.join(dist, 'index.wasm.gz'));
  assert.equal(gz[0], 0x1f);
  assert.equal(gz[1], 0x8b);
  assert.ok(gz.length > 1024 * 1024, 'wasm payload looks too small');
});

test('the deploy folder contains the files Cloudflare needs', { skip }, () => {
  for (const file of ['index.html', 'index.js', 'index.pck', '_headers', '_worker.js']) {
    assert.ok(exists(path.join('dist', file)), `dist/${file} missing`);
  }
  const sidecars = fs.readdirSync(dist, { recursive: true }).filter((f) => String(f).endsWith('.import'));
  assert.deepEqual(sidecars, [], 'Godot .import sidecar files must not be deployed');
});

test('index.html loads the engine and exposes a canvas', { skip }, () => {
  const html = fs.readFileSync(path.join(dist, 'index.html'), 'utf8');
  assert.match(html, /id="canvas"/);
  assert.match(html, /index\.js/);
  assert.match(html, /GODOT_CONFIG/);
});

test('the shell letterboxes the canvas to the viewport', { skip }, () => {
  // Without this the canvas keeps its 640 CSS px width and a phone clips it.
  const html = fs.readFileSync(path.join(dist, 'index.html'), 'utf8');
  assert.match(html, /viewport-fit/);
  assert.match(html, /object-fit:\s*contain/);
  assert.match(html, /image-rendering:\s*pixelated/);
});

test('the live shell carries the required note: context, 据/推断/设, AI tools', { skip }, () => {
  // Week 11 asks for a short note on the live page. It is injected by
  // tools/patch_shell.js, so it only exists in dist/, never in the source tree.
  const html = fs.readFileSync(path.join(dist, 'index.html'), 'utf8');
  assert.match(html, /observation-log\/light:about-note/, 'About note missing: patch_shell.js did not run');
  assert.match(html, /id="about-note"/);
  for (const tier of ['据', '推断', '设']) {
    assert.ok(html.includes(tier), `the About note must name the ${tier} tier`);
  }
  assert.match(html, /Claude Opus/, 'the About note must name the AI tools used');
  assert.match(html, /id="about-toggle"/, 'the About note must stay collapsible, not cover the canvas');
});

test('the worker inflates the wasm back to application/wasm', { skip }, () => {
  const worker = fs.readFileSync(path.join(dist, '_worker.js'), 'utf8');
  assert.match(worker, /DecompressionStream\('gzip'\)/);
  assert.match(worker, /application\/wasm/);
  assert.match(worker, /ASSETS\.fetch/);
});
