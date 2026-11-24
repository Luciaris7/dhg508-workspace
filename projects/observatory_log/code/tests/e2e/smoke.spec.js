// Browser feedback loop for the Godot web build.
// Runs against the local dist/ (npm run test:e2e) or against the deployed site
// (GAME_URL=https://... npx playwright test).
const { test, expect } = require('@playwright/test');

const BOOT_MS = 20000;

async function boot(page, url = '/') {
  const consoleErrors = [];
  const pageErrors = [];
  const failedRequests = [];
  const badResponses = [];
  const engineLogs = [];

  page.on('console', (msg) => {
    const text = msg.text();
    if (text.includes('Godot Engine')) engineLogs.push(text);
    if (msg.type() === 'error') consoleErrors.push(text);
  });
  page.on('pageerror', (err) => pageErrors.push(String(err)));
  page.on('requestfailed', (req) => failedRequests.push(`${req.url()} ${req.failure()?.errorText}`));
  page.on('response', (res) => {
    if (res.status() >= 400) badResponses.push(`${res.status()} ${res.url()}`);
  });

  await page.goto(url, { waitUntil: 'load' });
  await page.waitForTimeout(BOOT_MS);
  return { consoleErrors, pageErrors, failedRequests, badResponses, engineLogs };
}

test('the deployed game boots with no console, network or engine errors', async ({ page, request }) => {
  const report = await boot(page);

  await expect(page.locator('#canvas')).toBeVisible();
  const canvas = await page.evaluate(() => {
    const c = document.getElementById('canvas');
    const gl = c.getContext('webgl2') || c.getContext('webgl');
    return { w: c.width, h: c.height, gl: !!gl, version: gl && gl.getParameter(gl.VERSION) };
  });
  test.info().annotations.push({ type: 'canvas', description: JSON.stringify(canvas) });

  expect(canvas.gl, 'canvas has a WebGL context').toBe(true);
  expect(canvas.w).toBeGreaterThan(0);
  expect(report.badResponses, 'no 4xx/5xx').toEqual([]);
  expect(report.failedRequests, 'no failed requests').toEqual([]);
  expect(report.pageErrors, 'no uncaught page errors').toEqual([]);
  expect(report.consoleErrors, 'no console errors').toEqual([]);
  expect(report.engineLogs.join(' '), 'Godot engine banner').toMatch(/Godot Engine v4\./);

  await page.screenshot({ path: 'test-results/boot.png' });
});

test('the wasm is served as a real WebAssembly module', async ({ request }) => {
  // Pages caps a single *stored* asset at 25 MiB, so the wasm ships gzipped and
  // the worker inflates it; what the engine receives must be plain wasm bytes.
  const res = await request.get('/index.wasm');
  expect(res.status()).toBe(200);
  expect(res.headers()['content-type']).toContain('application/wasm');

  const body = await res.body();
  expect(body.slice(0, 4).toString('latin1'), 'wasm magic word').toBe('\0asm');
  expect(body.length).toBeGreaterThan(20 * 1024 * 1024);
});

test('the game renders and reacts to input', async ({ page }) => {
  const report = await boot(page);
  const canvas = page.locator('#canvas');

  const first = await canvas.screenshot();
  await canvas.click();
  for (const key of ['Enter', 'KeyE', 'KeyE', 'KeyD', 'KeyD', 'KeyA']) {
    await page.keyboard.press(key);
    await page.waitForTimeout(700);
  }
  await page.waitForTimeout(3000);
  const second = await canvas.screenshot({ path: 'test-results/after-input.png' });

  expect(report.consoleErrors).toEqual([]);
  expect(first.length, 'canvas is not blank').toBeGreaterThan(5000);
  expect(Buffer.compare(first, second), 'the frame changed after input').not.toBe(0);
});

test('renders on a phone-sized screen without clipping or crashing', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  const report = await boot(page);
  const canvas = page.locator('#canvas');
  await expect(canvas).toBeVisible();

  const box = await canvas.boundingBox();
  expect(box.width).toBeGreaterThan(100);
  expect(box.height).toBeGreaterThan(100);

  // The stock shell left the canvas at the phone's own size, so Godot rendered a
  // 640-wide frame into a 390 px window and clipped both sides (docs/user-feedback.md I5).
  // With the project canvas policy the whole 16:9 frame is rendered and CSS fits it.
  const layout = await page.evaluate(() => {
    const c = document.getElementById('canvas');
    const rect = c.getBoundingClientRect();
    return {
      innerW: window.innerWidth,
      scrollW: document.documentElement.scrollWidth,
      rectW: rect.width,
      bitmapW: c.width,
      bitmapH: c.height,
      aspect: c.width / c.height,
    };
  });
  expect(layout.rectW, 'canvas fits the viewport width').toBeLessThanOrEqual(layout.innerW + 1);
  expect(layout.scrollW, 'the page does not scroll sideways').toBeLessThanOrEqual(layout.innerW + 1);
  expect(layout.bitmapW, 'the whole frame is rendered, not a cropped one').toBeGreaterThanOrEqual(640);
  expect(layout.aspect, 'the frame keeps the 16:9 aspect').toBeCloseTo(16 / 9, 1);

  expect(report.pageErrors).toEqual([]);
  expect(report.consoleErrors).toEqual([]);
  await page.screenshot({ path: 'test-results/mobile.png' });
});
