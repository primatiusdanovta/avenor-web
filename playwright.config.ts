import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests/e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: [['list'], ['html', { open: 'never' }]],
  use: {
    baseURL: 'http://127.0.0.1:8010',
    trace: 'retain-on-failure',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    ignoreHTTPSErrors: true,
  },
  webServer: {
    command: 'powershell -ExecutionPolicy Bypass -File ./tools/e2e-server.ps1',
    url: 'http://127.0.0.1:8010/administrator/login',
    reuseExistingServer: false,
    timeout: 180000,
  },
  projects: [
    {
      name: 'desktop-chromium',
      use: { ...devices['Desktop Chrome'], browserName: 'chromium', viewport: { width: 1440, height: 960 } },
      testMatch: /.*\.spec\.ts/,
    },
    {
      name: 'desktop-firefox',
      use: { ...devices['Desktop Firefox'], browserName: 'firefox', viewport: { width: 1440, height: 960 } },
      testMatch: /auth\.spec\.ts/,
    },
    {
      name: 'tablet-chromium',
      use: { ...devices['iPad (gen 7)'], browserName: 'chromium', viewport: { width: 820, height: 1180 } },
      testMatch: /responsive\.spec\.ts/,
    },
    {
      name: 'mobile-chromium',
      use: { ...devices['Pixel 7'], browserName: 'chromium' },
      testMatch: /responsive\.spec\.ts/,
    },
  ],
});
