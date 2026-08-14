import { test, expect } from '@playwright/test'

// Orbit Browser — E2E: the tab strip (open / switch / close, per-tab URL).
// Tabs own the shell's navigation state: each tab has its own URL and the
// URL bar always reflects the active tab.

test('tab bar: new tab opens active; switching restores; session persists on reload', async ({ page }) => {
  await page.goto('/')

  // The shell starts with a single default tab.
  const tabs = page.getByRole('tab')
  await expect(tabs).toHaveCount(1)
  await expect(tabs.first()).toHaveAttribute('aria-selected', 'true')

  // Opening a new tab appends a second, active tab.
  await page.getByRole('button', { name: 'New tab' }).click()
  await expect(tabs).toHaveCount(2)
  await expect(tabs.nth(1)).toHaveAttribute('aria-selected', 'true')
  await expect(tabs.first()).toHaveAttribute('aria-selected', 'false')

  // Switching back to the first tab re-activates it.
  await tabs.first().click()
  await expect(tabs.first()).toHaveAttribute('aria-selected', 'true')
  await expect(tabs.nth(1)).toHaveAttribute('aria-selected', 'false')

  // The session (tabs + active tab) is persisted to localStorage.
  await page.reload()
  await expect(page.getByRole('tab')).toHaveCount(2)
  await expect(page.getByRole('tab').first()).toHaveAttribute('aria-selected', 'true')
})

test('tab bar: each tab keeps its own URL and title, feeding the URL bar', async ({ page }) => {
  await page.goto('/')
  const input = page.getByLabel('URL input')

  // Navigate the first tab.
  await input.fill('alpha.bawes')
  await input.press('Enter')
  await expect(page.getByTestId('current-url')).toContainText('https://alpha.bawes')

  // New tab starts blank; navigate it somewhere else.
  await page.getByRole('button', { name: 'New tab' }).click()
  await expect(page.getByTestId('current-url')).toBeHidden()
  await input.fill('https://beta.bawes')
  await input.press('Enter')
  await expect(page.getByTestId('current-url')).toContainText('https://beta.bawes')

  // Per-tab URL state: switching back shows alpha again.
  await page.getByRole('tab').first().click()
  await expect(page.getByTestId('current-url')).toContainText('https://alpha.bawes')
  await expect(page.getByRole('tab').first()).toHaveAttribute('aria-selected', 'true')

  // Titles derive from each tab's hostname.
  await expect(page.getByRole('tab').first()).toContainText('alpha.bawes')
  await expect(page.getByRole('tab').nth(1)).toContainText('beta.bawes')

  // And the URL bar input reflects the active tab's URL, ready to edit.
  await expect(input).toHaveValue('https://alpha.bawes')
})

test('tab bar: closing activates a neighbour and never leaves zero tabs', async ({ page }) => {
  await page.goto('/')
  const input = page.getByLabel('URL input')

  // Build three tabs, each with a distinct URL, active = third.
  await input.fill('one.bawes')
  await input.press('Enter')
  await page.getByRole('button', { name: 'New tab' }).click()
  await input.fill('two.bawes')
  await input.press('Enter')
  await page.getByRole('button', { name: 'New tab' }).click()
  await input.fill('three.bawes')
  await input.press('Enter')
  const tabs = page.getByRole('tab')
  await expect(tabs).toHaveCount(3)
  await expect(page.getByTestId('current-url')).toContainText('three.bawes')

  // Closing a background tab keeps the active tab active.
  await page.getByRole('button', { name: 'Close tab' }).first().click()
  await expect(tabs).toHaveCount(2)
  await expect(page.getByTestId('current-url')).toContainText('three.bawes')

  // Closing the active tab activates its left neighbour.
  await page.getByRole('button', { name: 'Close tab' }).last().click()
  await expect(tabs).toHaveCount(1)
  await expect(page.getByTestId('current-url')).toContainText('two.bawes')

  // Closing the last tab reopens a fresh one — the shell never has zero tabs.
  await page.getByRole('button', { name: 'Close tab' }).click()
  await expect(tabs).toHaveCount(1)
  await expect(tabs.first()).toHaveAttribute('aria-selected', 'true')
  await expect(tabs.first()).toContainText('New Tab')
})
