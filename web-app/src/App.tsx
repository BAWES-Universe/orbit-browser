import { useEffect, useState, type FormEvent } from 'react'
import './App.css'
import TabBar from './TabBar'
import { createTab, loadTabState, normalizeTarget, saveTabState, type Tab } from './tabs'
import IdentityChip from './identity/IdentityChip'
import { preconnectToUniverse, UNIVERSE_URL } from './identity/deviceIdentity'
import OrbitSidecar from './sidecar/OrbitSidecar'

// Orbit Browser — workspace shell (merged chunk: tabs + identity + sidecar)
// Left: universe dock · Center: universe viewport · Right: Orbit sidecar
// Top: tab strip — open/close/switch tabs, each with its own URL state.
export default function App() {
  const [sidecarOpen, setSidecarOpen] = useState(true)
  const [tabState, setTabState] = useState(loadTabState)
  const [draftUrl, setDraftUrl] = useState('')

  const { tabs, activeTabId } = tabState
  const activeTab: Tab | undefined = tabs.find((t) => t.id === activeTabId)
  const currentUrl = activeTab?.url ?? ''

  // Preconnect to the universe on first load (instant first trip — preload step).
  useEffect(() => {
    preconnectToUniverse()
  }, [])

  // Persist the tab session (tabs + active tab) across reloads — local only.
  useEffect(() => {
    saveTabState(tabState)
  }, [tabState])

  const navigate = (e: FormEvent) => {
    e.preventDefault()
    const target = normalizeTarget(draftUrl)
    // Navigation commits to the active tab only.
    setTabState((prev) => ({
      ...prev,
      tabs: prev.tabs.map((t) => (t.id === prev.activeTabId ? { ...t, url: target } : t)),
    }))
    setDraftUrl('')
  }

  const openTab = () => {
    const tab = createTab()
    setTabState((prev) => ({ tabs: [...prev.tabs, tab], activeTabId: tab.id }))
    setDraftUrl('')
  }

  const selectTab = (id: string) => {
    if (id === activeTabId) return
    const tab = tabs.find((t) => t.id === id)
    if (!tab) return
    // The URL bar reflects the active tab's URL, ready to edit.
    setDraftUrl(tab.url)
    setTabState((prev) => ({ ...prev, activeTabId: id }))
  }

  const closeTab = (id: string) => {
    setTabState((prev) => {
      const index = prev.tabs.findIndex((t) => t.id === id)
      if (index === -1) return prev
      const remaining = prev.tabs.filter((t) => t.id !== id)
      if (remaining.length === 0) {
        // Never leave the shell with zero tabs — reopen a fresh one.
        const tab = createTab()
        setDraftUrl('')
        return { tabs: [tab], activeTabId: tab.id }
      }
      if (prev.activeTabId !== id) {
        return { tabs: remaining, activeTabId: prev.activeTabId }
      }
      // Closing the active tab: activate the right neighbour, else the left.
      const neighbour = remaining[index] ?? remaining[index - 1]
      if (!neighbour) return prev // unreachable: remaining is non-empty
      // CodeRabbit fix: sync the URL bar with the newly active tab (never stale).
      setDraftUrl(neighbour.url)
      return { tabs: remaining, activeTabId: neighbour.id }
    })
  }

  return (
    <div className="orbit-shell">
      {/* Tab strip — open / close / switch tabs, one URL state per tab */}
      <TabBar
        tabs={tabs}
        activeTabId={activeTabId}
        onSelect={selectTab}
        onClose={closeTab}
        onNew={openTab}
      />

      {/* Universe dock — the places you can go */}
      <aside className="orbit-dock">
        <div className="dock-logo">🪐</div>
        <nav className="dock-nav">
          <button className="dock-item active" title="Universe">🌌</button>
          <button className="dock-item" title="Plugn stores">🏪</button>
          <button className="dock-item" title="Yo3an food">🍽️</button>
          <button className="dock-item" title="Planner">🥗</button>
          <button className="dock-item" title="Mail">✉️</button>
          <button className="dock-item" title="Storage">🗄️</button>
        </nav>
        <div className="dock-spacer" />
        <div className="dock-profile" title="Your bananas">🍌 13</div>
      </aside>

      {/* Browser chrome — URL bar + identity chip (one identity, one door) */}
      <div className="orbit-chrome">
        <form className="url-bar" onSubmit={navigate} role="search" aria-label="Address bar">
          <input
            type="text"
            value={draftUrl}
            onChange={(e) => setDraftUrl(e.target.value)}
            placeholder="Enter a URL or search…"
            aria-label="URL input"
            autoCapitalize="none"
            autoCorrect="off"
            spellCheck={false}
          />
          <button type="submit" aria-label="Go">↵</button>
        </form>
        {currentUrl && (
          <div className="current-url" data-testid="current-url">{currentUrl}</div>
        )}
        <IdentityChip />
      </div>

      <div className="orbit-shell-row">
      {/* Universe viewport — the world itself (pre-cached, instant) */}
      <main className="orbit-viewport">
        <div className="viewport-status">
          <span className="status-dot online" /> UniverseOS — pre-cached · offline-ready
        </div>
        <div className="viewport-placeholder">
          <h1>Welcome to the Universe</h1>
          <p>The world loads here — pre-cached, instant, native.</p>
          <p className="hint">Browser shell v0.2 — tabs + identity + fleet sidecar live</p>
        </div>
      </main>

      {/* Orbit sidecar — fleet status, quick actions, local AI-assist chat */}
      <OrbitSidecar
        open={sidecarOpen}
        onToggle={() => setSidecarOpen((o) => !o)}
        onOpenUniverse={() => {
          // CodeRabbit fix: use the configured UNIVERSE_URL (same origin as the
          // identity link + preconnect) — never a hardcoded second origin.
          const target = UNIVERSE_URL
          setTabState((prev) => ({
            ...prev,
            tabs: prev.tabs.map((t) => (t.id === prev.activeTabId ? { ...t, url: target } : t)),
          }))
        }}
      />
      </div>
    </div>
  )
}
