// Orbit Browser — tab model & persistence (pure helpers, no React).
//
// Each tab owns a URL (and a title derived from it). The tab list + active
// tab are persisted to localStorage so a session survives reloads — the
// shell is fully local, no backend.

export interface Tab {
  id: string
  url: string
}

export interface TabState {
  tabs: Tab[]
  activeTabId: string
}

/** Fallback target when the URL bar is submitted empty. */
export const DEFAULT_TARGET = 'browser.bawes'

export const STORAGE_KEY = 'orbit.tabs.v1'

export function makeTabId(): string {
  if (typeof crypto !== 'undefined' && typeof crypto.randomUUID === 'function') {
    return crypto.randomUUID()
  }
  return `tab-${Date.now()}-${Math.random().toString(36).slice(2, 10)}`
}

export function createTab(url = ''): Tab {
  return { id: makeTabId(), url }
}

/** Normalize a URL-bar submission into a loadable target. */
export function normalizeTarget(input: string): string {
  const target = input.trim() || DEFAULT_TARGET
  // CodeRabbit fix: require a COMPLETE http:// or https:// scheme (case-insensitive)
  // before skipping the prefix — 'httpsfoo.bawes' must become https://httpsfoo.bawes.
  return /^https?:\/\//i.test(target) ? target : `https://${target}`
}

/** Human title for a tab, derived from its URL (hostname). */
export function tabTitle(tab: Tab): string {
  if (!tab.url) return 'New Tab'
  try {
    return new URL(tab.url).hostname || 'New Tab'
  } catch {
    return tab.url
  }
}

export function defaultTabState(): TabState {
  const first = createTab()
  return { tabs: [first], activeTabId: first.id }
}

/** Restore a persisted session; falls back to a fresh single tab on any error. */
export function loadTabState(): TabState {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    if (!raw) return defaultTabState()
    const parsed = JSON.parse(raw) as Partial<TabState>
    if (!Array.isArray(parsed.tabs) || parsed.tabs.length === 0) {
      return defaultTabState()
    }
    const tabs = parsed.tabs.filter(
      (t): t is Tab =>
        typeof t === 'object' && t !== null && typeof t.id === 'string' && typeof t.url === 'string',
    )
    if (tabs.length === 0) return defaultTabState()
    const firstTab = tabs[0]
    if (!firstTab) return defaultTabState()
    const activeTabId =
      typeof parsed.activeTabId === 'string' && tabs.some((t) => t.id === parsed.activeTabId)
        ? parsed.activeTabId
        : firstTab.id
    return { tabs, activeTabId }
  } catch {
    return defaultTabState()
  }
}

export function saveTabState(state: TabState): void {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(state))
  } catch {
    // Quota / private-mode failures must never break the shell.
  }
}
