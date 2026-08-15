import { useState, type FormEvent, type MouseEvent } from 'react'
import './App.css'

type Tab = { id: number; title: string; url: string }

// Orbit Browser — workspace shell with tab management (T-003)
let nextTabId = 2
const DEFAULT_TABS: Tab[] = [
  { id: 1, title: 'Universe', url: 'browser.bawes' },
]

export default function App() {
  const [sidecarOpen, setSidecarOpen] = useState(true)
  const [url, setUrl] = useState('')
  const [tabs, setTabs] = useState<Tab[]>(DEFAULT_TABS)
  const [activeId, setActiveId] = useState(1)

  const activeTab = tabs.find((t) => t.id === activeId) ?? tabs[0]

  const navigate = (e: FormEvent) => {
    e.preventDefault()
    const raw = url.trim()
    const target = raw.startsWith('http') ? raw : raw ? `https://${raw}` : 'browser.bawes'
    setTabs((ts) => ts.map((t) => (t.id === activeId ? { ...t, url: target, title: raw || 'Universe' } : t)))
    setUrl('')
  }

  const openTab = () => {
    const id = nextTabId++
    setTabs((ts) => [...ts, { id, title: 'New tab', url: 'browser.bawes' }])
    setActiveId(id)
  }

  const closeTab = (id: number, e?: MouseEvent) => {
    e?.stopPropagation()
    setTabs((ts) => {
      const idx = ts.findIndex((t) => t.id === id)
      const next = ts.filter((t) => t.id !== id)
      if (next.length === 0) return [{ id: nextTabId++, title: 'New tab', url: 'browser.bawes' }]
      const nxt = next[Math.min(idx, next.length - 1)]
      if (id === activeId && nxt) setActiveId(nxt.id)
      return next
    })
  }

  const switchTab = (id: number) => setActiveId(id)

  return (
    <div className="orbit-shell">
      {/* Browser chrome — URL bar + tabs */}
      <div className="orbit-chrome">
        <div className="tab-strip" role="tablist" aria-label="Tabs">
          {tabs.map((t) => (
            <div
              key={t.id}
              className={`tab ${t.id === activeId ? 'active' : ''}`}
              role="tab"
              aria-selected={t.id === activeId}
              onClick={() => switchTab(t.id)}
            >
              <span className="tab-title">{t.title}</span>
              <button
                className="tab-close"
                aria-label={`Close ${t.title}`}
                onClick={(e) => closeTab(t.id, e)}
              >
                ✕
              </button>
            </div>
          ))}
          <button className="tab-new" aria-label="New tab" onClick={openTab}>+</button>
        </div>
        <form className="url-bar" onSubmit={navigate} role="search" aria-label="Address bar">
          <input
            type="text"
            value={url}
            onChange={(e) => setUrl(e.target.value)}
            placeholder="Enter a URL or search…"
            aria-label="URL input"
            autoCapitalize="none"
            autoCorrect="off"
            spellCheck={false}
          />
          <button type="submit" aria-label="Go">↵</button>
        </form>
        {activeTab && (
          <div className="current-url" data-testid="current-url">{activeTab.url}</div>
        )}
      </div>

      <div className="orbit-shell-row">
        {/* Universe dock */}
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

        {/* Universe viewport */}
        <main className="orbit-viewport">
          <div className="viewport-status">
            <span className="status-dot online" /> UniverseOS — pre-cached · offline-ready
          </div>
          <div className="viewport-placeholder">
            <h1>{activeTab?.title ?? 'Welcome to the Universe'}</h1>
            <p className="tab-url" data-testid="viewport-url">{activeTab?.url}</p>
            <p>Navigate with the URL bar, open tabs with +, close with ✕.</p>
            <p className="hint">Browser shell v0.2 — tabs live</p>
          </div>
        </main>

        {/* Orbit sidecar */}
        {sidecarOpen && (
          <aside className="orbit-sidecar">
            <div className="sidecar-header">
              <strong>Orbit</strong>
              <button onClick={() => setSidecarOpen(false)} aria-label="Close sidecar">✕</button>
            </div>
            <div className="sidecar-chat">
              <div className="msg bot">Hi — I'm your Orbit assistant. Ask me anything about the universe, or tell me what to build.</div>
              <div className="msg user">Build me a storefront</div>
              <div className="msg bot">On it — spawning a Brick for your project. You pay for the time it works.</div>
            </div>
            <div className="sidecar-input">
              <input placeholder="Ask Orbit… (spawn a Brick to build)" aria-label="Ask Orbit" />
              <button>↑</button>
            </div>
          </aside>
        )}

        {!sidecarOpen && (
          <button className="sidecar-reopen" onClick={() => setSidecarOpen(true)}>💬</button>
        )}
      </div>
    </div>
  )
}
