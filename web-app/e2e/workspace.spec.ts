import { test, expect } from '@playwright/test'

// Orbit Browser — E2E: the workspace shell features must actually work.

test('universe dock renders with all places', async ({ page }) => {
  await page.goto('/')
  const dock = page.locator('.orbit-dock')
  await expect(dock).toBeVisible()
  // Universe, Plugn, Yo3an, Planner, Mail, Storage
  await expect(dock.locator('.dock-item')).toHaveCount(6)
})

test('banana counter is visible in the dock', async ({ page }) => {
  await page.goto('/')
  await expect(page.locator('.dock-profile')).toContainText('🍌')
})

test('orbit sidecar opens, chats, and closes', async ({ page }) => {
  await page.goto('/')
  const sidecar = page.locator('.orbit-sidecar')
  await expect(sidecar).toBeVisible()

  // Bot message demo renders
  await expect(sidecar.locator('.msg.bot').first()).toContainText('Orbit assistant')

  // Close → reopen button appears
  await sidecar.locator('.sidecar-header button').click()
  await expect(sidecar).toBeHidden()
  await expect(page.locator('.sidecar-reopen')).toBeVisible()

  // Reopen works
  await page.locator('.sidecar-reopen').click()
  await expect(sidecar).toBeVisible()
})

test('viewport shows UniverseOS offline-ready status', async ({ page }) => {
  await page.goto('/')
  await expect(page.locator('.viewport-status')).toContainText('UniverseOS')
  await expect(page.locator('.viewport-status')).toContainText('pre-cached')
})

test('service worker registers and activates (precache path)', async ({ page }) => {
  await page.goto('/')
  // SW activation is async — wait for an active registration
  const activated = await page.evaluate(
    () =>
      new Promise<boolean>((resolve) => {
        if (!('serviceWorker' in navigator)) return resolve(false)
        const check = () => {
          navigator.serviceWorker.getRegistrations().then((regs) => {
            if (regs.some((r) => r.active)) resolve(true)
            else setTimeout(check, 250)
          })
        }
        check()
        // safety timeout
        setTimeout(() => resolve(false), 10_000)
      }),
  )
  expect(activated).toBe(true)
})

test('app is installable (manifest present)', async ({ page }) => {
  await page.goto('/')
  const manifest = await page.evaluate(() => document.querySelector('link[rel="manifest"]')?.getAttribute('href'))
  expect(manifest).toBeTruthy()
})

test('URL input: user can type a URL and navigate (regression guard)', async ({ page }) => {
  await page.goto('/')
  const input = page.getByLabel('URL input')
  await expect(input).toBeVisible()

  // Type a URL
  await input.fill('https://browser.bawes')
  await input.press('Enter')

  // The chrome reflects the navigated URL
  await expect(page.getByTestId('current-url')).toContainText('https://browser.bawes')

  // URL without scheme gets normalized
  await input.fill('universe.bawes')
  await input.press('Enter')
  await expect(page.getByTestId('current-url')).toContainText('https://universe.bawes')

  // Empty input falls back to the default
  await input.fill('')
  await input.press('Enter')
  await expect(page.getByTestId('current-url')).toContainText('browser.bawes')
})

test('tabs: open, switch, close (T-003 regression guard)', async ({ page }) => {
  await page.goto('/')

  // One default tab
  await expect(page.locator('.tab')).toHaveCount(1)

  // Open a second tab
  await page.locator('.tab-new').click()
  await expect(page.locator('.tab')).toHaveCount(2)
  await expect(page.getByRole('tab', { selected: true })).toHaveCount(1)

  // Navigate in the active (new) tab
  await page.getByLabel('URL input').fill('universe.bawes')
  await page.getByLabel('URL input').press('Enter')
  await expect(page.getByTestId('viewport-url')).toContainText('universe.bawes')

  // Switch back to the first tab — its URL is preserved
  await page.locator('.tab').first().click()
  await expect(page.getByTestId('viewport-url')).toContainText('browser.bawes')

  // Close a tab
  await page.locator('.tab').first().locator('.tab-close').click()
  await expect(page.locator('.tab')).toHaveCount(1)

  // Closing the last tab creates a fresh one (never zero tabs)
  await page.locator('.tab-close').first().click()
  await expect(page.locator('.tab')).toHaveCount(1)
  await expect(page.getByTestId('viewport-url')).toContainText('browser.bawes')
})
