import { test, expect } from '@playwright/test'

// Orbit Browser — E2E: identity layer.
// The registry-identity preload step: a device-local UUID that survives
// reloads, an honest sign-in placeholder, and the universe entry link.

const DEVICE_IDENTITY_KEY = 'orbit.device-identity'

test('device identity is created once and persists across reload', async ({ page }) => {
  await page.goto('/')

  // Identity chip renders in the workspace header
  const chip = page.getByTestId('identity-chip')
  await expect(chip).toBeVisible()
  await expect(chip).toContainText('local device identity')
  await expect(page.getByTestId('identity-name')).toContainText(/^device-[0-9a-f]{8}$/)

  // A v4 UUID was persisted to localStorage on first load
  const first = await page.evaluate((key) => localStorage.getItem(key), DEVICE_IDENTITY_KEY)
  expect(first).toBeTruthy()
  const parsed = JSON.parse(first!) as { id: string }
  expect(parsed.id).toMatch(
    /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/,
  )

  // Reload — the identity must not change
  await page.reload()
  const second = await page.evaluate((key) => localStorage.getItem(key), DEVICE_IDENTITY_KEY)
  expect(second).toBe(first)
  await expect(page.getByTestId('identity-name')).toContainText(`device-${parsed.id.split('-')[0]}`)
})

test('sign-in placeholder is honest and the universe entry link is preloaded', async ({ page }) => {
  await page.goto('/')

  // The sign-in affordance is a placeholder, not a claim of auth
  await page.getByRole('button', { name: 'Sign in' }).click()
  const note = page.getByTestId('identity-auth-note')
  await expect(note).toBeVisible()
  await expect(note).toContainText("isn't wired yet")

  // Universe entry link resolves to the configured default
  const entry = page.getByTestId('universe-entry-link')
  await expect(entry).toHaveAttribute('href', 'https://play.bawes')

  // The entry origin gets a preconnect so the first trip is instant
  const preconnected = await page.evaluate(() =>
    document.querySelector('link[rel="preconnect"][href="https://play.bawes"]') !== null,
  )
  expect(preconnected).toBe(true)
})
