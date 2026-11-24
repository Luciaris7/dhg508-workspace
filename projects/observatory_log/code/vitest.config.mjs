import { defineConfig } from 'vitest/config';

// The unit suites in tests/unit are written against node:test so they can also
// run with plain `node --test` (no extra runtime). Vitest is the command the
// course asks for, so alias node:test to vitest here instead of maintaining two
// copies of the same assertions.
export default defineConfig({
  resolve: {
    alias: {
      'node:test': 'vitest',
    },
  },
  test: {
    include: ['tests/unit/**/*.test.mjs'],
    // The E2E spec needs a running browser and lives under tests/e2e.
    exclude: ['tests/e2e/**', 'node_modules/**'],
  },
});
