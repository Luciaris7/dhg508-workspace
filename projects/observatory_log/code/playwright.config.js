const { defineConfig } = require('@playwright/test');

const baseURL = process.env.GAME_URL || 'http://127.0.0.1:8788';

module.exports = defineConfig({
  testDir: './tests/e2e',
  timeout: 180000,
  expect: { timeout: 20000 },
  workers: 1,
  fullyParallel: false,
  reporter: [['list']],
  use: {
    baseURL,
    // Edge ships with Windows. Set PW_CHANNEL=chromium after `npx playwright install chromium`.
    channel: process.env.PW_CHANNEL || 'msedge',
    headless: true,
    viewport: { width: 1280, height: 720 },
    launchOptions: {
      args: ['--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--autoplay-policy=no-user-gesture-required'],
    },
  },
  // Against the deployed URL (GAME_URL=https://...) there is no local server to start.
  webServer: process.env.GAME_URL
    ? undefined
    : {
        command: 'node tools/serve.js dist 8788',
        url: 'http://127.0.0.1:8788/index.html',
        reuseExistingServer: true,
        timeout: 30000,
      },
});
