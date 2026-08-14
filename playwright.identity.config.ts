import { defineConfig } from '@playwright/test'
import base from './web-app/playwright.config'

// Temp runner config for the identity chunk: run against a dedicated dev
// server on :5174 (the :5173 server belongs to a parallel chunk's checkout)
// while keeping the repo's playwright.config.ts untouched.
export default defineConfig({
  ...base,
  testDir: '/tmp/orbit-work/identity/web-app/e2e',
  use: { ...base.use, baseURL: 'http://localhost:5174' },
  webServer: {
    ...base.webServer!,
    command: 'npm run dev -- --port 5174 --strictPort',
    url: 'http://localhost:5174',
    cwd: '/tmp/orbit-work/identity/web-app',
  },
})
