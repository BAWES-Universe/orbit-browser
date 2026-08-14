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

test('sidecar expands and collapses via its toggle', async ({ page }) => {
  await page.goto('/')
  const sidecar = page.locator('.orbit-sidecar')
  const collapse = page.getByRole('button', { name: 'Collapse sidecar' })
  const reopen = page.getByRole('button', { name: 'Open sidecar' })

  // Starts expanded
  await expect(sidecar).toBeVisible()
  await expect(collapse).toHaveAttribute('aria-expanded', 'true')

  // Collapse → panel gone, floating reopen button appears (aria-expanded flips)
  await collapse.click()
  await expect(sidecar).toBeHidden()
  await expect(reopen).toBeVisible()
  await expect(reopen).toHaveAttribute('aria-expanded', 'false')

  // Expand again → panel back, toggle state restored
  await reopen.click()
  await expect(sidecar).toBeVisible()
  await expect(collapse).toHaveAttribute('aria-expanded', 'true')
})

test('sidecar quick actions render and wire to shell behavior', async ({ page }) => {
  await page.goto('/')
  const sidecar = page.locator('.orbit-sidecar')

  // All three quick actions render
  await expect(sidecar.locator('.quick-actions .qa-button')).toHaveCount(3)
  await expect(page.getByRole('button', { name: 'Spawn a Brick' })).toBeVisible()
  await expect(page.getByRole('button', { name: 'Open Universe' })).toBeVisible()
  await expect(page.getByRole('button', { name: 'View Bananas' })).toBeVisible()

  // Fleet status renders all four bricks (demo data)
  await expect(page.getByTestId('fleet-brick')).toContainText('online')
  await expect(page.getByTestId('fleet-zero')).toBeVisible()
  await expect(page.getByTestId('fleet-hermes-local')).toContainText('offline')
  await expect(page.getByTestId('fleet-zeus')).toBeVisible()

  // Open Universe is wired to the shell's real navigation
  await page.getByRole('button', { name: 'Open Universe' }).click()
  await expect(page.getByTestId('current-url')).toContainText('https://universe.bawes')

  // Spawn a Brick appends a clearly-labeled local demo message to the chat log
  await page.getByRole('button', { name: 'Spawn a Brick' }).click()
  await expect(page.locator('.msg').last()).toContainText('demo')

  // Chat input sends to the local log (no backend)
  await page.getByLabel('Chat message').fill('hello orbit')
  await page.getByRole('button', { name: 'Send message' }).click()
  await expect(page.locator('.msg.user').last()).toHaveText('hello orbit')
  await expect(page.locator('.msg').last()).toContainText('local-only demo')
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
